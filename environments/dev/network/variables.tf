locals {
  environment_stage  = "dev"
  app_name           = "line-item"
  name_prefix        = "${local.app_name}-${local.environment_stage}"

  tags = {
    Application = local.app_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}
