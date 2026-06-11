output "s3_bucket_region" {
  value = module.angular_app.bucket_region
}

output "s3_bucket_name" {
  value = module.angular_app.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.angular_app.cloudfront_distribution_id
}

output "auth0_client_id" {
  value = module.auth0_app_client.auth0_client_id
}

output "auth0_custom_domain" {
  value = module.auth0_app_client.auth0_custom_domain
}
