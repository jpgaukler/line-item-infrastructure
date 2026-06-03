output "auth0_api_id" {
  value = auth0_resource_server.api.id
}

output "auth0_tenant_domain" {
  value       = data.auth0_tenant.current.domain
}

output "auth0_api_audience" {
  value = auth0_resource_server.api.identifier
}

