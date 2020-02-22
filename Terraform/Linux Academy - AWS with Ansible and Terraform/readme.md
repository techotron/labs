# Notes from the Linux Academy course - Deploying to AWS with Ansible and Terraform

This will create a 3-tiered application with LB, Word Press application with RDS backend. A public R53 zone for public name resolution and private zone for RDS endpoint resolution.

## Process of deployment

1. Terraform builds the environment
1. Ansible playbook provisions wp_dev with Wordpress
1. An AMI is created from wp_dev that is used in the launch configuration for the ASG
1. User accesses the dev server and configures the database settings (setting up the connection string etc) (using wp_dev as bastion)
1. Ansible runs the s3update.yml play on wp_dev to copy code to S3
1. The ASG servers pull the code from S3 (through a VPC endpoint for S3) and connect to the RDS database

## SSH Agent setup

```bash
ssh-agent bash
ssh-add ~/.ssh/kryptonite

# List keys
ssh-add -l
```

