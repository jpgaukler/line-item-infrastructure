output "ecs_express_service_name" {
  description = "Name of the ECS Express Gateway service."
  value       = aws_ecs_express_gateway_service.app_service.service_name
}

output "ecs_express_service_url" {
  description = "Public HTTPS endpoint for the ECS Express Gateway service."
  value       = aws_ecs_express_gateway_service.app_service.ingress_paths[0].endpoint
}
