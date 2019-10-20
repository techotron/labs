data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  count   = length(var.regions)
  bucket  = "${data.aws_caller_identity.current.account_id}-tf-state-${var.regions[count.index]}"
  acl     = "private"

  tags = {
    Name        = "terraform_state"
    built_by    = "terraform"
    environment = "dev"
  }
}