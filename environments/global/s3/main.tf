module "frontend_build_versions_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket = "${local.app_name}-frontend-build-versions"

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      blocked_encryption_types = ["SSE-C"]
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}

# Allow GitHub Actions to access the bucket
resource "aws_iam_policy" "frontend_build_versions_policy" {
  name   = "${module.frontend_build_versions_bucket.s3_bucket_id}-policy"
  policy = data.aws_iam_policy_document.frontend_build_versions_policy_document.json
  tags = local.tags
}

resource "aws_iam_user_policy_attachment" "frontend_build_versions_policy_attachment" {
  user       = data.terraform_remote_state.global_iam.outputs.github_actions_user_name
  policy_arn = aws_iam_policy.frontend_build_versions_policy.arn
}
