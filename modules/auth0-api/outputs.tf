output "auth0_api_id" {
  description = "Auth0 resource server ID."
  value       = auth0_resource_server.api_resource_server.id
}

output "auth0_api_identifier" {
  description = "Auth0 API identifier/audience."
  value       = auth0_resource_server.api_resource_server.identifier
}
