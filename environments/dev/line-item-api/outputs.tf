output "auth0_tenant_domain" {
  value       = data.auth0_tenant.current.domain
  description = "The domain of the Auth0 tenant, used in authentication flows and API configuration"
}

output "auth0_api_audience" {
  value = auth0_resource_server.api.identifier
  description = "The unique identifier for the API, used as the 'audience' in Auth0 authentication flows"
}

output "aws_ecr_repository_url" {
  value       = aws_ecr_repository.api_repo.repository_url
  description = "The target URL used pushing container images"
}

output "aws_ecs_express_service_name" {
  value       = module.line_item_container_app.ecs_express_service_name
  description = "The name of the ECS service"
}

output "aws_ecs_express_api_url" {
  value       = module.line_item_container_app.ecs_express_service_url
  description = "The public HTTPS URL for the API"
}
