# Use docker containers to setup k8s cluster via kops

Read the comments in the script below. The gist is:
1. Build docker image called `kops-base`
2. Use docker image with env vars and commands to build up the environment

The idea of the Docker image is to have a consistant kops/kubeadm/awscli environment which can be portable.

## Setup cluster
```buildoutcfg
./Scripts/K8s\ Install/kops-docker-install.sh
```

## Destroy cluster
```buildoutcfg
./Scripts/K8s\ Install/kops-docker-destroy.sh
```
