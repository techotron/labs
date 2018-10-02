# labs
A place for scripts to deploy labs. 

# Requirements
PowerShell v5 with the awspowershell module installed. AWS access key and secret key saved in separate files located on the computer (eg c:\temp\awsAccess.key).


# Deployments

The scripts can deploy the following environments:

## Ansible

Setup 2 ASGs. One for an ansible server (on an Ubuntu host) with a min/max node count of 1. The other ASG will setup up to 4 vanilla Amazon Linux instances. The ansible server can connect to the instances out of the box using ec2.py as the dynamic inventory mechanism. The filter is currently limited to any instance with the name *ansible\*node*. 
Deploy the template using the **.\deploy-ansible-command.ps1** script, replacing the variables at the top.

## Kubernetes (KOPS) Deployment

Deploy a single Ubuntu EC2 instance which the necessary dependencies and scripts to install a basic master + 2 node K8s deployment. The instance has kubectl install and has the necessary security elements to connect to the master. In order to deploy the cluster, the /usr/local/bin/kops-install.sh scripts needs to be run manually.  
