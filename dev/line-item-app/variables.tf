locals {
  app_name  = "line-item-app"
  app_domain = "dev.line-item.app"
  app_logo_uri = "https://line-item.app/images/lineitem_logo_light.svg"
  
  auth0_secrets_key = "auth0_terraform_provider_credentials"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
  auth0_web_urls = [
    "http://localhost:4200",
    "https://line-item.app"
  ]
}
