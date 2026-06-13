locals {
  environment_stage = "dev"
  app_name          = "line-item"
  name_prefix       = "${local.app_name}-${local.environment_stage}"
  
  db_name                    = "lineitem"
  db_instance_class          = "db.t4g.micro"
  db_storage                 = 20
  db_max_storage_expansion   = 20 # don't allow storage autoscaling for dev
  db_backup_retention_period = 1 # maximum allowed by aws free tier
  db_backup_window           = "03:00-06:00"
  db_maintenance_window      = "Mon:00:00-Mon:03:00"

  tags = {
    Application = local.app_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}
