# used in Github Actions workflow to deploy files to S3
output "app_region" {
  value = aws_s3_bucket.app_bucket.region
}

# used in Github Actions workflow to deploy files to S3
output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}

# used in Github Actions workflow to trigger CloudFront cache invalidation after deployment
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.app_distribution.id
}

# user credentials for Github Actions workflow 
output "github_actions_user_access_key_id" {
  value = aws_iam_access_key.github_actions_user_access_key.id
}

# user credentials for Github Actions workflow 
output "github_actions_user_secret_access_key" {
  value     = aws_iam_access_key.github_actions_user_access_key.secret
  sensitive = true
}

# must configure name servers in DNS provider (GoDaddy) to match these in order for the custom domain to work
output "route53_zone_name_servers" {
  value = aws_route53_zone.app_zone.name_servers
}
