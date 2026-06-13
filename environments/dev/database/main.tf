module "rds_postgres_database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.0"

  identifier = "${local.name_prefix}-postgres"

  engine                     = "postgres"
  family                     = "postgres18"
  major_engine_version       = "18"
  engine_version             = "18.4"
  auto_minor_version_upgrade = true
  instance_class             = local.db_instance_class

  allocated_storage     = local.db_storage
  max_allocated_storage = local.db_max_storage_expansion
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = local.db_name
  username = "postgres"
  port     = "5432"
  manage_master_user_password = true
  
  create_db_subnet_group = false # this is created by vpc module
  db_subnet_group_name = data.terraform_remote_state.network.outputs.database_subnet_group_name
  
  vpc_security_group_ids = [
    aws_security_group.database.id
  ]
  
  publicly_accessible = false
  multi_az            = false

  backup_retention_period = local.db_backup_retention_period
  backup_window      = local.db_backup_window
  maintenance_window = local.db_maintenance_window

  deletion_protection = false
  skip_final_snapshot = true # should be false in production (enables final db snapshot upon deleting db)

  tags = local.tags
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-postgres-sg"
  description = "Allow Postgres database access"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-database-sg"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}