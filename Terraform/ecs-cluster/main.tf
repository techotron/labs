module "vpc" {
  source  = "git::https://github.com/techotron/labs.git//Terraform/vpc?ref=master"
  app     = var.app
}

module "iam" {
  source  = "git::https://github.com/techotron/labs.git//Terraform/iam/ecs?ref=master"
}

# resource "aws_ecs_cluster" "ecs-cluster" {
#   name = "ecs-cluster"
# }
