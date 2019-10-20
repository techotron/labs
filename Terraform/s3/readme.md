# Terraform State Buckets

This will create a bucket intended for Terraform state. The name will be "ACCOUNT-tf-state-REGION". It'll loop through the list in the regions variable to create as many buckets as there are regions defined.

```bash
terraform init
terraform plan
terraform apply
```