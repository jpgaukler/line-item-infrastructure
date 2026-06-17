data "terraform_remote_state" "global_iam" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/iam/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "aws_iam_policy_document" "frontend_build_versions_policy_document" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.frontend_build_versions_bucket.s3_bucket_arn]
  }

  statement {
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${module.frontend_build_versions_bucket.s3_bucket_arn}/*"]
  }
}

