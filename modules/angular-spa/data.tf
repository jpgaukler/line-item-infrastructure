# grant cloudfront permissions to see S3 bucket
data "aws_iam_policy_document" "app_bucket_cloudfront_policy_document" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]

    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.app_distribution.arn]
    }
  }
}

# grant IAM user permissions for Github actions workflow
data "aws_iam_policy_document" "app_bucket_github_actions_policy_document" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app_bucket.arn]
  }

  statement {
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.app_distribution.arn]
  }
}

