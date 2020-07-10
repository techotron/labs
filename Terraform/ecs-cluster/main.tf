module "vpc" {
  source  = "git::https://github.com/techotron/labs.git//Terraform/vpc?ref=master"
  app     = var.app
}

# resource "aws_ecs_cluster" "ecs-cluster" {
#   name = "ecs-cluster"
# }
