## Notes for going through the Kubernetes in Action
Github link: https://github.com/luksa/kubernetes-in-action
### Chapter 4
##### Create replication controller
```bash
k create -f ./kubia-rc.yml
```

### Chapter 5 - Services and Ingress
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

### Chapter 6 - Storage

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

### Chapter 7 - Secrets and ConfigMaps
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

### Chapter 8 - Pod Metadata
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

### Chapter 9 - Deployments
