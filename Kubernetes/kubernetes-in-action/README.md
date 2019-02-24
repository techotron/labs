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
Maps an ingress controller to a service. Operates on <u>layer 7</u> so has the flexibility to route hostname/app1 and hostname/app2 to different services and therefore pods.
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