locals {
  environment_stage = "dev"

  api_name  = "line-item-api"
  api_audience  = "https://line-item.app/api" 
  
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
}
