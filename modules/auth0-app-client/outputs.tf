output "auth0_client_id" {
  description = "Auth0 SPA client ID."
  value       = auth0_client.app_client.client_id
}

output "auth0_custom_domain" {
  description = "Auth0 custom domain."
  value       = auth0_custom_domain.app_login_domain.domain
}
