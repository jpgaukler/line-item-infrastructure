output "postgres_db_instance_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = module.rds_postgres_database.db_instance_endpoint
}

output "postgres_db_instance_address" {
  description = "PostgreSQL RDS address"
  value       = module.rds_postgres_database.db_instance_address
}

output "postgres_db_name" {
  description = "PostgreSQL database name"
  value       = module.rds_postgres_database.db_instance_name
}

output "postgres_security_group_id" {
  description = "Security group ID for PostgreSQL"
  value       = module.database_security_group.id
}
