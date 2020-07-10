data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state_bucket" {
  count   = length(var.regions)
  bucket  = "snowco-tf-state"
  acl     = "private"
  
  tags = {
    Name        = "terraform_state"
    built_by    = "terraform"
  }

  versioning {
    enabled = true
  }

  force_destroy = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name          = "terraform-locks"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform_state"
    built_by    = "terraform"
  }

}
