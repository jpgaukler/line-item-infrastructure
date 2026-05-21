locals {
  environment_stage = "dev"

  app_name  = "line-item-app"
  app_domain = "${local.environment_stage}.line-item.app"
  app_logo_uri = "https://${local.app_domain}/images/lineitem_logo_light.svg"
  
  auth0_secrets_key = "auth0_terraform_provider_credentials"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
  auth0_web_urls = [
    "http://localhost:4200",
    "https://${local.app_domain}"
  ]
}
