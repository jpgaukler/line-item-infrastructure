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
