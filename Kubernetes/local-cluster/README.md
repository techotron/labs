# Local cluster

## Start Cluster

Run `./start-virtual-box.sh` to start the VirtualBox VMs

## Setup Cluster

### Ingress

(See nginx-load-balancer for LB into the nodes)

### Helm

- `k create -f https://raw.githubusercontent.com/techotron/labs/master/Kubernetes/local-cluster/helm-rbac.yml` - Setup ClusterRole binding and service account to grant Tiller necessary permissions
- `helm init --service-account tiller --history-max 200` - Install Helm on cluster (pod will get deployed in `kube-system` NS)

#### Test Site

- Create temp namespace - `k create namespace temp`
- Create simple site from Kubernetes in Action image (just displays hostname of pod): 

```bash
helm upgrade -i -f /git/techotron/k8s-cluster/Helm/simple-site/values.yaml \
    simple-site /git/techotron/k8s-cluster/Helm/simple-site \
    --namespace temp --set image.repository=luksa/kubia \
        --set image.tag=latest \
        --set app.containerport=8080 \
        --set replicaCount=3
```

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


    
    
    
    
    




