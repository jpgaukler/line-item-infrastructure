# retrive data for route52 zone
data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "global/terraform.tfstate"
    region  = "us-east-2"
  }
}

# grant cloudfront permissions to see S3 bucket
data "aws_iam_policy_document" "app_bucket_cloudfront_policy_document" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.app_distribution.arn]
    }
  }
}

# grant IAM user permissions for Github actions workflow
data "aws_iam_policy_document" "github_actions_user_s3_policy_document" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.app_bucket.id}"]
  }

  statement {
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.app_bucket.id}/*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.app_distribution.arn]
  }
}

# used to output Auth0 tenant domain in outputs.tf
data "auth0_tenant" "current" {}

# used to retrieve Auth0 credentials from AWS Secrets Manager, this was manually added to AWS via the Management Console
# see documenation about Auth0 Terraform provider here: 
# https://registry.terraform.io/providers/auth0/auth0/latest/docs/guides/quickstart#create-a-machine-to-machine-application
data "aws_secretsmanager_secret" "auth0_keys" {
  name = local.auth0_secrets_key
}

data "aws_secretsmanager_secret_version" "auth0_keys_latest" {
  secret_id = data.aws_secretsmanager_secret.auth0_keys.id
}
