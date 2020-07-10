# Create ECS Cluster

## Reprequisites 

VPC created from [here](../vpc/readme.md)

## Commands

```bash
cd ../vpc
tfenv use 0.12.12
terraform init
terraform plan
terraform apply
```

Create ECS cluster:
(EC2 Linux +_Networking) 
Old but might be relevant:
[Part 1](http://blog.shippable.com/create-a-container-cluster-using-terraform-with-aws-part-1)
[Part 2](http://blog.shippable.com/setup-a-container-cluster-on-aws-with-terraform-part-2-provision-a-cluster)

TODO:

1. Create VPC (done)
1. Create IAM roles
1. Set up ALB
1. Set up ASG
1. Create ECS cluster
1. Create task definition and service 
