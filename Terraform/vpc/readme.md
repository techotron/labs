# Define VPC

## Commands

Deploy stand alone:

```bash
tfenv use 0.12.12
terraform init
terraform plan
terraform apply
```

Uses S3 for state management

**Note:** Use the variable `app` to deploy for a specific stack (if you want to segregate VPCs with different apps). You'd need to change the s3 backend key first - concider using env vars instead for the path - eg [this](https://github.com/hashicorp/terraform/issues/17288#issuecomment-462899292)

## Module

This definition can be used as a module. Eg [ecs-cluster](../ecs-cluster)

You can call the module using git as the source and set a variable in that block:

```bash
module "vpc" {
  source  = "git::https://github.com/techotron/labs.git//Terraform/vpc?ref=master"
  app     = var.app
}
```
