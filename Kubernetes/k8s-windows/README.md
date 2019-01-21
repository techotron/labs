# Mixed OS k8s Cluster
## Overview
The aim of this is to create a k8s cluster (a basic one) in which to deploy both Linux and Windows nodes.

## Master Node Setup
Deploy the master node with `./deploy-master.sh`
<br>
This will deploy a single EC2 instance with some defaults (AMI, keypair etc) with some shell scripts to run in order to set it up as a k8s master node. 
<br><br>
The contents of the scripts may need to be run manually. Check the template for the scripts themselves.
<br><br>
When the last script has been run, you should have a single master node setup.

## Enable Mixed-OS Scheduling
The next section of commands are required for enabling mixed nodes in the cluster
<br><br>
##### Step 1
Confirm that the update strategy of `kube-proxy` DaemonSet is set to RollingUpdate:
```bash
kubectl get ds/kube-proxy -o go-template='{{.spec.updateStrategy.type}}{{"\n"}}' --namespace=kube-system
```

##### Step 2
Patch the DaemonSet by downloading <a href="https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/l2bridge/manifests/node-selector-patch.yml">this</a> nodeSelector and apply it to only target linux
```bash
kubectl patch ds/kube-proxy --patch "$(curl https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/l2bridge/manifests/node-selector-patch.yml)" -n=kube-system
```

If this was successful, you should see "Node Selectors" of `kube-proxy` and any other DaemonSets set to 'beta.kubernetes.io/os=linux'
```bash
kubectl get ds -n kube-system
```

## Collect Cluster Information
We now need to collect the following information to join future nodes
1. The output from the `kubeadm init` command which looks like this: 
```bash
kubeadm join 10.0.1.114:6443 --token ig4ymu.vk4kiysrfrbwmpfa --discovery-token-ca-cert-hash sha256:cc578528776e4ad179ad23d560eb192958b22e2ec1e98e68852ae4a13bd277ce
```
2. The cluster subnet defined during `kubeadm init`:
```bash
kubectl cluster-info dump | grep -i service-cluster-ip-range
```
3. The kube-dns service IP:
```bash
kubectl get svc/kube-dns -n kube-system
```
4. Kubernetes `config` file generated after `kubeadm init`
```bash
/etc/kubernetes/admin.conf
$HOME/.kube/config
```