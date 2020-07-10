# Terraform State Buckets

This will create a bucket intended for Terraform state. The name "snowco-tf-state"

```bash
tfenv use 0.12.12
terraform init
terraform plan
terraform apply
```

I've since added the bucket it creates as an S3 backend. Bit of circular dependency but can be used as an example
