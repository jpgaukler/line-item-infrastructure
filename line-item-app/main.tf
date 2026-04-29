# ============================================= S3 Bucket =============================================
resource "aws_s3_bucket" "app_bucket" {
  bucket = "line-item-app"

  tags = {
    Name = "line-item-app"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    bucket_key_enabled = true
    blocked_encryption_types = [ "SSE-C" ]

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




# ============================================= Cloundfront distribution =============================================
# (see example in docs here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#s3-origin)
locals {
  app_domain = "line-item.app"
}

# Route 53 DNS zone for applying custom domain
# MANUAL STEP REQUIRED: after this is created, must update the nameservers in GoDaddy to the 4 name servers of the Route 53 zone
resource "aws_route53_zone" "app_route53_zone" {
  name = local.app_domain
}

# SSL cert for custom domain
resource "aws_acm_certificate" "line_item_ssl_cert" {
  provider          = aws.us_east_1
  domain_name       = local.app_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Add records in Route 53 to validate the certificate
resource "aws_route53_record" "line_item_ssl_route53_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.line_item_ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.app_route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# This resource triggers the actual validation process and waits for it to complete
resource "aws_acm_certificate_validation" "line_item_ssl_route53_cert_validation_waiter" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.line_item_ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.line_item_ssl_route53_cert_validation : record.fqdn]
}

# OAC policy for the Cloudfront Distribution
resource "aws_cloudfront_origin_access_control" "cloudfront_oac_policy" {
  name = "line-item-app-s3-oac-policy"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

# Cloudfront Distribution
resource "aws_cloudfront_distribution" "cloudfront_app_bucket_distribution" {
  comment = "line_item_app_bucket_distribution"

  origin {
    domain_name = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac_policy.id
    origin_id = aws_s3_bucket.app_bucket.bucket
  }

  enabled = true
  default_root_object = "index.html"
  aliases = ["${local.app_domain}"]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.app_bucket.bucket // must match the origin_id above (a single Cloudfront distrution can have multiple origins, this link id is required for proper caching behavior)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" // Managed-CachingOptimized 
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.cloudfront_spa_rewrite.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  viewer_certificate { 
    acm_certificate_arn      = aws_acm_certificate.line_item_ssl_cert.arn // SSL certificate for custom domain created above
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # This ensures the cert is fully issued BEFORE Terraform tries to use the SSL cert, otherwise 'apply' would fail
  depends_on = [aws_acm_certificate_validation.line_item_ssl_route53_cert_validation_waiter]
}

# Function to rewrite all requests to index.html file
resource "aws_cloudfront_function" "cloudfront_spa_rewrite" {
  name    = "spa-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite all non-file paths to index.html for SPA routing"
  publish = true
  code    = <<EOF
  function handler(event) {
      var request = event.request;
      var uri = request.uri;
      
      // If the URI doesn't look like a file (no dot in the last segment),
      // rewrite it to /index.html
      if (!uri.includes('.')) {
          request.uri = '/index.html';
      }
      
      return request;
  }
  EOF
}

# DNS records to point to the CloudFront distribution
resource "aws_route53_record" "app_route53_record" {
  for_each = aws_cloudfront_distribution.cloudfront_app_bucket_distribution.aliases
  zone_id  = aws_route53_zone.app_route53_zone.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_app_bucket_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_app_bucket_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# ============================================= IAM User for CI/CD =============================================
resource "aws_iam_user" "github_actions_user" {
  name          = "github-actions-user"
  path          = "/"
  force_destroy = true # Allows destroying user even if they have non-Terraform managed keys
}

resource "aws_iam_policy" "github_actions_user_s3_policy" {
  name   = "github-actions-s3-deploy-policy"
  policy = data.aws_iam_policy_document.github_actions_user_s3_policy_document.json
}

resource "aws_iam_user_policy_attachment" "github_actions_user_s3_policy_attachment" {
  user       = aws_iam_user.github_actions_user.name
  policy_arn = aws_iam_policy.github_actions_user_s3_policy.arn
}

resource "aws_iam_access_key" "github_actions_user_access_key" {
  user = aws_iam_user.github_actions_user.name
}
