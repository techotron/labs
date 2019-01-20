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

List all resources
```buildoutcfg
kubectl get all --all
```

List all resources from all namespaces (assumed not tested)
```buildoutcfg
kubectl get all --all --all-namespaces
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

Viewing a pod's full descriptor
```buildoutcfg
kubectl get pod <pod_name> -o yaml
kubectl get pod <pod_name> -o json
```

Editing resources directly
```buildoutcfg
kubectl edit replication controller <replication_controller_name>
```
Note: This will use the default text editor specified in either the EDITOR env or KUBE_EDITOR env.
This can be added to ~/.bashrc:
```buildoutcfg
export KUBE_EDITOR="/usr/bin/vi"
```

## Namespaces

Namespaces are ways to logically separate pods, eg dev|QA|stage. It's possible for pods in different namespaces to communicate with each other if the networking configuration allows for it however.
Create a new namespace
```buildoutcfg
kubectl create namespace <new-namespace-name>
```
**Note:** dots are not allowed in namespace names.

Create namespace via YAML file
```buildoutcfg
apiVersion: v1
kind: Namespace 
metadata: 
  name: custom-namespace
```

Alias for quick changing of default namespace
```buildoutcfg
alias kcn='kubectl config set-context $(kubectl config current-context) --namespace
```
**Note:** This will allow you to change the namespace quickly using `kcn pre-prod` for example

## Creating pods

When you create a pod you're really creating a replication controller. This is the object which manages the life cycle of the pod
Create a pod from a manifest file
```buildoutcfg
kubectl create -f <./manifest_filename.yml>
```

Schedule a pod to a specific node
This is done by adding the `nodeSelector` spec to the pod's YAML file
```buildoutcfg
...
spec:
  nodeSelector: 
    gpu: "true"
...
```
This will create the pod on any node which has the label "gpu=true"

## Deleting pods

When you delete a pod, the replication controller will automatically bring a new one back up. In order to delete the pod, you need to delete or reconfigure the replication controller.
To delete a pod
```buildoutcfg
kubectl delete pods <pod-name>
kubectl delete pods <pod1> <pod2> <pod3>
```

Delete pod based on label selector
```buildoutcfg
kubectl delete pods -l creation_method=manual
```

Delete all the pods by deleting the whole namespace
```buildoutcfg
kubectl delete ns <new-namespace-name>
```

Delete all pods whilst keeping the namespace
```buildoutcfg
kubectl delete pods --all
```

Delete all resources from the namespace
```buildoutcfg
kubectl delete all --all
```
**Note:** This will also delete the `kubernetes` service in the namespace, but this should automatically start back up

## Labels

Labels are a good way to organise resources. They are key value pairs, similar to tags in AWS.
You can use the same commands to add labels to other resources - eg nodes. Just substitute "pods" with "nodes"

Add a label to a pod
```buildoutcfg
kubectl label pods <pod_name> key=value
```

Update an existing label value
```buildoutcfg
kubectl label pods <pod_name> key=new_value --overwrite
```

Remove a label
```buildoutcfg
kubectl label pods <pod_name> key-
```

Show all labels attached to pod
```buildoutcfg
kubectl get pods --show-labels
```

Show specifc labels attached to a pod
```buildoutcfg
kubectl get pods -L creation_method,env
```

Show pods with/without a label of any value
```buildoutcfg
kubectl get pods -l env
kubectl get pods -l '!env'
```

Using set-based filters
```buildoutcfg
kubectl get pods -l 'env notin (dev,prod)'
kubectl get pods -l 'creation_method=manual,env in (dev)'
```

## Networking

Add port forward to a pod
```buildoutcfg
kubectl port-forward kubia-manual 8888:8080
```
**Note:** This is a handy way to test an individual pod

## Logging

**Note:** It's standard practise for container logs to std out and std err stream rather than files. Docker will typically redirect these stream to files, which you can retrieve with `docker logs <container_id>`.

Container logs are automatically rotated daily and everytime the log file reaches 10MB. 

View a pod's logs
```buildoutcfg
kubectl logs <pod_name>
```
**Note:** This only shows the logs from the last rotation.

View a specific container's log within a pod
```buildoutcfg
kubectl logs <pod_nane> -c <container>
```

## Secrets

Decode a secret
```buildoutcfg
kubectl get secrets dk-tls-secret -o json | jq '.data."tls.crt"' | sed 's/\"//g' | base64 --decode
```

Decode a certificate from a secret
```buildoutcfg
kubectl get secrets dk-tls-secret -o json | jq '.data."tls.crt"' | sed 's/\"//g' | base64 --decode > /tmp/cert.temp && openssl x509 -text -noout -in /tmp/cert.temp
```

Create certificate and add as k8s secret
```buildoutcfg
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=*.snowco.com/O=Snowco/OU=DevOps" -days 3650
kubectl -n=ops create secret tls <name_of_secret> --cert=tls.crt --key=tls.key
```


## Help Commands

Detail pod config manifests
```buildoutcfg
kubectl explain pods
```

Detail pod config sub section
```buildoutcfg
kubectl explain pod.spec
```

## Dashboard
Get the k8s dashboard (GKE)
```buildoutcfg
kubectl cluster-info | grep dashboard
```

Get the username/password for the dashboard (GKE)
```buildoutcfg
gcloud container clusters describe <cluster-name> | grep -E "(username|password):"
```

**Note:** for getting the dashboard details in minikube, use the minikube-cheatsheet.md
