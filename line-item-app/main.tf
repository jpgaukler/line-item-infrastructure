# S3 Bucket ==========================================================================
resource "aws_s3_bucket" "line_item_app" {
  bucket = "line-item-app"

  tags = {
    Name = "line-item-app"
  }
}

# Encrypt state at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "line_item_app_encryption" {
  bucket = aws_s3_bucket.line_item_app.id

  rule {
    bucket_key_enabled = true
    blocked_encryption_types = [ "SSE-C" ]

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access 
resource "aws_s3_bucket_public_access_block" "line_item_app_public_access" {
  bucket = aws_s3_bucket.line_item_app.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false # Must be false to allow your IP policy
  restrict_public_buckets = false # Must be false to allow your IP policy
}


# Enable static website
resource "aws_s3_bucket_website_configuration" "line_item_static_website" {
  bucket = aws_s3_bucket.line_item_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

locals {
  ip_address = "69.117.151.90"
}

# Attach the IP-Restricted Bucket Policy
resource "aws_s3_bucket_policy" "line_item_allow_specific_ip" {
  bucket = aws_s3_bucket.line_item_app.id

  # Ensure this policy is applied AFTER the public access block is modified
  depends_on = [aws_s3_bucket_public_access_block.line_item_app_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSpecificIPOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.line_item_app.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "${local.ip_address}/32" # Replace with your public IP
          }
        }
      }
    ]
  })
}