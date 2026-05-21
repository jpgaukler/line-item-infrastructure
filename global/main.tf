# ============================================= Route 53 Zone =============================================
# MANUAL STEP REQUIRED: after this is created, must update the nameservers in GoDaddy to the 4 name servers of the Route 53 zone
resource "aws_route53_zone" "app_zone" {
  name = local.app_domain
}

# SSL cert for custom domain
resource "aws_acm_certificate" "app_cert" {
  provider          = aws
  domain_name       = local.app_domain
  subject_alternative_names = ["*.${local.app_domain}"] // wildcard support
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Add records in Route 53 to validate the certificate
resource "aws_route53_record" "app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.app_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# This resource triggers the actual validation process and waits for it to complete
resource "aws_acm_certificate_validation" "app_cert_validation_waiter" {
  provider                = aws
  certificate_arn         = aws_acm_certificate.app_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_validation : record.fqdn]
}
