locals {
  environment_stage = "dev"

  api_name  = "line-item-api"
  api_audience  = "https://line-item.app/api" 

  ecs_container_cpu    = 256
  ecs_container_memory = 512
  
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
}
