output "auth0_tenant_domain" {
  value       = data.auth0_tenant.current.domain
  description = "The domain of the Auth0 tenant, used in authentication flows and API configuration"
}

output "auth0_api_audience" {
  value       = module.auth0_api.auth0_api_identifier
  description = "The unique identifier for the API, used as the 'audience' in Auth0 authentication flows"
}

output "ecs_service_security_group_id" {
  value       = module.ecs.services["line_item_api"].security_group_id
  description = "Security group ID for the ECS API service"
}