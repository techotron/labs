terraform {
  required_version = ">=0.12.12"
  backend "s3" {
    bucket          = "snowco-tf-state"
    key             = "eu-west-2/vpc/terraform.tfstate"
    region          = "eu-west-2"
    dynamodb_table  = "terraform-locks"
    profile         = "snowco"
  }
}

provider "aws" {
  region                    = "eu-west-2"
  shared_credentials_file   = "~/.aws/credentials"
  profile                   = "snowco"
}
