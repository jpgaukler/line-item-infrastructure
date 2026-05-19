output "s3_bucket_region" {
  value = aws_s3_bucket.app_bucket.region
  description = "Region of the S3 bucket for the applications frontend files"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_bucket.id
  description = "Name of the S3 bucket for the applications frontend files"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.app_distribution.id
  description = "ID of the CloudFront distribution" // used in Github Actions to trigger cache invalidation after deployment
}

output "github_actions_user_access_key_id" {
  value = aws_iam_access_key.github_actions_user_access_key.id
  description = "ID of the IAM access key for Github Actions workflow"
}

output "github_actions_user_secret_access_key" {
  value     = aws_iam_access_key.github_actions_user_access_key.secret
  description = "Secret access key for Github Actions workflow"
  sensitive = true
}

output "route53_zone_name_servers" {
  value = aws_route53_zone.app_zone.name_servers
  description = "Nameservers for the Route 53 AWS zone" // must configure in DNS provider (GoDaddy) for the custom domain to work
}

output "auth0_client_id" {
  value = auth0_client.app_client.client_id
  description = "The Auth0 Client Id for this application"
}

output "auth0_domain" {
  value       = data.auth0_tenant.current.domain
  description = "The Auth0 tenant domain for this application"
}
