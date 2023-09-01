#!/bin/bash

if [ -z $VM_NAME ] ; then
    echo "you must specify VM_NAME"
    exit 1
fi

multipass help >& /dev/null
if [ $? -ne 0 ] ; then
    echo "multipass is not installed or cannot be executed"
    exit 1
fi

if [ -d "$VM_NAME" ] ; then
    echo "directory '$VM_NAME' exists already"
    exit 1
fi

mkdir "$VM_NAME"
pushd "$VM_NAME"

ssh-keygen -f sshkey -N ""
PUB_KEY=$(cat sshkey.pub)
CLOUD_CONFIG=$(wget -O- https://raw.githubusercontent.com/openfaas/faasd/master/cloud-config.txt)

sed "s%ssh-rsa.*%$PUB_KEY%" <<< "$CLOUD_CONFIG" |\
    multipass launch --name "$VM_NAME" --cloud-init -

IP=$(sudo multipass info "$VM_NAME" | grep IPv4: | sed -e "s/\s\+/ /g" | cut -f 2 -d : | cut -f 2 -d ' ')
OPENFAAS_URL=http://$IP:8080
ssh -i sshkey ubuntu@$IP "sudo cat /var/lib/faasd/secrets/basic-auth-password" > faas_pass.txt

cat > environment << EOF
export IP=$IP
export OPENFAAS_URL=$OPENFAAS_URL
faas-cli login -s < faas_pass.txt
EOF

popd
