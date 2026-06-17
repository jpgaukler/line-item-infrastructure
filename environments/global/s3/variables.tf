locals {
  app_name = "line-item"
  
  tags = {
    Application = local.app_name
    ManagedBy   = "Terraform"
  }
}
