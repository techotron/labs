# Command cheatsheet for K8s commands

# kubectl
## Administrative Commands
List available nodes in cluster
```buildoutcfg
kubectl get nodes
```

List pods with extra columns
```buildoutcfg
kubectl get pods -o wide
```

List pods from all namespaces
```buildoutcfg
kubectl get pods --all-namespaces
```

Describe a specific pod in more detail
```buildoutcfg
kubectl describe pod <pod-name>
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

Scale application up/down (where N = integer)
```buildoutcfg
kubectl scale replicationcontroller <replication-controller-name> --replicas=N
```

#####Dashboard
Get the k8s dashboard (GKE)
```buildoutcfg
kubectl cluster-info | grep dashboard
```

Get the username/password for the dashboard (GKE)
```buildoutcfg
gcloud container clusters describe <cluster-name> | grep -E "(username|password):"
```

**Note:** for getting the dashboard details in minikube, use the minikube-cheatsheet.md

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