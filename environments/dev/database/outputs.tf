output "db_instance_endpoint" {
  description = "Postgres RDS database endpoint."
  value       = module.rds_postgres_database.db_instance_endpoint
}

output "db_instance_address" {
  description = "Postgres RDS database address."
  value       = module.rds_postgres_database.db_instance_address
}

output "db_instance_name" {
  description = "Postgres database name."
  value       = module.rds_postgres_database.db_instance_name
}

output "db_instance_port" {
  description = "Postgres database port."
  value       = module.rds_postgres_database.db_instance_port
}

output "db_security_group_id" {
  description = "Security group ID attached to the Postgres database."
  value       = aws_security_group.database.id
}

output "db_instance_master_user_secret_arn" {
  description = "Db instance identifier for the database."
  value       = module.rds_postgres_database.db_instance_master_user_secret_arn
}
