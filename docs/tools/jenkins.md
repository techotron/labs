# Jenkins 
## Deploy Jenkins Master (docker)
### AWS Deployment
### Overview
This will deploy a Jenkins master node onto a ASG running CentOS. The instance in the ASG has an EFS volume mounted which contains the Jenkins config. This provides me with a cheap pseudo persistence for my Jenkins configuration as long as the CFN stack for the EFS volume isn't deleted. The ASG can be deleted anytime without loosing the config.

### Requirements
Change the parameters in the script to suit your environment/profile name

### Deployment
This will upload the CFN template to S3 and create/update the stack.
```bash
./labs/Scripts/Jenkins/deploy-jenkins.sh
```

### Local Deployment

### Build the image
Use the docker file to build
```bash
docker build -t eddy_jenkins_lts:<version> .
```

### Build the image
Use the docker file to build (if running locally)
```bash
docker build -t eddy_jenkins_ubuntu_agent:<version> .
```

### Run the containers
Run the above containers (master and agent)
```bash
docker run -d -p 80:8080 -p 50000:50000 -v ~/docker_volumes/jenkins_home:/var/jenkins_home eddy_jenkins_lts:<version>
docker run -d -p 10022:22 eddy_jenkins_ubuntu_agent:latest

# or

docker run -d -p 80:8080 -p 50000:50000 -v ~/docker_volumes/jenkins_home:/var/jenkins_home eddy_jenkins_lts:2.150.1 && docker run -d -p 10022:22 eddy_jenkins_ubuntu_agent:latest
```
