# Use docker containers to setup k8s cluster via kops

The below docker commands use the images in the ./Docker/kops-k8s-X images

## Use base image
```buildoutcfg
docker run -it -d -e AWS_ACCESS_KEY_ID=accesskey -e AWS_SECRET_KEY_ID=secretkey -e AWS_REGION=eu-west-1 -e KOPS_IAM_USER=kops-username kops-base:0.0.1
```

Then log into that running container with exec (assumes you only have 1 container running)

```buildoutcfg
docker exec -it $(docker ps -q) /bin/sh
```