# Command cheatsheet for K8s commands

# kubectl
## Administrative Commands
List available nodes in cluster
```buildoutcfg
kubectl get nodes
```

List pods from all namespaces
```buildoutcfg
kubectl get pods --all-namespaces
```

List deployments
```buildoutcfg
kubectl get deployments --all-namespaces
```

Delete deployment
```buildoutcfg
kubectl delete -n NAMESPACE deployment DEPLOYMENT
```

List Replication Controllers
```buildoutcfg
kubectl get replicatecontrollers
```

# helm
## Install Traefik
Search for helm chart
```buildoutcfg
helm search traefik
```

Install helm chart
```buildoutcfg
helm install stable/traefik --name traefik --namespace kube-system
```

List Helm deployments
```buildoutcfg
helm list
```

Check status of the service
```buildoutcfg
kubectl get svc traefik --namespace kube-system -w
```

When the `EXTERNAL-IP` is no longer `<pending>`:
```buildoutcfg
kubectl describe service traefik -n kube-system | grep Ingress | awk '{print $3}'
```

Create ingress rule for traefik ui (only an example. The following works with a manually deployed pod - not one deployed using helm):
```buildoutcfg
kubectl apply -f https://raw.githubusercontent.com/techotron/labs/master/HelmCharts/Traefik/traefik-ui.yml
```

Delete a helm deployment(?)
```buildoutcfg
helm del --purge traefik
```