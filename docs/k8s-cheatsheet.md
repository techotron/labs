# Command cheatsheet for K8s commands

# kubectl
## Login commands
Change context to another 
```buildoutcfg
kubectl config use-context my-cluster-name
```
**Note:** The kubectl config file is typically found in ~/.kube/config and is in yaml format 

Get jwt keycloak token to use for openid auth
```buildoutcfg
curl -X POST https://keycloak.example.com/auth/realms/master/protocol/openid-connect/token -d 'grant_type=password' -d 'client_id=SOME_STRING' -d 'client_secret=SOME_GUID' -d 'username=SOME_USERNAME' -d 'password=SOME_PASSWORD' -d 'scope=openid' -d 'response_type=id_token' > token
```
This will output the token to a file called `token` in the local directory. This can be parsed and used to authenticate with the master nodes by injecting it into the kubectl config file 

Add jwt token to kubectl config
```buildoutcfg
kubectl config set-credentials SOME_NAME --auth-provider=oidc --auth-provider-arg=idp-issuer-url=https://keycloak.example.com/auth/realms/master --auth-provider-arg=client-id=SOME_STRING --auth-provider-arg=client-secret=SOME_GUID --auth-provider-arg=refresh-token=$(jq -r '.refresh_token' < token) --auth-provider-arg=id-token=$(jq -r '.id_token' < token)
```
This uses the token retrieved from the previous command and adds it to the kubectl config

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