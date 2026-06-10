locals {
  environment_stage = "dev"
  api_name          = "line-item-api"
  name_prefix       = "${local.api_name}-${local.environment_stage}"
  
  
  api_domain        = "${local.environment_stage}.api.line-item.app"
  
  auth0_api_audience  = "https://line-item.app/api" 

  ecs_container_cpu    = 256
  ecs_container_memory = 512
  ecs_container_port   = 8080
  
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"
}
