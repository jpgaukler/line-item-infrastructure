output "route53_zone_name_servers" {
  value = aws_route53_zone.app_zone.name_servers
}

output "route53_zone_id" {
  value = aws_route53_zone.app_zone.zone_id
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.app_cert.arn
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

output "ecr_repository_arn" {
  value = aws_ecr_repository.api_repo.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api_repo.repository_url
}
