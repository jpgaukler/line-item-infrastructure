module "line_item_angular_spa" {
  source = "../../../modules/angular-spa"

  environment_stage = local.environment_stage
  app_name          = local.app_name
  app_domains       = local.app_domains

  route53_zone_id      = data.terraform_remote_state.global.outputs.route53_zone_id
  acm_certificate_arn  = data.terraform_remote_state.global.outputs.acm_certificate_arn
  github_actions_user_name = data.terraform_remote_state.global.outputs.github_actions_user_name

  cloudfront_geo_restriction_locations = ["US"]

  tags = {
    Application = local.app_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}



# ============================================= Auth0 Application =============================================
resource "auth0_client" "app_client" {
  name            = "${local.app_name}-${local.environment_stage}"
  logo_uri        = local.app_logo_uri
  description     = "Managed by Terraform"
  app_type        = "spa"
  oidc_conformant = true
  grant_types     = [
    "authorization_code",
    "refresh_token"
  ]
  
  # URLs required for authentication flow
  callbacks           = local.auth0_web_urls
  allowed_logout_urls = local.auth0_web_urls
  allowed_origins     = local.auth0_web_urls
  web_origins         = local.auth0_web_urls

  refresh_token {
    leeway                       = 10
    rotation_type                = "rotating"
    expiration_type              = "expiring"
    infinite_token_lifetime      = false
    token_lifetime               = 2592000 # 30 days
    infinite_idle_token_lifetime = false
    idle_token_lifetime          = 1296000 # 15 days
  }

  jwt_configuration {
    alg = "RS256"
  }
}

# Configure custom domain for Auth0
resource "auth0_custom_domain" "app_domain" {
  domain     = "login.${local.app_domains[0]}"
  type       = "auth0_managed_certs"
  tls_policy = "recommended"
}

# Create the AWS Route 53 DNS Verification Record
resource "aws_route53_record" "auth0_custom_domain" {
  zone_id = data.terraform_remote_state.global.outputs.route53_zone_id
  name    = auth0_custom_domain.app_domain.verification[0].methods[0].domain
  type    = upper(auth0_custom_domain.app_domain.verification[0].methods[0].name)
  records = [auth0_custom_domain.app_domain.verification[0].methods[0].record]
  ttl     = 60
}

# Validate the custom domain on Auth0 side
resource "auth0_custom_domain_verification" "app_domain_verification" {
  depends_on = [aws_route53_record.auth0_custom_domain]
  custom_domain_id = auth0_custom_domain.app_domain.id

  timeouts {
    create = "15m"
  }
}

# enable custom domain in Auth0
resource "auth0_custom_domain_default" "app_domain_default" {
  depends_on = [auth0_custom_domain_verification.app_domain_verification]
  domain = auth0_custom_domain.app_domain.domain
}
