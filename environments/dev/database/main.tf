module "rds_postgres_database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.0"

  identifier = "${local.name_prefix}-postgres"

  engine                     = "postgres"
  family                     = "postgres18"
  major_engine_version       = "18"
  engine_version             = "18.4"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 20 # don't allow storage autoscaling for dev
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

  backup_retention_period = 1 # maximum allowed by aws free tier
  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:03:00"

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
}