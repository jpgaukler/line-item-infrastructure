locals {
  name_prefix = "${var.app_name}-${var.environment_stage}"
}

# =============================================
# S3 Bucket
# =============================================
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${local.name_prefix}-angular-spa"
  tags   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket_public_access" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "app_bucket_cloudfront_policy" {
  bucket = aws_s3_bucket.app_bucket.id
  policy = data.aws_iam_policy_document.app_bucket_cloudfront_policy_document.json
}



# =============================================
# CloudFront Distribution
# =============================================
resource "aws_cloudfront_origin_access_control" "cloudfront_oac_policy" {
  name                              = "${local.name_prefix}-s3-oac-policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "cloudfront_spa_rewrite" {
  name    = "${local.name_prefix}-spa-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite all non-file paths to index.html for SPA routing"
  publish = true

  code = <<EOF
  function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // If the URI doesn't look like a file, rewrite it to /index.html.
      if (!uri.includes('.')) {
          request.uri = '/index.html';
      }

      return request;
  }
  EOF
}

resource "aws_cloudfront_distribution" "app_distribution" {
  comment             = "${local.name_prefix}-app-bucket-distribution"
  enabled             = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = var.app_domains

  origin {
    domain_name              = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac_policy.id
    origin_id                = aws_s3_bucket.app_bucket.bucket
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.app_bucket.bucket // must match the origin_id above (a single Cloudfront distrution can have multiple origins, this link id is required for proper caching behavior)
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" // Managed-CachingOptimized 
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.cloudfront_spa_rewrite.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.cloudfront_geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags
}


# =============================================
# Route53 Alias Records
# =============================================
resource "aws_route53_record" "app_record" {
  for_each = var.app_domains
  zone_id  = var.route53_zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.app_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.app_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}



# =============================================
# IAM User for Github Actions CI/CD
# =============================================
resource "aws_iam_policy" "github_actions_s3_policy" {
  name   = "${local.name_prefix}-github-actions-s3-policy"
  policy = data.aws_iam_policy_document.app_bucket_github_actions_policy_document.json
}

resource "aws_iam_user_policy_attachment" "github_actions_s3_policy_attachment" {
  user       = var.github_actions_user_name
  policy_arn = aws_iam_policy.github_actions_s3_policy.arn
}


