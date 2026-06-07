output "bucket_region" {
  description = "AWS region of the S3 bucket for the Angular application files."
  value       = aws_s3_bucket.app_bucket.region
}

output "bucket_name" {
  description = "Name of the S3 bucket for the Angular application files."
  value       = aws_s3_bucket.app_bucket.bucket
}

output "cloudfront_distribution_id" {
  description = "Id of the cloudfront distribution for the Angular application."
  value       = aws_cloudfront_distribution.app_distribution.id
}
