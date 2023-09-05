# prototype-legacy

Partial implementation of the EDGELESS features with state-of-the-art tools 

## Prerequisites

- Linux server with [multipass](https://multipass.run/) installed (tested with Ubuntu 20.04)
- The current user has `sudo` privileges
- The OpenFaaS CLI [faas-cli](https://github.com/openfaas/faas-cli)

## Simple workflow experiment

Create two faasd virtual machines:

```bash
sudo VM_NAME=faasd1 scripts/create_faasd_vm.sh
sudo VM_NAME=faasd2 scripts/create_faasd_vm.sh
```

This will create two directories called `faasd1` and `faasd2` containing the SSH keys to enter the VMs, the secret to login with faas-cli, and a Bash file with pre-configured environment setup, e.g., to verify that you can connect via the CLI to faasd1 run:

```bash
cd faasd1 && . environment && faas-cli list
```

Download and build [ServerlessOnEdge](https://github.com/ccicconetti/serverlessonedge) in another multipass VM, see [quick start instructions](https://github.com/ccicconetti/serverlessonedge/blob/master/docs/BUILDING.md).

Deploy the function `incr`, which reads a single integer number and increments it, on faasd1:

```bash
cd faasd1 && . environment && cd ..
faas template pull https://github.com/openfaas-incubator/rust-http-template
faas-cli deploy -f examples/incr.yml --gateway $OPENFAAS_URL
```

Try it (it should reply `100`):

```bash
curl $OPENFAAS_URL/function/incr -d 99
```

or:

```bash
echo  "99" | faas-cli invoke incr
```

## ServerlessOnEdge-only experiment

First, enter the ServerlessOnEdge VM:

```
sudo multipass shell soe-bionic
```

Then, from the VM run:

```
wget https://raw.githubusercontent.com/edgeless-project/prototype-legacy/main/scripts/setup-soe-only-chain.sh
chmod 755 setup-soe-only-chain.sh
EXEC_DIR=serverlessonedge/build/debug/Executables ADDRESS=$(hostname -I | cut -f 1 -d ' ') ./setup-soe-only-chain.sh
```

The script will execute in background:

- two edgecomputer simulators, serving respectively `lambda1` and `lambda2` functions
- two local (called _companion_) edgerouters, interconnected to one edgecomputer each
- one main edgerouter, which provides the client with access to the FaaS platforms

and it will configure the forwarding tables of all the edgerouters.

Afterwards, it will create an edgeclient that will execute a simple function chain `lambda1-lambda2` with fixed content.