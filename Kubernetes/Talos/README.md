# Talos

Talos is an OS for K8s. You can use in AWS by creating an AMI with launch config pertinent to your setup. Using the `osctl` command line utility, you can launch a prod-like cluster (3 masters and 1 node) as docker containers for local dev and CI/CD, making you test against a similar environment in prod.

## Local Cluster Setup

### MacOS

```bash
# Install osctl
wget -q -O /usr/local/bin/osctl https://github.com/talos-systems/talos/releases/download/v0.3.0-alpha.0/osctl-darwin-amd64
chmod +x /usr/local/bin/osctl

# Setup cluster - this will overwrite your current kubectl config - backup if you want to keep this!
osctl cluster create
osctl kubeconfig > ~/.kube/config
kubectl config set-cluster talos_default --server https://127.0.0.1:6443
kubectl apply -f https://raw.githubusercontent.com/talos-systems/talos/v0.3.0-alpha.0/hack/dev/manifests/psp.yaml
kubectl apply -f https://raw.githubusercontent.com/talos-systems/talos/v0.3.0-alpha.0/hack/dev/manifests/coredns.yaml
kubectl apply -f https://raw.githubusercontent.com/talos-systems/talos/v0.3.0-alpha.0/hack/dev/manifests/flannel.yaml

# Check progress of the pods
kubectl get pods --all-namespaces

# Check nodes are now ready
kubectl get nodes

# Destroy the cluster
osctl cluster destroy
```