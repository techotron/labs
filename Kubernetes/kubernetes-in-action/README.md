## Notes for going through the Kubernetes in Action
Github link: https://github.com/luksa/kubernetes-in-action
## Chapter 4
##### Create replication controller
```bash
k create -f ./kubia-rc.yml
```

## Chapter 5 - Services and Ingress
#### Services
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

## Chapter 6 - Storage

#### - Non-Persistent Storage -
#### Creating shared volumes with "emptyDir" type

This will deploy an app (built from ./dockerfiles-fortune) which will write a file of random quotes, using the "fortune" application. The web-server component of this (running nginx:alpine) will serve this quote as an HTML file

```bash
k create -f fortune-pod.yml
k port-forward fortune 8080:80 &
```

You can create the emptyDir volume on the host's memory with the following template:

```bash
k create -f fortune-pod-volume-in-memory.yml
```

#### Create a shared volume with "gitRepo" type

This will deploy a shared volume, similar to the "emptyDir" type except it will clone the contents of a git repo into it. The contents of the repo is only copied when the pod is created so in order to update the content of the volume, you'd have to delete the pod and recreate it (or deploy the pod using a replication controller and only delete the pod).

```bash
k create -f gitrepo-volume-pod.yml
k port-forward gitrepo-volume-pod 8080:80 &
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
![Test Mongo Access](./imgs/mongodb-test-access.png)

The rest of the MongoDB commands to create a simple JSON document can be found on page 276 (ebook version)

Test MongoDB commands to check existing document:
```bash
use mystore
db.foo.find()
```

#### Persistent Volumes (and PV Claims)

They work like this:
![PVC1](./imgs/persistent-vol-claims.png)

**Note:** PVs do not belong to any namespace. They are cluster-level resources (like nodes). Persistent Volume Claims however ___do___ belong to a namespace and can only be used by pods in the same namespace.

![Image of PVC2](./imgs/persistent-vol-claims2.png)

Create a persistent volume (which maps to the same hostPath directoy on the minikube node) like this:

```bash
k create -f mongodb-hostpath-pv.yml
```

To create the claim, run:

```bash
k create -f mongodb-hostpath-pvc.yml
```

If you list the PVCs, you'll notice that the claim is bound to the persistent volume that was created earlier.

The access modes:

|Access Mode|Meaning|Use|
|---|---|---|
|ROW|ReadWriteOnce|Only a single node and mount a volume|
|ROX|ReadOnlyMany|Multiple nodes can mount a volume for reading|
|RWX|ReadWriteMany|Multiple nodes can mount a volume for read/write|

**Note:** The above access modes are for ___nodes___, not pods.

To deploy a mongoDB pod, using this new PVC, run: 

```bash
k create -f mongodb-pod-pvc.yml
```

#### Dynamic PV Provisioning

Instead of the cluster admin creating the persistent volumes before hand, you can deploy a persistent volume provisioner and define one or more StorageClass objects and let users choose what they want. Users can refer to the StorageClass in their PVC. StorageClass objects are not namespaced..

With minikube, you can test this by deploying the following provisioner

```bash
k create -f storageclass-fast-hostpath.yml
```

**Note:** This creates a storage class resource which will be used by PVC to create new PV on the fly. The concept of PVC and PVs is still the same, the difference is that the PVs don't have to exist beforehand.

Then create a PV by deploying the following PVC:

```bash
k create -f mongodb-storageclass-pvc.yml
```

**Note:** This creates a hostPath PV on the minikube node. The StorageClass provisioner has done this when the PVC was created.

The point of StorageClasses is that they're referable by name and are therefore easily portable to other clusters (providing the StorageClasses with the same name exist there)

The below image illistrates how storage classes work:

![Storage Classes](./imgs/storage-classes.png)

## Chapter 7 - Secrets and ConfigMaps
#### Config Maps

##### CMD, Entrypoint Terminology

The terminology differences between Dockerfiles and Kubernetes:

![Terminology Table](./imgs/cmd-entrypoint-table.png)

##### Parameters and Environment Variables

Rather than hard coding values in pods, you can override the arguments that are used by the container. In this example, the html-generator script has been changed to use a script parameter as the value for the sleep interval
```bash
k create -f ./fortune-pod-arg.yml
```

You can pass varying parameters as environment variables via the pod template, eg:

```bash
k create -f ./fortune-pod-env.yml
```

##### Creating Config Maps

Config maps are a Kubernetes resource which store key-value data which pods can use. The pods don't need to know they're using config maps which keeps them Kubernetes agnostic. You can deploy config maps with the same name in different namespaces which allows pods in different namespaces to inherit different values, based on the namespace they've been deployed in (eg, dev or prod)

**Note:** Config Map keys _must_ be a valid DNS subdomain

Create a config map directly using kubectl:

```bash
k create configmap fortune-config --from-literal=sleep-interval=25 --from-literal=foo=bar --from-literal=one=two
```

Alternatively, create the config map from a file:

```bash
k create -f ./fortune-config.yml
```

Configmaps can store entire config data which can be read from a file:

This will read the contents of `config-file.conf` in the working directory and add it as a key named after the file name

```bash
k create configmap my-config --from-file=config-file.conf
```

Alternatively, specify the key:

```bash
k create configmap my-config --from-file=customkey=config-file.conf
```

If you want to add all files in the directory, you can add all like this:
This will create an individual map entry for each file in the directory.

```bash
k create configmap my-config --from-file=/path/to/dir
```

You can mix the varying types of keys from above:

```bash
k create configmap my-config \
    --from-file=foo.json \
    --from-literal=foo=bar \
    --from-file=/path/to/dir
```

##### Using Config Maps

**IMPORTANT NOTE:** When using environment variables or args, the pods would need to be restarted for the containers to recognise the change. Using volume mounts do not require the pods to be restart as the new contents of the mounted volumes are updated live. HOWEVER, you may need to include some logic in the processes in the container which reload in order to "see" the new files in the mounted volumes.
You can pass a ConfigMap entry as an environment variable. Eg:

```bash
k create -f ./fortune-config.yml
k create -f ./fortune-pod-env-configmap.yml
```

**Note:** If the ConfigMap doesn't exist when the pod starts, it will fail _until_ the ConfigMap is created. If you want to override this and have the pod start even if the ConfigMap isn't available you can mark the reference as optional by setting `configMapKeyRef.optional: true`

You can create all contents of the config map as environment variables at once, eg:

```bash
k create -f ./fortune-config.yml
k create -f ./fortune-pod-env-configmap2.yml
```

**Note:** This will create 2 env vars called `CONFIG_foo` and `CONFIG_one` but not one called `CONFIG_sleep-interval` because this is not a valid env var (with the dash)

You can pass the values of the ConfigMap as arguments to the main container process by using env vars, eg:

```bash
k create -f ./fortune-pod-args-configmap.yml
```

You can present the value of the config maps as a configmap volume, This will create the contents of the config map as files in the container. This example will pass the nginx.conf to the web-server container as a configmap.

**IMPORTANT NOTE:** This is simply mounting a volume but using config maps as the contents. This means the same rules apply when mounting any other volume, namely: any contents in the path from the container will get masked by the new volume mount.

First, we create the configmap using files in the ./configmap-files directory.
Then we create the pod with a volume which contains the values of the configmap

```bash
k create configmap fortune-config --from-file=configmap-files
k create -f ./fortune-pod-volume-configmap.yml
```

**Note:** This doesn't overwrite the value of the default nginx conf file in /etc/nginx/nginx.conf but will map the file to /etc/nginx/conf.d/ which nginx loads *.conf files by default.

Test this has worked by forwarding the port and checking the response headers:

```bash
k port-forward fortune-vol-configmap 8080:80 &
curl -H "Accept-Encoding: gzip" -I localhost:8080
```

The only problem with the above is that it maps all of the contents of ./configmap-files to /etc/nginx/conf.d whereas we only want the nginx .conf file there. We can specify which files are copied there with an item selector:

```bash
k create -f ./fortune-pod-volume-configmap2.yml
k exec -it forturn-vol-configmap --container web-server -- ls /etc/nginx/conf.d
```

**Note:** Expected outcome, the file `gzip.conf` is listed

The above methods are fine if you want to mount a volume to an empty path but if you wanted to add a file to the /etc directory, you couldn't use this method. Instead, you can use the subPath property of the volumeMounts config:

```bash
k create -f ./fortune-pod-volume-configmap3.yml
k exec -it forturn-vol-configmap --container web-server -- ls /etc/nginx/conf.d
```

##### Notes about updating files in the volume mounts

- Changes to configmaps are often seen on the pods around 1 minute from making the change
- The changes are atomic, meaning changes to all files in the mount happen at the same time. 
- The above is achieved by Kubernetes using symbolic links. K8s copies the files to a new directory and when all the files have been copied, it changes the symbolic links, making the change instant.
- If a single file has been mounted to a volume, then this WILL NOTE GET UPDATED. Only full volume mounts get updated live.
- If multiple pods are using the same configmap as a mounted volume, it's possible for the files changes between different pods to be out of sync whilst the kubernetes copies the files to the new directory.

#### Secrets

- Secrets hold any sensitive information. 
- Like ConfigMaps, they are key value pairs. 
- Since v1.7, they are encrypted and stored in etcd.
- Secrets are only distributed to nodes which run pods that require the secrets 
- They are always stored in memory and never written to physical storage (not yet sure if this includes the etcd store)
- All pods are given a default secret which is made of a .crt, namespace and token. This is used by the pod should it need to communicate with the Kubernetes APIs.
- Secrets have a 1MB limit.

The secrets are mounted as a volume on the pod. The location of the path and the secrets which the pod has mounted using `k describe pods`

![Secrets Volume](./imgs/secrets-mounted-vol.png)

##### Creating a secret

Very similar process to creating a ConfigMap

We'll create a certificate locally (and an extra file to demonstrate that the data is encrypted)

```bash
openssl genrsa -out ./certs/https.key 2048
openssl req -new -x509 -key ./certs/https.key -out ./certs/https.cert -days 3650 -subj /CN=minikube.eddy.com
echo bar > ./certs/foo

k create secret generic fortune-https --from-file=./certs/https.key --from-file=./certs/https.cert --from-file=./certs/foo
k get secrets fortune-https -o yaml
```

- The value of the secret is stored in Base64-encoded strings
- By using Base-64 encoding we can also store binary data as plain-text strings

**Note:** You'd need to update the `fortune-config` ConfigMap so that the nginx.conf file includes the ssl information before deploying the next pod:

```bash
k create -f ./fortune-pod-env-configmap-secret.yml
k port-forward fortune-https 8443:443 & 
```

This illustrates what is happening with this pod:

![Pod Using Secret](./imgs/secrets-used-in-pod.png)


Check that the pod is using the new certificate:

```bash
curl -k -v https://localhost:8443
```

expected result:

> ➜  kubernetes-in-action git:(master) ✗ curl -k -v  https://localhost:8443
> Rebuilt URL to: https://localhost:8443/
>   Trying ::1...
> TCP_NODELAY set
> Connected to localhost (::1) port 8443 (#0)
>Handling connection for 8443
> ALPN, offering h2
> ALPN, offering http/1.1
> Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
> successfully set certificate verify locations:
>   CAfile: /etc/ssl/cert.pem
>  CApath: none
> TLSv1.2 (OUT), TLS handshake, Client hello (1):
> TLSv1.2 (IN), TLS handshake, Server hello (2):
> TLSv1.2 (IN), TLS handshake, Certificate (11):
> TLSv1.2 (IN), TLS handshake, Server key exchange (12):
> TLSv1.2 (IN), TLS handshake, Server finished (14):
> TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
> TLSv1.2 (OUT), TLS change cipher, Client hello (1):
> TLSv1.2 (OUT), TLS handshake, Finished (20):
> TLSv1.2 (IN), TLS change cipher, Client hello (1):
> TLSv1.2 (IN), TLS handshake, Finished (20):
> SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
> ALPN, server accepted to use http/1.1
> Server certificate:
>  subject: CN=minikube.eddy.com
>  start date: Apr 25 21:42:50 2019 GMT
>  expire date: Apr 22 21:42:50 2029 GMT
>  issuer: CN=minikube.eddy.com
>  SSL certificate verify result: self signed certificate (18), continuing anyway.
> GET / HTTP/1.1
> Host: localhost:8443
> User-Agent: curl/7.54.0
> Accept: */*
> 
> HTTP/1.1 200 OK
> Server: nginx/1.15.11
> Date: Thu, 25 Apr 2019 23:10:58 GMT

##### Secrets in Memory

The secret is mounted in the pod from an in-memory filesystem (tmpfs). You can see this by listing the mounts in the container:

```bash
k exec fortune-https -c web-server -- mount | grep certs
```

Will return:

>tmpfs on /etc/nginx/certs type tmpfs (ro,relatime)

The secret could have been exposed to the pod as environment variables rather than a volume. You'd so this the same way as you could from a ConfigMap, example is commented out in the ./fortune-pod-env-configmap-secret.yml manifest

##### Image Pull Secrets

Store private registry passwords as secrets for Kubernetes to pull images from them

This will create a secret of type: "docker-registry"

```bash
k create secret docker-registry mydockerhubsecret --docker-username=myusername --docker-password=mypassword --docker-email=my.email@provider.com
```

This will create a secret with a single entry called `.dockercfg` which is the equivalent to the .dockercfg file created when you run the `docker login` command

Add this to the spec in the pod manifest. Commented example is in ./fortune-pod-env-configmap-secret.yml

## Chapter 8 - Pod Metadata

#### Downward API

##### Downward API using Env Vars

The Downward API enables you to expose the pod's own metadata to the processes running inside the pod. It allows you to pass the following information:

![Downward API Info](./imgs/downward-api-info.png)

Using the downward API, you're able to keep your application Kubernetes agnostic however, you're only able to use it for the above list of metadata.

For resource values, you use a divisor which is used to return a value as a known unit. 

An example of exposing data as env vars:

```bash
k create -f ./downward-api-env.yml
k exec downward env
```

An example of exposing data as a volume mount:

```bash
k create -f ./doward-api-volume.yml
k exec downward -- cat /etc/downward/annotations
```

Valid divisors for memory limits/requests are:

- 1 (byte)
- 1k (kilobyte)
- 1Ki (kibibyte)
- 1M (megabyte)
- 1Mi (mebibyte)
etc

The unit for CPU requests are: `1m` or milli-core. These are 1/1000th of a CPU core.

##### Downward API Volume

You can define an downward API mount rather than exposing details via environment variables. You can _only_ do this for a pod's labels or annotations. The reason for this is because the values of annotations and labels can be updated on the fly. If this is done then the files in the mounted volume are also updated but this dynamic updating of values isn't available for environment variables.

![Downward API Volume](./imgs/downward-api-volume.png)

**Note:** It's possible to change the permissions of these files in the same way as in ConfigMaps, using the `defaultMode` property in the pod spec

#### Kubernetes REST API

Get the API URL with `k cluster-info`

It's not easy to access it directly but you can by the `kubectl proxy` command. This will accept an HTTP connection on the local machine and proxies them to the API server whilst taking care of authentication. To run the proxy:

```bash
k proxy
```

Kubectl knows all the auth settings and URLs so this command is all that's needed.

So now you connect to the API via this proxy connection with:

```bash
curl localhost:8001
```

For example, to list jobs by using the API, deploy a job run the request:

```bash
k create -f ./my-job.yml
curl http://localhost:8001/apis/batch/v1/jobs
```

##### REST API from within a pod

To talk to the REST API from a pod, you need to do the following:

- Locate API server
- Confirm identity of API server (and not an impersonation)
- Authenticate with API server

We can test this from a pod, then execute a shell session to test API access:

```bash
k create -f ./pod-curl.yml
k exec -it curl bash
```

Now we're in the pod, we can start with the 3 tasks above:

```bash
# The location is included in the env vars by default. We could have also used the DNS name of the service in Kubernetes.
curl https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
# This complains about a certificate error. So we'll try with the secret that's mounted by default. (We could use the -k flag but this makes us susceptable to man-in-the-middle attacks.)

# We can verify the server by specifying the CA cert it was signed with
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
# We now get a 403 response.
# We'll make a CURL_CA_BUNDLE env var to make this easier from now on:

export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Lastly, we need to authenticate with it. You can do this using the token that's including in the default-token secret:
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -H "Authorization: Bearer $TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
```
**Note:** This may not work if you have RBAC enabled. The simplest way to get around this is to run the following:

```bash
k create clusterrolebinding permissive-binding --clusterrole=cluster-admin --group=system:serviceaccounts
```

You can get the namespace that a pod is running in by using the details included in the secrets vol mount:

```bash
NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
curl -H "Authorization: Bearer $TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namepsaces/$NS/pods
```

![REST API Access](./imgs/rest-api-access.png)

##### REST API via an ambassador container

Like using `kubectl proxy` in a sidecar container and using the pod's loopback address to access it.

```bash
k create -f ./pod-curl-ambassador.yml
k exec -it curl-with-ambassador -c main bash
```

Now you can access the REST API from the main container, using `curl http://localhost:8001`

##### REST API using client libraries

2 libraries exist that are officially supported by the API Machinery special interest group (SIG):

- Golang client: https://github.com/kubernetes/client-go
- Python: https://github.com/kubernetes-incubator/client-python

Multiple user-contributed client libraries:

- Java client by Fabric8: https://github.com/fabric8io/kubernetes-client
- Java client by Amdatu: https://bitbucket.org/amdatulabs/amdatu-kubernetes 
- Node.js client by tenxcloud: https://github.com/tenxcloud/node-kubernetes-client 
- Node.js client by GoDaddy: https://github.com/godaddy/kubernetes-client 
- PHP: https://github.com/devstub/kubernetes-api-php-client 
- Another PHP client: https://github.com/maclof/kubernetes-client 
- Ruby: https://github.com/Ch00k/kubr 
- Another Ruby client: https://github.com/abonas/kubeclient 
- Clojure: https://github.com/yanatan16/clj-kubernetes-api 
- Scala: https://github.com/doriordan/skuber 
- Perl: https://metacpan.org/pod/Net::Kubernetes

**Note:** Check ebook page 372 for an example of a Fabric8 Java Client

##### Swagger API

Kubernetes has a list of swagger API definitions but also has Swagger UI integrated into the API server. You can enable it with the `--enable-swagger-ui=true` or with minikube, when you start the cluster: `minikube start --extra-config=apiserver.Features.Enable-SwaggerUI=true`. You can then get to it using the /swagger-ui URI.

## Chapter 9 - Deployments

Create new kubia replication controller, service and ingress, running v1:

```bash
k create -f kubia-rc-and-service-v1.yml
```

An old method of triggering a rolling update is by using kubectl:

```bash
while true; curl http://minikube.eddy.com/ && sleep 1; done
k rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2
```

This does the following:
* Create new RC using old RC as base (but with different image)
* Add label to old pods called "deployment: 1234zxc"
* Add label selector to old RC called "deployment: 1234zxc"
* Add label to new pods called "deployment: 4321qwerty"
* Add label select to new RC called "deployment: 4321qwerty"
* The old RC is scaled down, whilst the new RC is scaled up until the old RC as 0 pods.
* When the old RC has 0 pods, the old RC is deleted

This whole processes relies on the kubectl client having access to the API server.
It's also imperative and k8s strengths are in it's declarative model. 
These are the main reasons it's an obsolete method of performing rolling updates.

#### Deployments

When you create a deployment, a ReplicaSet is actually created underneath.

A deployment is the resource which coordinates the old and new ReplicaSets when you deploy a new release.

Deploy a deployment:

```bash
k create -f ./kubia-deployment-v1.yml --record
``` 
**Note:** The `--record` will record the command in the revision history

You can check the status of the deployment with:

```bash
k rollout status deployment kubia
```

The deployment will create a ReplicaSet which will create the pods:

![Replica Set Hash](./imgs/replica-set-hash.png)

The alpha-numeric name after "kubia" is the hash of the pod template.

There are the following deployment strategies:
* RollingUpdate (default)
* Recreate (delete old pods. Create new ones)

To view a RollingUpdate in process, we'll need to slow it down by adding a delay:

```bash
k patch deployment kubia -p '{"spec": {"minReadySeconds": 10}}'
```

We can now change the image defined in the deployment with a kubectl set command:

```bash
k set image deployment kubia nodejs=luksa/kubia:v2
```
**Note:** Changing this will trigger a new deployment. It'll be a rolling update because the strategy hasn't been defined in the template.

Even after this, you'll still see the old replica set (`k get rs`). This is used in case we need to rollback to the previous version quickly. It also stores a copy of all revisions since the first deployment. You can limit the number of stored revisions with the `revisionHistoryLimit` property on the deployment resource.

Deploy a version with a bug (v3): 

```bash
k set image deployment kubia nodejs=luksa/kubia:v3
```

You can quickly rollback this to the previous version with:

```bash
k rollout undo deployment kubia
# or to a specific version:
k rollout undo deployment kubia --to-revision=N
```

You can view a rollout's history with the following:

```bash
k rollout history deployment kubia
```
**Note:** This is why we created the deployment with the `--record` flag.

##### Rolling Update Strategy - maxSurge and maxUnavailable properties

maxSurge is a number or percentage which means how many pods above the desired value can be created. Percentage is rounded up if not a round number. Default is 25%
maxUnavailable is a number or percentage which mean many pod __below__ the desired value can be unavailable. Percentage is rounded down if not a round number. Default is 25%

##### Pausing the rollout process

You can achieve a canary deployment by pausing the deployment before it finishes.

```bash
k set image deployment kubia nodejs=luksa/kubia:v4
k rollout pause deployment kubia
```
**Note:** Depending when you run the pause, only some requests will be going to the new pods, the rest will be going to the old ones.

Resume with:

```bash
k rollout resume deployment kubia
```

This isn't a great way to achieve a canary release because it's relies upon timing of running the pause command. The proper way for now is to use 2 different deployments and scaling them appropriately. 

##### Blocking rollouts of bad versions

Use the `minReadySeconds` property to prevent malfunctioning versions from getting deployed.

This specifies how long a newly created pod should be ready before it's treated as available. If the readiness probe fails before the minReadySeconds value has been met, K8s will stop the deployment.

Test this out with a new deployment which includes a readiness check:

```bash
k apply -f ./kubia-deployment-v3-with-readinesscheck.yml
```

You can check the status again:

```bash
k rollout status deployment kubia
```

This says it's still waiting for rollout to finish...

If we check the pods, we can see that one isn't ready. This is because the readiness probe happens every second. The 5th request (so the 5th second) will fail, meaning the readiness check will not pass. The pod is removed as an endpoint from the service. This happens before the 10 second minReadySeconds value that the deployment is waiting for, so the deployment is paused, waiting. If the rollout can't make any progress in 10 minutes, it's considered as failed. You can see this with:

```bash
k describe deployments kubia
```

Where it provides a reason of "ProgressDeadlineExceeded".

You can manually abort the rollout with:

```bash
k rollout undo deployment kubia
```

## Chapter 10 - Statefulsets

Pods keep the same hostname with an ordinal index from 0 (ie each pod with be named "podName-X"). They'll scale up and down in order so this is predictable. 

To use persistent volumes, you need the stateful stes to use a Persistent Volume Claim template.

To demonstrate this (with minikube), we'll create 3 PVs which we'll have our stateful set pods use. The image is similar to the kubia app except it'll accept a POST to add data to a text file and any GET request will display that data:

```bash
minikube ssh

sudo mkdir -p /k8s/volumes/hostpath/statefulsetvol1
sudo mkdir -p /k8s/volumes/hostpath/statefulsetvol2
sudo mkdir -p /k8s/volumes/hostpath/statefulsetvol3

k create -f ./stateful-set-pv.yml
```

We then need to create a governing service (also known as a headless service). This will be used to create a network identity for the pods. Using a "headless" service means all the IPs from the pods included in the selector are returned.

Create the headless service and stateful set:

```bash
k create -f ./stateful-kubia.yml
```
**Note:** We create the PVC template with the `storageClassName` as blank. Otherwise, it would use the default storage class which would be to create a new PV for the PVC. In this example, we created the new volumes manually so we don't know new volumes to get created.

This will create the pods, one by one. The reason for this is because certain clutered stateful apps are sensitive to race conditions if multiple cluster members are up at the same time.

We'll use `k proxy` to connect to the API proxy:

```bash
k proxy
curl http://localhost:8001/api/v1/namespaces/kube-system/pods/kubia-0/proxy/
```
**Note:** This connection went through 2 different proxies:
1. kubectl proxy
2. API server (which proxied the request to the pod)

Which looks like this:

![Double Proxied Connection](./imgs/double-proxied-connection.png)

We'll test the POST functionality with:

```bash
curl -X POST -d "Hey there! This geeting was submitted to kubia-0." http://localhost:8001/api/v1/namespaces/kube-system/pods/kubia-0/proxy/
```

We can check the data exists on kubia-0 and not on kubia-1 by running the following:

```bash
curl http://localhost:8001/api/v1/namespaces/kube-system/pods/kubia-0/proxy/
# We can see the data exists
curl http://localhost:8001/api/v1/namespaces/kube-system/pods/kubia-1/proxy/
# No data returned.
```

We can confirm the data persists even after we delete the kubia-0 pod:

```bash
k delete pod kubia-0
curl http://localhost:8001/api/v1/namespaces/kube-system/pods/kubia-0/proxy/
# We see the data exists still
```

We'll now test accessing this via a non-headless service but still via the API proxy:

```bash
# Still using the k proxy from before
k create -f ./stateful-kubia-nonheadless-svc.yml
curl http://localhost:8001/api/v1/namespaces/kube-system/services/kubia-public/proxy/
# This will hit kubia-0 and kubia-1 alternately. 
```
**Note:** We're connecting directly to the service, instead of the pod this time.

##### Discovery using DNS SRV records

SRV records are used to point hostnames and ports to services. It can be used for peer discovery between (pod) cluster members.

To run a one off DNS query for SRV records:

```bash
# This will return an answer section which points to each pod in the stateful set
k run -it srvlookup --image=tutum/dnsutils --rm --restart=Never -- dig SRV kubia.kube-system.svc.cluster.local
```

For example, as the stateful set app currently stands, we get a response from one pod (either kubia-0 or kubia-1). One has data, the other does not. We're going to use a new version of the app which will do a SRV lookup and then perform a request on each pod it gets an answer for. Then this is returned in our GET request.

Eg, imagine we have 3 pods in the stateful set.
Our request to the public service hits kubia-0 first:

![Stateful App Peers](./imgs/stateful-app-peers.png)

We can update our stateful set to the use the new image:

```bash
k edit statefulset kubia
# Update spec.template.spec.containers.image to luksa/kubia-pet-peers
```
**Note:** You have to delete the existing pods for the new image to get used. This is because stateful sets were more like ReplicaSets than Deployments. Since K8s v1.7, stateful sets support Rolling Updates (spec.updateStrategy)

To test this, you need to run a couple of POSTs which end up on different pods and then a GET to the kubia-public service.
This will only work if you are using the default namespace because the image is hardcoded with it in the SRV lookup.

##### Stateful Set Pod recovery

A stateful set guarantees that only 1 pod with the same identity is running at any time. Therefore if a node was to fail - it would have to KNOW that the pod had stopped working. 

If a node fails, the master doesn't know for sure if the pod has stopped working. For example, the kubelet may have just stopped working, but the pod itself is fine. This means that the pod on that node would have a status of "unknown". The cluster admin would need to delete the pod or delete the whole node (thus evicting all pods). 

If a pods status remains in a status of unknown for more than 2 minutes (this is configurable) then it's evicted from the node by the master. It evicts the pod by deleting the pod resource.

##### Gotchas

If you delete the pod manually, you may find the status is still "unknown" and the age of the pod hasn't changed. This is because the master (k8s control plane) has marked the pod for deletion but is waiting for confirmation from the downed node's kubelet that this has happened. Assuming the node won't come back up, this confirmation won't happen. The only way around this is to delete the pod forcibly:

```bash
k delete pod kubia-0 --force --grace-period 0
```

## Chapter 11 - Understanding Kubernetes Internals

Only the API Server has direct access to the etcd storage. All the other components communicate to the API server.

![K8s Internals](./imgs/k8s-internals.png)

The control plane (master node) components can run as pods or run directly on the master nodes. To run as pods, the master nodes need a kubelet process running on them.
Nearly all connections to the API server are initiated by the components except:

- When you've used kubectl to get logs (API initiates to kubelet)
- When using `kubectl attach` to connect to a container
- When using `kubectl port-forward`

Check the status of the k8s components

```bash
k get componentstatuses
```

List all the k8s components running as pods:

```bash
k get pods -o custom-columns=POD:metadata.name,NODE:spec.nodeName --sort-by spec.nodeName -n kube-system
```

#### etcd

Key/Value store for K8s resource metadata. It stores the resource definitions in JSON. The etcd cluster is distributed and uses the RAFT consensus algorithm (which is the same as a quorum vote type cluster). Changes to the k/v go through the API server; making each change consistent. It uses optimistic locking which means when a client tries to update a value, a version number is checked. If the version number is different since the data was read, the update fails and the client has to re-read and re-process the change before it's able to write the update.

Split brain example:
![Split Brain Example](./imgs/split-brain-example.png)

Most production deployments will have 5 master nodes for redundancy however, 3 is enough to survive a single node failure.

#### Service Proxy

The kube-proxy is the thing responsible for routing packets destined for a service, to a pod. It does the load balancing (if the service is a load balancer). 

There are 2 modes this is implemented:

- `Userspace Proxy`: A server process which intercepted traffic destined for services and re-routed them to the correct pods. It uses iptables on the worker node to intercept the traffic.
- `Iptables Proxy`: A process updates iptables rules to direct packets straight to the pods, without going through a proxy. This is the current (and much more performant) option in use.

The Userspace proxy balanced traffic in a true round robin way whereas iptables  does it in a random way. 

#### Cluster DNS

The pods are configured to use the `kube-dns` service by default. The kube DNS pods which back this service look at the API server with the "watch" mechanism to check for updates to services/pods and updates it's DNS records accordingly. Any updates will be fairly prompt, but the changes are not instantaneous.

#### How Ingress Works

Most work in the same way - the controller runs a reverse proxy server and keeps it configured according to the Ingress, Service, and Endpoints resources. It therefore looks to the API server using the "watch" mechanism in order to keep up to date. 

#### What a "Pod" Actually Is

Even a single container pod consists of 2 containers under the hood. Each pod will have a container that is run first and "paused". This is the container that holds all the other containers in the pod together and it is how all the other containers are able to share the same network and Linux namespaces. It is also known as the pod infrastructure container.

If application containers die, they need to be a part of the same namespace as before. The infrastructure container makes this possible.

Its lifecycle is tied to the pod. If the pod is killed (intentionally or not) then the kubelet will re-create the infrastructure container and all the other containers which make up the pod.

#### Inter Pod Networking

K8s doesn't require a specific networking technology but it does mandate the following:

```
The network the pods use to communicate must be such that the IP address a pod sees as its own is the exact same address that all other pods see as the IP address of the pod in question.
```

In other words, when pod A sends a network packet to pod B, the source IP pod B sees must be the same IP that pod A sees as its own. 

There should not be any NAT'ing in between, even when this communication spans across worker nodes.

The pod network looks like this:

![Pod Network](./imgs/pod-network.png)

Before the infrastructure container is started, the host creates a virtual interface pair. One interface of the pair remains on the hosts namespace (named something like `vethXXXX`) and the other is moved into the containers network namespace and renamed `eth0`.

The interface on the host namespace is attached to a network bridge that the container runtime is configured to use. The interfaces of the adjoining containers are given an IP address in the bridge's IP range. Packets from Pod A to Pod B will go via the bridge.

#### Cross Node Networking (the pods perspective)

Consider the following:

![Worker Node Network](./imgs/worker-node-network.png)

For a Pod on Node A to connect to a pod on Node B, the following would need to happen:

Pod on Node A -> Node A veth pair -> Node A Bridge ->  Node A physical adapter -> >Over the wire to Node B's physical adapter -> Node B Bridge -> Node B veth pair -> Pod on Node B

This would only work if the nodes were connected to the same network switch without any routers involved. Otherwise, the packets would get dropped because they refer Pod IPs. The routers _could_ be configured to route packets for the pods to the node's interface but this isn't scalable and becomes increasingly hard the more routers there are.

Using a SDN (Software Defined Network) resolves this problem. It makes it appear as though all the nodes are connected to the same network switch. Packets are encapsulated when they leave the pod, sent over the network and de-encapsulated and then delivered to the destination pod in their original form.

#### Container Network Interface (CNI)

CNI is a project which allows Kubernetes to use any CNI plugin that's out there, for example:

- Calico
- Flannel
- Romana
- Weave Net
- (Others)

Installing a network plugin isn't difficult. It's a case of deploying a Daemonset (plus some other supporting resources). This essentially deploys a network agent on the nodes, this then ties into the CNI interface on the nodes. In order for the nodes to _use_ this plugin, kubelet needs to be started with `--network-plugin=cni`.

#### How Services are Implemented

A service consists of a vIP and port pair. They're not assigned to an interface and are not pingable. 

They work by kube-proxy agents "watching" the API server for new services and endpoints (endpoints are a list of pod IPs which are in scope for the service). When one is created, the kube-proxy makes the service addressable by setting up some iptables rules. This makes sure the packets are intercepted and destination address modified so that the packet is redirected to one of the pods backing the service.

#### High Availability (Applications)

Run apps as deployments. Even if the app isn't horizontally scalable, set the replica count to 1. That way, if the hosting node fails, the controller will bring the application up on another node. This will still incur downtime though, whilst the pod is started. This can be minimised by using a leader/election mechanism. This is accomplished by running multiple replicas but ensuring only 1 is active. The others would have logic (either built into the app or as a sidecar container) which would determine which replica is the "leader" and active. An example of this can be found here: https://github.com/kubernetes/contrib/tree/master/election

#### High Availability (Control Plane)

![Control Plane HA](./imgs/control-plane-ha.png)

The following components would need to be available:

- etcd (this is distributed by nature and is easy to setup)
- API Server (almost completely stateless. All data is in etcd but some is cached. This needs to be put behind an LB so that all the kubelets talk to the healthy instances.)
- Controller Manager 
- Scheduler

HA for the CM and Scheduler isn't as easy. Only one set can be active at a time. This is because they watch the API server and act when they see something relevant. They have no knowledge of each other and therefore you'd have instances of duplicate actions taking place.

Each of these components have a `--leader-elect` option which defaults to `true`. Each instance in the cluster is either active as the leader or just waiting to be the leader:

![Control Plane Election](./imgs/control-plane-election.png)

The election process works by a resource getting created via the API server. The resource used for this is an Endpoints resource (which will soon, if not already be ConfigSets instead).

The scheduler for example: `k get endpoints kube-scheduler -o yaml`

There is an annotation called: `control-plane.alpha.kubernetes.io/leader`. The field called `holderIdentity` is the most important part. The first instance which puts its name there, becomes the leader. It uses optimistic concurrency (updates are versioned, if versions differ with what's on the API server, it's submitted again). The leader will try to update the value every 2 seconds (by default) so the other instances can see if it's not been updated in the expected time frame and will attempt to put their name there, started the cycle again.

## Chapter 12 - Securing the API Server

K8s uses a authN and authZ plugins to first let a client log in (authN) and then decide what that client is permitted to do (authZ). There are several authN plugins available and they typically use the following methods to obtain the client's identity:

- From the client certificate
- From an auth token in the HTTP header
- Basic HTTP auth

A Service Account is a resource which represents the identity of the app running inside the pod. Each pod has an associated service account (or will use the default SA in the namespace where the pod exists, which is called 'default').

The format for a service account is: `system:serviceaccount:<namespace>:<service account name>`

Service Accounts can only be used by pods in the same namespace. You can control what resources/actions a pod can perform by assigning it to different service accounts. The authentication tokens used in Service Accounts are JWT tokens (JSON Web Tokens).

#### Creating Service Accounts

This will create a service account with the name `myServiceAccountName` in whatever namespace kubectl is currently configured to use.

```bash
k create serviceaccount foo
```

You can list service accounts like any other k8s resource `k get serviceaccounts`, and also describe them with `k describe serviceaccount foo`.

Reading a secret from a service account is the same as any secret, `k describe secret foo-token-nptwh`

In a `k describe` command, Service Account tokens are included in the "Mountable secrets" list. By default, a pod can mount any secret it wants but the pod's service account can be configured to only allow the pod to mount secrets which are listed as mountable secrets on the service account.

To enable this feature, you need to add the following annotation to the service account:

`kubernetes.io/enforce-mountable-secrets="true"`

Any pods using a service account with this annotation will only be allowed to mount secrets in the "Mountable secrets" list.

You can add an `imagePullSecret` to a Service Account definition (eg `./service-account.yml`). Added this to a service account will mean any pods that use the service account will inherit the image pull secret (meaning you don't have to add it to each pod).

#### Assigning a service account to a pod

You can only do this at pod creation time, you can't set later. 

The name of the service account needs to be added to the `spec.serviceAccountName` field in the pod definition. 

#### RBAC (Role Based Access Control)

RBAC was introduced in version 1.8.0. Other authZ plugins are available:

- Attribute Based Access Control
- Web-Hook plugin
- Custom plugin implementations

RBAC uses a mapping of HTTP methods to authorisation verbs:

|HTTP Method|Verb for single resource|Verb for collection|
|---|---|---|
|GET, HEAD|get, watch|list|
|POST|create|n/a|
|PUT|UPDATE|n/a|
|PATCH|patch|n/a|
|DELETE|delete|deletecollection|

An authZ plugin like RBAC will run inside the API server and decide what verb a client is allowed to run based on the HTTP method used.
It allows for fine grained permission allocation, from entire resource types to a single service and even to non-resource URL paths too.

A human (user/s) or Service Account/s are associated with one or more roles. Each role will define what verbs are allowed to what resource. The sum of rules that a user's/SA's role membership allows will be the effective permissions. If an action/resource isn't specified, then the default action is to deny.

#### RBAC Resources

RBAC definitions are resources like everything else in k8s. 4 resource types can be grouped into 2 sets:

- Roles and ClusterRoles (specify which verbs on which cluster resources)
- RoleBindings and ClusterRoleBindings (which binds the above to users/groups/SAs)

Roles define _what_ can be done. Bindings define _who_ can do it:

![Roles and Bindings](./imgs/roles-bindings.png)

The difference between the Role and Cluster elements of the above are that Roles are namespaced and Clustered are cluster-level resourced (not namespaced).

![Scope of Roles](./imgs/scope-of-roles.png)

#### RBAC Roles/RoleBindings Example (Setup)

- We'll deploy 2 pods in different namespaces to compare the roles.
- The pods will run a single container and use kubectl exec to run curl to the API server.
- The container is based on the kubectl-proxy image (see Chapter 8 notes) which proxies the kubectl connection to localhost:8001, whilst authenticating as the default SA

1. Create namespaces and pods

```bash
k create namespace foo 
k run test --image=luksa/kubectl-proxy -n foo
k create namespace bar 
k run test --image=luksa/kubectl-proxy -n bar
```

2. Run a shell within the pod

```bash
k exec -it <pod-name> -n foo /bin/sh
k exec -it <pod-name> -n bar /bin/sh
```

3. Check that RBAC is enabled by confirming the following gets denied (within the pod session):

```bash
curl localhost:8001/api/v1/namespaces/foo/services
```

A response which goes along the lines of "forbidden" should be received.

#### RBAC Roles/RoleBindings Example (Testing)

1. Deploy the RBAC policy to the `foo` namespace
 
This allows read access to services in the namespace:

```bash
k create -f ./rbac-service-reader.yml
```

**Note:** This policy will allow "get" and "list" actions to resources specified in the `apiGroups` field. In this case, services are part of the core apiGroup, so just an empty `""` is needed. If access to resources belonging to multiple resource groups are required, then multiple policies are required.

2. Deploy the RBAC policy to the `bar` namespace

An alternative way to create the same policy would be to use `kubectl`, in the bar namespace for example:

```bash
k create role service-reader --verb=get --verb=list --resource=services --namespace bar
```

3. Bind the Roles to the Service Accounts

Create the RoleBinding resource to pair the Role with the Service Account (which in this case is the default SA for the foo namespace):

```bash
k create rolebinding test --role=service-reader --serviceaccount=foo:default --namespace foo
```

The yaml representation of this is found in ./rbac-service-reader-binding.yml

**Note:** If you want to bind to a user or group resource, then the same command would be used but replacing `--serviceaccount` with `--user` or `--group`.

4. Re-test API access

Now that the default service account has been paired with the service-reader role, we can confirm the access with another test:

(From with the shell session to the test pod in the foo namespace)

```bash
curl localhost:8001/api/v1/namespaces/foo/services
```

**Note:** The response will be successful but the list of "items" in the response will be empty because no services exist in this namespace.

5. Add the test pod from `bar` namespace to access service resources in `foo`

```bash
k edit rolebinding test -n foo
# Add the following lines to the subjects list:

- kind: ServiceAccount
  name: default
  namespace: bar
```

Now log onto the pod in `bar` and check for services in the `foo` namespace - it should back back positive.

#### RBAC ClusterRoles/ClusterRoleBindings

These resources are _not_ namespaced and are "cluster-level" resources. Certain resources aren't namespaced, such as:

- Nodes
- Persistent Volumes
- Namespaces
etc.

Roles (which operate at the namespace level) can't grant access to these resources but ClusterRoles can.

This will create a ClusterRole which will grant list rights to persistent volumes:

```bash
k create clusterrole pv-reader --verb=get,list --resource=persistentvolumes
```

**Note:** This can also be defined in the ./rbac-cluster-role-pv-reader.yml definition

Before binding the role to a service account, confirm that the pod in `foo` can't list persistent volumes:

```bash
curl localhost:8001/api/v1/persistentvolumes
```

Then apply the binding by creating a ClusterRoleBinding resource:

```bash
k create clusterrolebinding pv-test --clusterrole=pv-reader --serviceaccount=foo:default
```

Now if you run the test again, it should work:

```bash
curl localhost:8001/api/v1/persistentvolumes
```

#### Non-Resource URLs

These are URLs which don't map to a "resource" as such but to some sort of service (eg /healthz or /dashboard etc).

The `system:discovery` ClusterRole allows this automatically.

```bash
k get clusterrole system:discovery -o yaml
```

The "system:discovery" ClusterRole has an associated binding called the same:

```bash
k get clusterrolebinding system:discovery -o yaml
```

It works by binding the `system:authenticated` and `system:unauthenticated` groups to the ClusterRole.

It's possible to pair ClusterRoles with RoleBindings in order to grant access to namespaced resources in a specific namespace.

The built-in `view` ClusterRole:

```bash
k get clusterrole view -o yaml
```

You can bind this role with a RoleBinding or a ClusterRoleBinding. The difference being that in a RoleBinding, only access to the resources that belong to the namespace that the RoleBinding relates to are allowed. If a ClusterRoleBinding was used, then it would be resources across all namespaces in the cluster.

#### Testing a ClusterRole with a RoleBinding and ClusterRoleBinding

1. Control test (before changes)

From the pod in the `foo` namespace:

```bash
# The below shouldn't work because we're asking for pods in all namespaces
curl localhost:8001/api/v1/pods
# The below shouldn't work because we don't have permission to view the pod resource in the foo namespace
curl localhost:8001/api/v1/namespaces/foo/pods
```

2. Create ClusterRoleBinding to the "view" ClusterRole

We expect this to allow us to view pods in all namespaces and in specific namespaces also

```bash
k create clusterrolebinding view-test --clusterrole=view --serviceaccount=foo:default
```

3. Test new binding has worked

```bash
# All of these should work
curl localhost:8001/api/v1/pods
curl localhost:8001/api/v1/namespaces/foo/pods
curl localhost:8001/api/v1/namespaces/bar/pods
```

4. Test with RoleBinding in foo namespace

We need to delete the ClusterRoleBinding we've just created and test a RoleBinding

```bash
k delete clusterrolebinding view-test
k create rolebinding view-test --clusterrole=view --serviceaccount=foo:default --namespace foo
```

5. Test RoleBinding access

We'd expect to only be able to view pods in the `foo` namespace:

```bash
# The below should FAIL
curl localhost:8001/api/v1/pods
# The below should SUCCEED
curl localhost:8001/api/v1/namespaces/foo/pods
# The below should FAIL
curl localhost:8001/api/v1/namespaces/bar/pods
```


#### When to use Namespaces/Cluster wide roles and bindings

![Roles Bindings Use Cases Table](./imgs/roles-bindings-use-cases-table.png)

#### Default ClusterRoles and ClusterRoleBindings

These are pre configured cluster level roles and bindings. They are updated everytime the API server starts which means that they'll get re-created if you mistakenly delete them or if a newer version of Kubernetes uses a different configuration of cluster roles and bindings.

To view the list of default ClusterRoles and ClusterRoleBindings:

```bash
k get clusterrolebindings
k get clusterroles
```

The important ClusterRoles are:

- view
- edit
- admin
- cluster-admin

These are meant to be bound to ServiceAccounts

##### View Role

Allows read only to most resources except for; Roles, RoleBindings and Secrets. Not secrets because this may allow viewing credentials which might allow higher privileges (privilege escalation).

##### Edit Role

Allows modifying resources in a namespace. It also allows reading and modifying secrets. It doesn't allow modifying Roles or RoleBindings (again, to prevent privilege escalation).

##### Admin Role

Allows full control of resources in a namespace. They can read and modify any resource except ResourceQuotas and the namespace resource itself. Difference between `edit` and `admin` is the ability to edit Roles and RoleBindings.

##### Cluster-Admin Role

Allows full and complete control of the k8s cluster and all the resources within it. It has the same permissions as the `admin` role with the addition that it can also edit ResourceQuotas and Namespace resources.

If you create a RoleBinding which references the `cluster-admin` role, then you'll be giving the subject full access to the entire namespace that the RoleBinding exists in.

#### Best Practices

- Principal of least privilege.
- Create Service Accounts for each pod/relicas and associate with tailor made Role/ClusterRole with a RoleBinding (it's unlikely you'd want to grant that pod access to other namespaces so a ClusterRoleBinding is not what you'd want).
- Expect your application will get compromised. Minimise the damage that an attacker _could_ do if they had access to your pods.

## Chapter 13 - Securing Cluster nodes and the Network

You can configure a pod to share the node's network namespace by setting the `spec.hostNetwork` property to `true`:

![hostNetwork true](./imgs/host-network-true.png)

When the control plane components are deployed as pods, they will typically have the `hostNetwork` property set to `true`.

#### Hostport vs NodePort

You can also bind a port from a host's default namespace to a pod's own network namespace by setting the `spec.containers.port` property to `hostPort`. This differs to a Node port service like so:

![nodeport vs hostport](./imgs/nodeport-vs-hostport.png)

Node Port: an incoming connection could hit the service on node 1 but get routed to a pod on node 2
Host Port: there is a direct binding to the node's port to the pod's port. This means only 1 pod with a hostport binding on any single port can run on a single node.

The scheduler is aware of the caveat to hostPorts, so if 4 replicas are deployed in a 3 node cluster, it'll deploy 3 (1 on each node) and a 4th will be in a "pending" state.

Deploy a pod with a hostport:

```bash
k create -f ./kubia-hostport.yml
```

The hostport service is primarily used for exposing system services which are deployed to every node using DaemonSets.

This used to also be a method people used to ensuring no 2 pods were scheduled to the same node (but there is a better way of achieving this now).

#### Shared PID and IPC namespace

You can share the node's PID and IPC namespace using the `hostPID` and `hostIPC` properties:

```bash
k create -f ./pod-with-host-pid-and-ipc.yml
```

Check the running processes that the pod can see. Usually, this would only show the processes in the pod's own namespace but this shows all the ones on the node's as well:

```bash
kubectl exec pod-with-host-pid-and-ipc ps aux
```

By setting the `hostIPC` to true, the container can communicate to all the host's processes.

#### Security Context

Using the `security-context` property in a pod manifest, you can add more security properties for the pod to access.

- Specify the user ID under which the container will run
- Prevent the container running as root (this would prevent any container configured to run as root, to start).
- Run the container in privileged mode, giving it full access to the node's kernal.
- Configure fine grained privileges.
- Set SELinux
- Prevent the process from writing to the container's filesystem.

To test this, we will run a pod with default security-context:

```bash
k run pod-with-defaults --image alpine -- /bin/sleep 999999
```

We'll check what user ID information it's running as:

```bash
k exec pod-with-defaults-7597b869cb-qztct -- id

# returns:
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
```

This tells us it's running as root (uid=0) and group id as root (gid=0)

**Note:** If the USER directive is omitted from a Dockerfile, then the container will run as root by default.

Now, we'll run a pod to run as a specific user:

```bash
k create -f ./pod-as-user-guest.yml
```

Check the user ID for the new pod:

```bash
k exec pod-as-user-guest -- id

# returns:
uid=405(guest) gid=100(users)
```

To prevent a container to run as root, the securityContext property is: `runAsNonRoot: true`. If you tried to run the pod (which uses a root user) it would get scheduled but not run.

Some containers will need to modify the node system which will require the `privileged: true` property. For example the kube-proxy pods need to keep the node's iptables config updated with new services etc.

A pod with `privileged: true` will have access to /dev, lets look at the differences:

```bash
k create -f ./pod-privileged.yml

k exec pod-with-defaults-7597b869cb-qztct --  ls /dev

# expected return:
core
fd
full
mqueue
null
ptmx
pts
random
shm
stderr
stdin
stdout
termination-log
tty
urandom
zero


k exec pod-privileged -- ls /dev

# expected return
autofs
bsg
btrfs-control
core
cpu
... <loads more>
```

This means that the container can use any device freely. Therefore - use with caution!

Another example use case for this level of privilege is if you want a pod running on a Raspberry Pi to control a connected LED.

#### Permitting fine grained kernal capabilities

Linux allows you to permit "capabilities" to containers rather than a blanket "everything", as with the case of privileged containers. For example, if you wanted to allow a container to change the hardware clock, you could add the following to the pod template:

```yaml
securityContext:
  capabilities:
    add:
    - SYS_TIME
```

**Note:** Linux capabilities are usually prefixed with "CAP_" but you leave this bit out in the pod template.

#### Dropping kernal capabilities

By default, containers are granted the CAP_CHOWN capability which allows them to change the ownership of files on the filesystem. This can be dropped like so:

```yaml
securityContext:
  capabilities:
    drop:
    - CHOWN
```

#### Preventing processes from writing to the containers filesystem

It's wise to prevent processes from writing to the container filesystem outside of the mounted volumes. This can be done with the following:

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

**Note:** Doing this means that you'd need to mount a volume to wherever the pod needs to write to (eg, on-disk caches, logs etc).

#### Sharing volumes between different user IDs

Use case: 2 third party containers need to access the same volume. They need to read/write to it but the user their processes run as differ. It's possible to specify a supplemental group which grants this access, allowing the user ID to access the volume without causing a clash. This is done using the following properties:

- fsGroup
- supplementalGroups

Create the following pod which consists of 2 containers which share an empty volume.

```bash
k create -f ./pod-with-shared-volume-fsgroup.yml
```

The template shows us a couple of things:

- The `first` container runs as user ID 1111
- The `second` container runs as user ID 2222
- The fsGroup and supplemental runs as the _pod_ level. They add users to groups 555, 666 and 777

`fsGroup: 555` will set the mounted volumes to be owned by group ID 555 

```bash
# Open a shell to the first container
kubectl exec -it pod-with-shared-volume-fsgroup -c first sh

# Show group membership
id

# expected return:
uid=1111 gid=0(root) groups=555,666,777

# Show permissions to the mounted volume
ls -l / | grep volume

# expected return:
drwxrwsrwx    2 root     555           4096 Jul 10 13:25 volume

# Create a file on the mounted volume
echo foo > /volume/foo

# Check the owner
ls -l /volume

# expected return:
-rw-r--r--    1 1111     555              4 Jul 10 13:27 foo
```

**Note:** This differs to when you usually create files on a filesystem. The owner of the file isn't the creator, instead is the group ID for the fsGroup.

### Restricting the use of the above features

This section will outline how to prevent users of the cluster from granting the pods they deploy, more privileges than they require. This is done using a "PodSecurityPolicy", which is a cluster-level resource. They define what security related features users can and can't use in their pods.

When a user submits a pod config to the API server, the pod security policy plugin will confirm if the user is allowed to use whatever security features are specified. If they're not, then it's rejected immediately. If it's allowed, it's stored to etcd.

A PodSecurityPolicy defines things like the following:

- Whether a pod can use the host’s IPC, PID, or Network namespaces 
- Which host ports a pod can bind to 
- What user IDs a container can run as 
- Whether a pod with privileged containers can be created 
- Which kernel capabilities are allowed, which are added by default and which are always dropped 
- What SELinux labels a container can use
- Whether a container can use a writable root filesystem or not 
- Which filesystem groups the container can run as 
- Which volume types a pod can use

An example policy [pod-security-policy.yml](./pod-security-policy.yml)

#### Overriding Container User IDs

If you specify a user ID that a container should run as in the Dockerfile and have a PodSecurityPolicy which specifies a runAsUser min/max of 2 - then this will override the user ID used in the Dockerfile. Therefore you can can't bypass the policy by using the USER directive in the Dockerfile.

#### Defining Capabilities (allowed, dropped and default)

See the example policy [psp-capabilities..yml](./psp-capabilities.yml)

If there are default capabilities which are specified in policy, then all containers will inherit them. If you don't want your container to have them, you can explicitly drop them in the pod spec file. This (drop) will override the defaults set by the policy.

#### Defining Allowed Volume Types

See the example policy [psp-volumes.yml](./psp-volumes.yml)

**Note:** If multiple policies are in place, then a union of the allowed volume types is used (ie, accumlative)

#### Assigning Policies to users and groups

You can do this using RBAC. Bind a policies to a ClusterRole via a ClusterRoleBinding.

### Isolating the Pod Network

It's possible to configure which pods, other pods can talk to by using a `NetworkPolicy`. The ability to use a NetworkPolicy resource is dependent on which container networking plugin is used.

Application of the policy is determined by a label selector mechanism. The NetworkPolicy uses ingress and egress rules (not related to Ingress resources) to allow|deny access to other pods.

#### Enabling network isolation

By default, pods in a given namespace can be accessed by anyone. To change this, we'll need to create a `default-deny` policy resource. This policy will prevent any pod from accessing any other pod in the same namespace.

```bash
k create -f ./network-policy-default-deny.yml
``` 

*Note:* The empty pod selector means it applies to all pods in the namespace.

#### Adding an ingress rule

This example will allow a web server pod to talk to a Postgress pod on the Postgress port (by default, 5432):

```bash
k create -f ./network-policy-postgres.yml
```

*Note:* The selector is the database pod, so it'll only apply to the DB pod. The rule is saying "allow ingress from pods with the `webserver` app label on port 5432". 
*Note2:* The web server pods would typically talk to the database pods via a service rather than directly. This doesn't change how the ingress|egress rules work. An ingress rule is still required even if the pod is connecting via a service. 

This on it's own will allow the web server pods to talk to the database pods. There's no need to create an egress rule for the webserver pods.

#### Allowing pods from a specific namespace

Allow all pods from a namespace (with a label of `tenant: manning`) to access a pod

```bash
k create -f ./network-policy-cart.yml
```

This will allow any pod from the namespace which has a label of `tenant: manning` to access the pods with an app label of "shopping-cart", on port 80.

*Note:* If the tenant had access to change the labels of their own namespace, it would be possible for them to circumvent this NetworkPolicy rule.

#### Allowing pods from a CIDR network address

An example of this is in [network-policy-cidr.yml](./network-policy-cidr.yml). It works the same way as the other policies but using the CIDR notation in the ipBlock section.

#### Egress rules

These work the same way as ingress but define rules for outgoing traffic instead.

This example will restrict the web pods to only allow outbound to the database pods. It dooesn't define ingress for the database pods, ie: if the database pods didn't have an ingress rule allow access from the webserver pods - then they'd not be able to access them.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-net-policy
spec:
  podSelector:
    matchLabels:
      app: webserver
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

## Chapter 14 - Managing Pod Computational Resources

"Requests" define the resources a container needs to run.
"Limits" define the max a container is allowed to use.

The definitions are allocated to the containers in a pod, not to the pod as a whole. Therefore the pod's Request and Limit values are the values, multiplied by the number of containers in a pod.

### Units

CPU time is measured in "millicores". 1000 millicores is equal to one CPU core.
Memory is measured in "mebibytes"

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: requests-pod
spec:
  containers:
  - image: busybox
    command: ["dd", "if=/dev/zero", "of=/dev/null"]
    name: main
    resources:
      requests:
        cpu: 200m
        memory: 10Mi
```

In this example, the CPU specifies 200 millicores (or 1/5 of a CPU core). This is like saying 5 pods can sufficiently run on a single CPU core. 
These values are under the `requests` property, so they're the minimum that _you_ think the pod will need to do it's job. It's not specifying the minimum that the pod will use.

If we create this pod, we can look at it's CPU consumption with the `top` command:

```bash
k create -f ./requests-pod.yml
k exec -it requests-pod top
```

The output will look like this:

```
Mem: 1940176K used, 98448K free, 18248K shrd, 37400K buff, 1169516K cached
CPU: 17.0% usr 35.4% sys  0.0% nic 47.3% idle  0.0% io  0.0% irq  0.1% sirq
Load average: 1.15 1.17 0.85 10/861 12
  PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
    1     0 root     R     1300  0.0   0 50.3 dd if /dev/zero of /dev/null
    7     0 root     R     1308  0.0   1  0.0 top

```

- The `dd` command will use as much CPU as it can
- Minikube is running on a 2 core VM
- The `dd` command is running in a single thread, so it's only able to use 1 core (50% of the VM's 2 core CPU)

This single core is 1000 millicores, which is more than the 200 millicores specified in the pod definition. It's allowed to do this because it's not a limit.

### Pod Scheduling with Requests defined

The scheduler will only schedule the pod on a node which has enough unallocated resources to run the pod.

The scheduler uses the sum of the requested amount of resources for all the pods, rather than the actual capacity the node has. This ensures that a node isn't over provisioned with pods. This can be visualised here:

![pod-resource-provisioning](./imgs/pod-resource-provisioning.png)

In Chapter 11, scheduling mentions how nodes are prioritised. Amongst others, there are 2 prioritisation functions that are requests based: `LeastRequestedPriority` and `MostRequestedPriority`.

- LeastRequestedPriority: The scheduler will prefer nodes with fewer requested resources (ie, a greater amount of unallocated resources).
- MostRequestedPriority: The scheduler will prefer nodes with more requested resources (ie, less amount of unallocated resources). This option is good for cloud infrastructure where you'd want to squeeze as many pods on the fewest amount of instances possible.

### Checking a Node's Capacity

The kubelet reports the resource metrics for a node to the API server. The Scheduler uses this information when making a scheduling decision. You can view this information with:

```bash
kubectl describe nodes

# Example output:
...
Capacity:
 cpu:                2
 ephemeral-storage:  17784772Ki
 hugepages-2Mi:      0
 memory:             2038624Ki
 pods:               110
Allocatable:
 cpu:                2
 ephemeral-storage:  16390445849
 hugepages-2Mi:      0
 memory:             1936224Ki
 pods:               110
...
``` 

If we run the previous `requests-pod` pod (which has a CPU requests value of 200) let's see what happens if we run another pod with a requests value of 800 millicores:

```bash
k run requests-pod-2 --image=busybox --restart Never --requests='cpu=800m,memory=20Mi' -- dd if=/dev/zero of=/dev/null
```

**Note:** The cpu value here depends on the available CPU for the node. Eg, control plane pods use cpu time, therefore contribute to the allocated resources value.

### CPU Requests affect CPU time sharing

Consider a scenario where 1 pod requests 200m and another requests 1000m), if both pods are working at full capacity, then the CPU time is split in an equal ratio of their requests value (eg, 200:1000 == 1:5 ratio). This mean the first pod would get 16.7% of the node's CPU time and the other would get 83.3%.

However, if the second pod wasn't working at full capacity, then the first pod would be allowed to use the free CPU time. But when the second pod needed the CPU time again, the first pod would have it's CPU time throttled back, up to it's requests CPU value.

### Custom Resources

These were called Opaque Integer Resources but this was changed in 1.8 to Extended Resources.

- Add your resource name to the node object's `capacity` field (eg `example.org/my-gpu-resource`) *Can't be in the kubernetes.io namespace
- The above can be done with a `PATCH` HTTP request
- The quantity must be an integer (eg, it couldn't be 100m because this == 0.1 but it could be 2000m or 2)
- This value will be copied from the capacity field, to the allocatable field automatically.
- You specify the request in the same way as any other in the pod spec file.

An example of where you might do this is with GPU units.

### Limiting Resources available to a container

CPU is a compressible resource. You can throttle it without it causing too many issues for the application.
Memory is not. If a process has been given a chunk of memory, it can't be taken away without the process releasing it (or killing the process).

Therefore, you need to limit the maximum amount of memory an application can use.

The following pod (./limited-pod.yml) will only allow the container/s within it to use up to 1 (CPU) AND 20Mi:

```bash
k create -f ./limited-pod.yml
```

**Note:** Because the pod definition doesn't contain any resource requests, the same values for the limits will be used.

Unlike resource requests, you are allowed to over provision the limits for a node. This does mean however, if a node's resources are exhausted, pods will need to be killed off.

### Exceeding the limits

When a process tries to allocate memory over its limit, it's killed (`OOMKilled`). If the restart policy is "Always", then the pod is restarted but if it continues to allocate more memory than it's allowed, the kubelet will attempt at restarting it with increasing delays between restarts. This is when you see the `CrashLoopBackOff` status.

Delay Timings:

1st - 10s
2nd - 20
3rd - 40s
4th - 80s
5th - 120s
6th - 300s

It then stays at 5 mins until the pod stops crashing or it's deleted.

The pods logs (`k logs <pod_name>`) or using `k describe pod <pod_name>` command will show why it's crashing. 

### How apps see limits 

#### Memory

Containers see the nodes memory - not the container's. This can cause a problem which some apps (particularly Java based apps) where unless the max heap size is specified, it'll set the max sized based on the node's total memory, instead of the total memory available to the container.

This can also have an unexpected side effect when deployed in prod (where total memory of nodes is typically larger) and the app will try to consume more memory than what is allocated in the limits section. This results in OOMKilled errors.

This isn't just solved by setting the `-Xmx` value (which constrains the heap size), as there is still the off-heap memory to deal with. Newer versions now concider the container limits however so an update could solve this.

#### CPU

Like with memory, containers see the node's CPU, not just what is limited to them. Eg. on a CPU with 64 cores, a container limited to 1 core will be allocated 1/64 of the CPU's time. However, it doesn't mean the container's process will only run on a single core. At different points in time, it's code may be executed on different cores. 

This could be a disaster in the following scenario:
- Some applications will look up the number of cores to decide how many threads to run. On a CPU with 64 cores for example, this could cause the app to start too many threads.
- Also, this would cause memory to spike with the added number of threads.

A way around this would be to limit how many cores the container "saw", by using the Downward API **or** by using cgroups directly and looking at the following files:

- /sys/fs/cgroup/cpu/cpu.cfs_quota_us
- /sys/fs/cgroup/cpu/cpu.cfs_period_us

**Note:** cgroups (control groups) is a Linux thing which allows you to allocate resources.

### Pod QOS Classes

