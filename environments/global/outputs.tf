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

output "github_actions_user_name" {
  value = aws_iam_user.github_actions_user.name
}

output "github_actions_user_access_key_id" {
  value = aws_iam_access_key.github_actions_user_access_key.id
}

output "github_actions_user_secret_access_key" {
  value     = aws_iam_access_key.github_actions_user_access_key.secret
  sensitive = true
}

output "ecr_api_repository_arn" {
  value = aws_ecr_repository.api_repo.arn
}

output "ecr_migrations_repository_arn" {
  value = aws_ecr_repository.migrations_repo.arn
}

output "ecr_api_repository_url" {
  value = aws_ecr_repository.api_repo.repository_url
}

output "ecr_migrations_repository_url" {
  value = aws_ecr_repository.migrations_repo.repository_url
}
