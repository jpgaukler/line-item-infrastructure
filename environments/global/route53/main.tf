# ============================================= Route 53 Zone =============================================
# MANUAL STEP REQUIRED: after this is created, must update the nameservers in GoDaddy to the 4 name servers of the Route 53 zone
resource "aws_route53_zone" "app_zone" {
  name = local.app_domain
}

# SSL cert in us-east-1 (Cloudfront requires us-east-1)
resource "aws_acm_certificate" "app_cert_us_east_1" {
  provider          = aws.us_east_1
  domain_name       = local.app_domain
  subject_alternative_names = [
    "*.${local.app_domain}",
    "*.api.${local.app_domain}"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_us_east_1_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_cert_us_east_1.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "app_cert_us_east_1_validation_waiter" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.app_cert_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_us_east_1_validation : record.fqdn]
}


# SSL cert in us-east-2 (ALB requires that cert is in same region as ALB)
resource "aws_acm_certificate" "app_cert_us_east_2" {
  domain_name       = local.app_domain
  subject_alternative_names = [
    "*.${local.app_domain}",
    "*.api.${local.app_domain}"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_us_east_2_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_cert_us_east_2.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "app_cert_us_east_2_validation_waiter" {
  certificate_arn         = aws_acm_certificate.app_cert_us_east_2.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_us_east_2_validation : record.fqdn]
}
