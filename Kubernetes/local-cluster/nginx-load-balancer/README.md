# Setup

Requires nginx ingress controller (https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal)

This will install the dependancies (nginx ingress controller etc)

`k create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml`

Deploy node port to link "external" (node IP) to ingress controller:

`k create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/service-nodeport.yaml`

Create a deployment, lb service and ingress rule for kubia (as an example):

`k create -f https://raw.githubusercontent.com/techotron/labs/master/Kubernetes/kubernetes-in-action/kubia-deployment-service-and-ingress-local-cluster.yml`

- On local computer, set `kubia.cluster.kube` to point to the Nginx load balancer.
- Upload nginx.conf and passthrough.conf to relevant directories (ensuring that IPs and ports are for the nodes and the ports of the ingress controller service)

# Troubleshooting

- `nginx -V` - View nginx details (loaded modules, version etc)
- `nginx -t` - Verify configuration
- `curl --resolve cluster.kube:30293:192.168.86.60 https://cluster.kube:30293/tea --insecure` - on the fly hostname resolution for cURL request
- `k exec nginx-ingress-6957586bf6-rdt6f -- cat /etc/nginx/conf.d/nginx-ingress-eddy-ingress.conf` - nginx config which has been created dynamically by the controller when you create a new deployment with ingress rule. Notice how the `upstream` block changes each time you change the spec.replicas of the deployment
- `k edit deployment kubia` - edit the deployment on the fly
