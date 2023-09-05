#!/bin/bash

edgerouters_conf_endpoints=()
ann_functions=()
ann_destinations=()
ann_self=()

function start_edgecomputer() {
    configuration_endpoint=$ADDRESS:$((PORT++))
    companion_endpoint=$ADDRESS:$((PORT++))
    echo "starting companion edgerouter at $companion_endpoint (configuration: $configuration_endpoint)"
    GLOG_v=$VERBOSITY $EXEC_DIR/edgerouter \
        --server-conf type=grpc \
        --configuration-endpoint $configuration_endpoint \
        --server-endpoint $companion_endpoint >& edgerouter-$PORT.log &

    ann_functions+=( $FUNCTION )
    edgerouters_conf_endpoints+=( $configuration_endpoint )
    ann_destinations+=( $companion_endpoint )
    ann_self+=( $configuration_endpoint )

    cat > computer.json << EOF
{
	"version": "1.0",
	"processors": [{
		"name": "arm",
		"type": "GenericCpu",
		"speed": 4e9,
		"memory": 500e6,
		"cores": 1
	}],

	"containers": [{
		"name": "ccontainer0",
		"processor": "arm",
		"lambda": {
			"name": "$FUNCTION",
			"output-type": "copy-input",
			"requirements": "proportional",
			"op-coeff": 1e6,
			"op-offset": 4e6,
			"mem-coeff": 100,
			"mem-offset": 0
		},
		"num-workers": 1
	}]
}
EOF

    computer_endpoint=$ADDRESS:$((PORT++)) 
    echo "starting edgecomputer for $FUNCTION at $computer_endpoint"
    GLOG_v=$VERBOSITY $EXEC_DIR/edgecomputer \
        --server-conf type=grpc \
        --computer-type sim \
        --asynchronous \
        --companion-endpoint $companion_endpoint \
        --conf type=file,path=computer.json \
        --server-endpoint $computer_endpoint >& edgecomputer-$PORT.log &
    sleep 0.5
    rm computer.json

    echo "configuring the companion edgerouter for $FUNCTION"
    $EXEC_DIR/forwardingtableclient \
        --server-endpoint $configuration_endpoint \
        --action change \
        --lambda $FUNCTION \
        --destination $computer_endpoint \
        --weight 1 \
        --final >& /dev/null
}

start_main_edgerouter() {
    main_endpoint=$ADDRESS:$((PORT++))
    main_conf_endpoint=$ADDRESS:$((PORT++))
    echo "starting main edgerouter at $main_endpoint (configuration: $main_conf_endpoint)"
    GLOG_v=$VERBOSITY $EXEC_DIR/edgerouter \
        --server-conf type=grpc \
        --configuration-endpoint $main_conf_endpoint \
        --server-endpoint $main_endpoint >& edgerouter-$PORT.log &
    edgerouters_conf_endpoints+=( $main_conf_endpoint )
}

populate_routes() {
    for configuration_endpoint in ${edgerouters_conf_endpoints[@]}; do
        echo "populate routes of edgerouter at $configuration_endpoint"
        for (( i = 0 ; i < ${#ann_functions[@]} ; i++ )) ; do
            if [ $configuration_endpoint == ${ann_self[$i]} ] ; then
                continue
            fi
            echo "add route ${ann_functions[$i]} -> ${ann_destinations[$i]}"
            $EXEC_DIR/forwardingtableclient \
                --server-endpoint $configuration_endpoint \
                --action change \
                --lambda ${ann_functions[$i]} \
                --destination ${ann_destinations[$i]} \
                --weight 1 \
                >& /dev/null
        done
    done
}

start_client() {
    cat > chain.json << EOF
{
  "functions" : [ "lambda1", "lambda2" ],
  "dependencies" : {},
  "state-sizes" : {}
}
EOF
    GLOG_v=$VERBOSITY $EXEC_DIR/edgeclient \
        --max-requests 1 \
        --content hello \
        --chain-conf type=file,filename=chain.json \
        --server-endpoint $main_endpoint \
        --callback $ADDRESS:$((PORT++))
    rm chain.json
}


if [ -z $EXEC_DIR ] ; then
    EXEC_DIR=$PWD
fi
if [ -z $ADDRESS ] ; then
    ADDRESS=localhost
fi
if [ -z $PORT ] ; then
    PORT=10000
fi
if [ -z $VERBOSITY ] ; then
    VERBOSITY=0
fi

executables="edgecomputer edgerouter forwardingtableclient"

for e in $executables ; do
    if [ ! -x "$EXEC_DIR/$e" ] ; then
        echo "missing executable: $e"
        exit 1
    fi
done

FUNCTION=lambda1
start_edgecomputer

FUNCTION=lambda2
start_edgecomputer

start_main_edgerouter

populate_routes

start_client

read -n 1 -p "Press any key to stop all the processes"

rm -f *.log 2> /dev/null

pkill -P $$

wait