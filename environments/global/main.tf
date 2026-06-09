# ============================================= Route 53 Zone =============================================
# MANUAL STEP REQUIRED: after this is created, must update the nameservers in GoDaddy to the 4 name servers of the Route 53 zone
resource "aws_route53_zone" "app_zone" {
  name = local.app_domain
}

# SSL cert for custom domain
resource "aws_acm_certificate" "app_cert" {
  provider          = aws.us_east_1
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

resource "aws_acm_certificate_validation" "app_cert_validation_waiter" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.app_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_validation : record.fqdn]
}


# ============================================= IAM User for Github Actions =============================================
resource "aws_iam_user" "github_actions_user" {
  name          = "github-actions-user"
  path          = "/"
  force_destroy = true # Allows destroying user even if they have non-Terraform managed keys
}

resource "aws_iam_access_key" "github_actions_user_access_key" {
  user = aws_iam_user.github_actions_user.name
}




# ============================================= ECR Container Registry =============================================
resource "aws_ecr_repository" "api_repo" {
  name                 = "line-item/line-item-api"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

