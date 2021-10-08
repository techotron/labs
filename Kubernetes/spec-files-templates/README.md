# Spec File Definitions
A collection of k8s spec files in order to become familiar with their structure. I'm using them to prepare for the CKA exam

The idea is to create the following spec files from memory and use the validation tool [Kubeval](https://kubeval.instrumenta.dev/) to check them.

Spec files to create:

- Deployment
- Service (nodeport)
- Service (clusterip)
- Pod
- Daemonset
- Persistent Volume
- Persistent Volume Claim
- Pod with 2 containers which share an empty volume
- Deployment which uses a PVC
- Ingress
- Service Account with read permissions to the API server
- Storage Class which allows volume expansion
- Cluster Role
- Cluster Role Binding
- Role
- Role Binding
- Network policy which applies to all pods in a namespace
- Network policy which applies to pods with a cidr range of 172.17.0.0/24

## Validation
Run the kubeval tool against the file you create for the resource and confirm it's correct. This will validate it's structure but won't confirm it's fufils the requirements in the above list. For this, the full spec files will put into the [manifests](./manifests) directory

```bash
kubeval --strict filename.yaml
```
