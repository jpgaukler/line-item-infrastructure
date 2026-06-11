locals {
  environment_stage = "dev"

  app_name  = "line-item-app"
  app_domains = ["${local.environment_stage}.line-item.app"]
  app_logo_uri = "https://${local.app_domains[0]}/images/lineitem_logo_light.svg"
  
  auth0_secrets_key = "auth0_terraform_provider_credentials_dev"
  auth0_web_urls = concat(
    ["http://localhost:4200"],
    [for domain in local.app_domains : "https://${domain}"]
  )
}
