## Notes for going through the Kubernetes in Action
### Chapter 4
##### Create replication controller
```bash
k create -f ./kubia-rc.yml
```

### Chapter 5
##### Create service
```bash
k create -f ./kubia-svc.yml
```
##### Get Service
```bash
k get service
```
##### Test service from another pod
```bash
k exec <pod_name> -- curl -s http://<svc_ip>
```
##### Service Endpoints
These are the resource which routes traffic from clients to the pods which are part of the service. The selector in the service config is used to build a list of endpoints (IPs and ports) and this is used to route the traffic to the pod.
<br>
You can check the endpoint like any other resource:
```bash
k get endpoint kubia
```
##### Create node port
This is a mapping of a k8s node port to a port for a pod
````bash
k create -f ./nodeport.yml
````

#### Ingress
Maps an ingress controller to a pod. Operates on <u>layer 7</u> so has the flexibility to route hostname/app1 and hostname/app2 to different services and therefore pods.
<br>
Requires an ingress controller. This can be enabled with minikube with `minikube addons enable ingress`. Get the IP of the controller with `minikube service list` - you're looking for the "default-http-backend"
<br>
The below will route requests to the `host/test` value of the template to `kubia-nodeport` service
```bash
k create -f ./ingress.yml
```
<b>Note:</b> You can test this using cURL:<br>
`curl -X GET 'http://minikube.eddy.com/test`
<br>or<br>
`curl -X GET 'http://<IP_OF_INGRESS_CONTROLLER>/test -H 'Host: minikube.eddy.com'`
<br>
(Where the host is whatever is specified in the ingress object)

###### Note how ingresses works
1. Request is sent to URL (eg minikube.eddy.com/test)
2. DNS resolves this to the IP of the ingress controller
3. Client sends HTTP request to the ingress controller with `minikube.eddy.com` in the host header
4. From the header, the controller determines the service that the client is trying to access, looked up the pod IPs via the Endpoints object associated with the service and forwarded the request to one of the pods.
<b>Note:</b> The ingress controller doesn't forward requests to the service, rather it gets the endpoints from the service and forwards to the pods directly. Most ingress controllers work like this.
<br><br>
![Image of Ingress](./imgs/ingress.png)

##### Enabling HTTPS for an ingress
1. Create a self signed certificate and key (page 241 // 147)
```bash
openssl genrsa -out tls.key 2048
openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=minikube.eddy.com
```
2. Then create a secret from the 2 files
```bash
k create secret tls tls-secret --cert=tls.cert --key=tls.key
```

3. Deploy the app using the following template:
```bash
k create -f ingress-tls.yml
```
or if the deployment already exists, update it:
```bash
k apply -f ingress-tls.yml
```

#### Readiness Probes
- A failed readiness probe removes the pod IP from the list of endpoints for the associated service.
- They will not kill or restart a container. Liveness probes will but readiness probes won't.
- You configure a time to wait before the readiness probe starts polling.
- The readiness probe polls at certain intervals (10 seconds by default).
- An example of where you'd use one:
  - Your app has front end pods which connect to a back end database.
  - Your front end pods have connectivity problems to the database
  - You'd want the readiness probe to fail, which would remove the pod IP from the service (but not kill the pod).
  - This is different to a liveness probe which (if it had the same check) would kill the pod - even though there's nothing wrong with the pod.
  
#### Run a single pod with the dnsutils tools, on the fly
```bash
k run dnsutils --image=tutum/dnsutils --generator=run-pod/v1 --command -- sleep infinity
```
Note: the `--generator=run-pod/v1` part tells K8s to create a pod without a replication controller or similar behind it.

### Chapter 6

#### - Non-Persistent Storage -
#### Creating shared volumes with "emptyDir" type

This will deploy an app (built from ./dockerfiles-fortune) which will write a file of random quotes, using the "fortune" application. The web-server component of this (running nginx:alpine) will serve this quote as an HTML file

```bash
k create -f fortune-pod.yml
k port-forward fortune 8080:80
```

You can create the emptyDir volume on the host's memory with the following template:

```bash
k create -f fortune-pod-volume-in-memory.yml
```

#### Create a shared volume with "gitRepo" type

This will deploy a shared volume, similar to the "emptyDir" type except it will clone the contents of a git repo into it. The contents of the repo is only copied when the pod is created so in order to update the content of the volume, you'd have to delete the pod and recreate it (or deploy the pod using a replication controller and only delete the pod).

```bash
k create -f gitrepo-volume-pod.yml
k port-forward gitrepo-volume-pod 8080:80
```

Note: You can't clone from a private repo. The K8s devs wanted to keep the volume type simple so cloning from a private repo would need to be done via a git sync sidecar.

#### - Persistent Storage - 
#### Create a hostPath volume

This is a mounted path from the k8s worker nodes filesystem. The data exists on the worker node so any pod scheduled to that specific node and has config which will map a volume to that path will see the data. .

They are typically used to give access of the hosts' filesystem to the pods (eg to consume log files, CA certificates or the K8s config file (kubeconfig)).

Note: Only use `hostPath` if you need to read/write system files on the worker node. They should not be used to persist data across pods.

In order to create a directory on the minikube node, you have to SSH onto it and create the directory:

```bash
minikube ssh
sudo mkdir -p /k8s/volumes/hostpath/mongodb
```

#### Deploy mongodb container using the above created hostPath

This will create the container running MongoDb (using a host path on the minikube node). The second command will test access to the the mongodb server. 

```bash
k create -f mongodb-pod-hostpath-pd.yml
k exec -it mongodb mongo
```

Example of how it should look if sucessfull:
![Image of Ingress](./imgs/mongodb-test-access.png)

The rest of the MongoDB commands to create a simple JSON document can be found on page 276 (ebook version)