locals {
  app_name  = "line-item-app"
  app_domain = "line-item.app"
  app_logo_uri = "https://line-item.app/images/lineitem_logo_light.svg"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
}
