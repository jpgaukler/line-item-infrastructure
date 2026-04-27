# S3 bucket =================================================================
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

# Define access policy so CloudFront can access the bucket
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
      values = [aws_cloudfront_distribution.cloudfront_app_bucket_distribution.arn]
    }
  }
}

# Apply the policy to the S3 bucket
resource "aws_s3_bucket_policy" "app_bucket_cloudfront_policy" {
  bucket = aws_s3_bucket.app_bucket.id
  policy = data.aws_iam_policy_document.app_bucket_cloudfront_policy_document.json
}




# Cloundfront distribution =================================================================

resource "aws_cloudfront_origin_access_control" "cloudfront_oac_policy" {
  name = "line-item-app-s3-oac-policy"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "cloudfront_app_bucket_distribution" {
  comment = "line_item_app_bucket_distribution"

  origin {
    domain_name = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac_policy.id
    origin_id = aws_s3_bucket.app_bucket.bucket
  }

  enabled = true
  default_root_object = "index.html"

  // don't cache index.html, so that it is always fetched from s3
  ordered_cache_behavior {
    path_pattern     = "/index.html"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.app_bucket.bucket // must match the origin_id above (a single Cloudfront distrution can have multiple origins, this link id is required for proper caching behavior)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" // Managed-CachingDisabled
    viewer_protocol_policy = "redirect-to-https"
  }

  // default cache behavior for all other files
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
    cloudfront_default_certificate = true 
  }
}

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

