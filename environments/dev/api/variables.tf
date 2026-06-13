locals {
  environment_stage = "dev"
  app_name          = "line-item"
  name_prefix       = "${local.app_name}-${local.environment_stage}"
  
  api_name          = "line-item-api"
  api_domain        = "${local.environment_stage}.api.line-item.app"
  api_container_count  = 1 # should probably be set to 2 or more for production
  api_container_cpu    = 256
  api_container_memory = 512
  api_container_port   = 8080
  api_environment      = "Development"

  migrations_name   = "line-item-migrations"
  migrations_cpu    = 256
  migrations_memory = 512
  
  cloudwatch_log_retention_days = 14

  auth0_api_audience  = "https://${local.environment_stage}.api.line-item.app"
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"

  tags = {
    Application = local.app_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}
