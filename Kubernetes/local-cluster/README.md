# Local cluster

## Start Cluster

Run `./start-virtual-box.sh` to start the VirtualBox VMs

## Setup Cluster

### Ingress

(See nginx-load-balancer for LB into the nodes)

### Helm

- `k create -f https://raw.githubusercontent.com/techotron/labs/master/Kubernetes/local-cluster/helm-rbac.yml` - Setup ClusterRole binding and service account to grant Tiller necessary permissions
- `helm init --service-account tiller --history-max 200` - Install Helm on cluster (pod will get deployed in `kube-system` NS)

#### Observability

- Create namespace - `k create namespace observability`

##### Grafana

```bash
helm install --name grafana stable/grafana \
    --set ingress.enabled=true \
    --set ingress.path="/grafana" \
    --set ingress.hosts={"stats.cluster.kube"} \
    --set 'grafana\.ini'.server.root_url=http://stats.cluster.kube/grafana \
    --set 'grafana\.ini'.server.serve_from_sub_path=true \
    --set adminPassword=admin 
```


    
    
    
    
    




