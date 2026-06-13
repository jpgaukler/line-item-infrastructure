output "route53_zone_name_servers" {
  value = aws_route53_zone.app_zone.name_servers
}

output "route53_zone_id" {
  value = aws_route53_zone.app_zone.zone_id
}

output "acm_certificate_us_east_1_arn" {
  value = aws_acm_certificate.app_cert_us_east_1.arn
}

output "acm_certificate_us_east_2_arn" {
  value = aws_acm_certificate.app_cert_us_east_2.arn
}
