locals {
  name_prefix       = "${local.api_name}-${local.environment_stage}"
  environment_stage = "dev"
  api_name          = "line-item-api"
  api_domain        = "${local.environment_stage}.api.line-item.app"

  container_cpu    = 256
  container_memory = 512
  container_port   = 8080

  auth0_api_audience  = "https://${local.environment_stage}.api.line-item.app"
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"
}
