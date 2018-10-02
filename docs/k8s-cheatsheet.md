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

Check status of the service
```buildoutcfg
kubectl get svc traefik --namespace kube-system -w
```

When the `EXTERNAL-IP` is no longer `<pending>`:
```buildoutcfg
kubectl describe service traefik -n kube-system | grep Ingress | awk '{print $3}'
```
