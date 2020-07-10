# Deploy VPC

## Commands

```bash
tfenv use 0.12.12
terraform init
terraform plan
terraform apply
```

Uses S3 for state management.
**Note:** Use the variable `app` to deploy for a specific stack (if you want to segregate VPCs with different apps). You'd need to change the s3 backend key first - concider using env vars instead for the path - eg [this](https://github.com/hashicorp/terraform/issues/17288#issuecomment-462899292)
