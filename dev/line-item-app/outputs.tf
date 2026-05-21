output "s3_bucket_region" {
  value = aws_s3_bucket.app_bucket.region
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}
// used in Github Actions to trigger cache invalidation after deployment
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.app_distribution.id
}

output "github_actions_user_access_key_id" {
  value = aws_iam_access_key.github_actions_user_access_key.id
}

output "github_actions_user_secret_access_key" {
  value     = aws_iam_access_key.github_actions_user_access_key.secret
  sensitive = true
}

output "auth0_client_id" {
  value = auth0_client.app_client.client_id
}

output "auth0_domain" {
  value       = auth0_custom_domain.app_domain.domain
}
