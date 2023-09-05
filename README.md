# prototype-legacy

Partial implementation of the EDGELESS features with state-of-the-art tools 

## Prerequisites

- Linux server with [multipass](https://multipass.run/) installed (tested with Ubuntu 20.04)
- The current user has `sudo` privileges
- The OpenFaaS CLI [faas-cli](https://github.com/openfaas/faas-cli)

## Simple workflow experiment

### Set up two FaaS VMs

Create two faasd virtual machines:

```bash
sudo VM_NAME=faasd1 scripts/create_faasd_vm.sh
sudo VM_NAME=faasd2 scripts/create_faasd_vm.sh
```

This will create two directories called `faasd1` and `faasd2` containing the SSH keys to enter the VMs, the secret to login with faas-cli, and a Bash file with pre-configured environment setup, e.g., to verify that you can connect via the CLI to faasd1 run:

```bash
cd faasd1 && . environment && faas-cli list
```

### Deploy example functions on the FaaS VMs

We will deploy:

- on `faasd1` a function `incr` which reads a single integer number and increments it,
- on `faasd2` a function `double` which reads a single integer number and doubles it,

with the following commands:

```bash
cd faasd1 && . environment && cd ..
OPENFAAS_URL1=$OPENFAAS_URL
cd faasd2 && . environment && cd ..
OPENFAAS_URL2=$OPENFAAS_URL
faas template pull https://github.com/openfaas-incubator/rust-http-template
faas-cli deploy -f examples/incr.yml --gateway $OPENFAAS_URL1
faas-cli deploy -f examples/double.yml --gateway $OPENFAAS_URL2
```

Try them with curl (theexpected answer is `(99+1)*2=200`):

```bash
curl $OPENFAAS_URL1/function/double -d $(curl $OPENFAAS_URL2/function/incr -d 99)
```

### Setup an ServerlessOnEdge VM

Download and build [ServerlessOnEdge](https://github.com/ccicconetti/serverlessonedge) in another multipass VM, see [quick start instructions](https://github.com/ccicconetti/serverlessonedge/blob/master/docs/BUILDING.md).

Make sure that `sudo multipass list` shows at least the following VMs: `faasd1`, `faasd2`, `soe-bionic`.

### Run a simple function chain experiment

First, download the example script into the VM and make it executable:

```bash
sudo multipass exec soe-bionic -- bash -c "wget https://raw.githubusercontent.com/edgeless-project/prototype-legacy/main/scripts/setup-soe-faasd-chain.sh"
sudo multipass exec soe-bionic -- bash -c "chmod 755 setup-soe-faasd-chain.sh"
```

Then, you can run the experiment:

```bash
sudo multipass exec soe-bionic -- bash -c "VERBOSITY=2 EXEC_DIR=serverlessonedge/build/debug/Executables ADDRESS=\$(hostname -I | cut -f 1 -d ' ')  OPENFAAS_URL1=http://10.203.18.112:8080 OPENFAAS_URL2=http://10.203.18.75:8080 ./setup-soe-faasd-chain.sh"
```

The script will execute in background:

- two edgecomputers active as brokers towards `faasd1` and `faasd2`, respectively
- two local (called _companion_) edgerouters, interconnected to one edgecomputer each
- one main edgerouter, which provides the client with access to the FaaS platforms

and it will configure the forwarding tables of all the edgerouters.

Afterwards, it will create an edgeclient that will execute a simple function chain `incr-double` with input equal to `99`.

## ServerlessOnEdge-only experiment

First, download the example script into the VM and make it executable:

```bash
sudo multipass exec soe-bionic -- bash -c "wget https://raw.githubusercontent.com/edgeless-project/prototype-legacy/main/scripts/setup-soe-only-chain.sh"
sudo multipass exec soe-bionic -- bash -c "chmod 755 setup-soe-only-chain.sh"
```

Then, you can run the experiment:

```bash
sudo multipass exec soe-bionic -- bash -c "EXEC_DIR=serverlessonedge/build/debug/Executables ADDRESS=\$(hostname -I | cut -f 1 -d ' ') ./setup-soe-only-chain.sh"
```

The environment is the same as the chain example with FaaS but:

- the edgecomputers simulate a FaaS platform, each offering one lambda function (`lambda1` or `lambda2`)
- both lambda functions simply copy the input into the output
- the chain of functions invoked by the client is `lambda1-lambda2`