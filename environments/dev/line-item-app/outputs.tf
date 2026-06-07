output "s3_bucket_region" {
  value = module.line_item_angular_spa.bucket_region
}

output "s3_bucket_name" {
  value = module.line_item_angular_spa.bucket_name
}
// used in Github Actions to trigger cache invalidation after deployment
output "cloudfront_distribution_id" {
  value = module.line_item_angular_spa.cloudfront_distribution_id
}

output "auth0_client_id" {
  value = auth0_client.app_client.client_id
}

output "auth0_domain" {
  value = auth0_custom_domain.app_domain.domain
}
