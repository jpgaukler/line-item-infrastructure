locals {
  environment_stage  = "dev"
  name               = "line-item-db"
  name_prefix        = "${local.name}-${local.environment_stage}"
  db_name            = "lineitem"

  tags = {
    Application = "line-item"
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}
