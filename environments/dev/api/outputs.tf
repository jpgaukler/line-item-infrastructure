output "auth0_tenant_domain" {
  value       = data.auth0_tenant.current.domain
  description = "The domain of the Auth0 tenant, used in authentication flows and API configuration"
}

output "auth0_api_audience" {
  value       = module.auth0_api.auth0_api_identifier
  description = "The unique identifier for the API, used as the 'audience' in Auth0 authentication flows"
}

output "ecs_cluster_name" {
  description = "ECS cluster name for the API environment."
  value       = module.ecs.cluster_name
}

output "migrations_task_definition_family" {
  description = "ECS task definition family for the migrations task."
  value       = aws_ecs_task_definition.migrations.family
}

output "migrations_task_network_configuration" {
  description = "Network configuration value for aws ecs run-task."
  value       = "awsvpcConfiguration={subnets=[${join(",", data.terraform_remote_state.network.outputs.private_subnet_ids)}],securityGroups=[${module.ecs.services["line_item_api"].security_group_id}],assignPublicIp=DISABLED}"
}

output "migrations_log_group_name" {
  description = "Name of the Cloudwatch log group for ECS migrations task."
  value       = aws_cloudwatch_log_group.migrations.name
}

output "migrations_log_stream_prefix" {
  description = "Prefix of the task logs for database migrations."
  value       = "${jsondecode(aws_ecs_task_definition.migrations.container_definitions)[0].logConfiguration.options["awslogs-stream-prefix"]}/${jsondecode(aws_ecs_task_definition.migrations.container_definitions)[0].name}"
}
