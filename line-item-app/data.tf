# used to retrieve the current AWS AccountID
data "aws_caller_identity" "current" {}

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
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.app_distribution.id}"]
  }
}

# used to output Auth0 tenant domain in outputs.tf
data "auth0_tenant" "current" {}

# used to retrieve Auth0 credentials from AWS Secrets Manager
data "aws_secretsmanager_secret" "auth0_keys" {
  name = "auth0_terraform_provider_credentials"
}

data "aws_secretsmanager_secret_version" "auth0_keys_latest" {
  secret_id = data.aws_secretsmanager_secret.auth0_keys.id
}
