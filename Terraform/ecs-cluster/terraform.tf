terraform {
  required_version = ">=0.12.12"
  backend "s3" {
    bucket          = "snowco-tf-state"
    key             = "eu-west-2/ecs/terraform.tfstate"
    region          = "eu-west-2"
    dynamodb_table  = "terraform-locks"
    profile         = "snowco"
  }
}


provider "aws" {
  version                   = "~> 2.33"
  region                    = "eu-west-1"
  shared_credentials_file   = "~/.aws/credentials"
  profile                   = "snowco"
}
