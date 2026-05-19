locals {
  app_name  = "line-item-app"
  app_domain = "line-item.app"
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
}
