module "angular_app" {
  source = "../../../modules/angular-spa"

  name_prefix       = local.name_prefix
  app_domains       = local.app_domains

  cloudfront_geo_restriction_locations = ["US"]

  route53_zone_id      = data.terraform_remote_state.global_route53.outputs.route53_zone_id
  acm_certificate_arn  = data.terraform_remote_state.global_route53.outputs.acm_certificate_us_east_1_arn
  
  github_actions_user_name = data.terraform_remote_state.global_iam.outputs.github_actions_user_name

  tags = local.tags
}

module "auth0_app_client" {
  source = "../../../modules/auth0-app-client"

  environment_stage      = local.environment_stage
  app_name               = local.app_name
  app_logo_uri           = local.app_logo_uri
  custom_login_domain    = "login.${local.app_domains[0]}"
  allowed_web_urls         = local.auth0_web_urls

  route53_zone_id = data.terraform_remote_state.global_route53.outputs.route53_zone_id
}
