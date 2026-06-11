locals {
  environment_stage  = "dev"
  app_name           = "line-item"
  name_prefix        = "${local.app_name}-${local.environment_stage}"
}
