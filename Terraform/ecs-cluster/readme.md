Create VPC (if not already exists)

```bash
cd ../vpc
terraform plan -var app="ecs-cluster"
terraform apply -var app="ecs-cluster" -state ecs-cluster.tfstate
```
