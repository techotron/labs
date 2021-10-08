resource "aws_ecs_cluster" "cluster" {
  name = "example-ecs-cluster"

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

module "ecs-fargate" {
  source = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "ecs-fargate-example"
  vpc_id             = "vpc-072155609fbdf9563"
  private_subnet_ids = ["subnet-0c48cd955edb61034", "subnet-0a37e6ed374ac0390"]

  cluster_id         = aws_ecs_cluster.cluster.id

  task_container_image   = "marcincuber/2048-game:latest"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  target_groups = [
    {
      target_group_name = "tg-fargate-example"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "test"
    Project = "Test"
  }
}

# data "terraform_remote_state" "vpc" {
#   backend = "s3"
#   config = {
#     bucket          = "snowco-tf-state"
#     key             = "eu-west-2/vpc/terraform.tfstate"
#     region          = "eu-west-2"
#     dynamodb_table  = "terraform-locks"
#     profile         = "snowco"
#   }  
# } 
