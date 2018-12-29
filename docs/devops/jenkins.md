# Jenkins 
## Deploy Jenkins Master (docker)
### Overview
This will deploy a Jenkins master node onto a ASG running CentOS. The instance in the ASG has an EFS volume mounted which contains the Jenkins config. This provides me with a cheap pseudo persistence for my Jenkins configuration as long as the CFN stack for the EFS volume isn't deleted. The ASG can be deleted anytime without loosing the config.

### Requirements
Change the parameters in the script to suit your environment/profile name

### Deployment
This will upload the CFN template to S3 and create/update the stack.
```bash
./labs/Scripts/Jenkins/deploy-jenkins.sh
```
   