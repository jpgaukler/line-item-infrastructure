# =============================================
# Auth0 Application Client
# =============================================
resource "auth0_client" "app_client" {
  name            = "${var.app_name}-${var.environment_stage}"
  logo_uri        = var.app_logo_uri
  description     = "Managed by Terraform"
  app_type        = var.app_type
  oidc_conformant = true
  grant_types     = var.grant_types

  # URLs required for authentication flow
  callbacks           = var.allowed_web_urls
  allowed_logout_urls = var.allowed_web_urls
  allowed_origins     = var.allowed_web_urls
  web_origins         = var.allowed_web_urls

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

resource "auth0_custom_domain" "app_login_domain" {
  domain     = var.custom_login_domain
  type       = "auth0_managed_certs"
  tls_policy = "recommended"
}

# Validate the custom domain on Auth0 side
resource "auth0_custom_domain_verification" "app_domain_verification" {
  depends_on       = [aws_route53_record.auth0_custom_domain]
  custom_domain_id = auth0_custom_domain.app_login_domain.id

  timeouts {
    create = "15m"
  }
}

# enable custom domain in Auth0
resource "auth0_custom_domain_default" "app_domain_default" {
  depends_on = [auth0_custom_domain_verification.app_domain_verification]
  domain     = auth0_custom_domain.app_login_domain.domain
}



# =============================================
# Route 53 Records
# =============================================
resource "aws_route53_record" "auth0_custom_domain" {
  zone_id = var.route53_zone_id
  name    = auth0_custom_domain.app_login_domain.verification[0].methods[0].domain
  type    = upper(auth0_custom_domain.app_login_domain.verification[0].methods[0].name)
  records = [auth0_custom_domain.app_login_domain.verification[0].methods[0].record]
  ttl     = 60
}
