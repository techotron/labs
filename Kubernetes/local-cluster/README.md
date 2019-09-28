# Local cluster

## Start Cluster

Run `./start-virtual-box.sh` to start the VirtualBox VMs

## Setup Cluster

### Ingress

(See nginx-load-balancer for LB into the nodes)

### Helm

- `k create -f ` - Setup ClusterRole binding and service account to grant Tiller necessary permissions
- `helm init --service-account tiller --history-max 200` - Install Helm on cluster (pod will get deployed in `kube-system` NS)
- 


