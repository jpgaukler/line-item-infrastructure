module "line_item_container_app" {
  source = "../../../modules/ecs-express-container-app"

  environment_stage        = local.environment_stage
  app_name                 = local.api_name
  
  ecr_repository_arn = data.terraform_remote_state.global.outputs.ecr_repository_arn
  ecr_repository_url = data.terraform_remote_state.global.outputs.ecr_repository_url

  container_health_check_path     = "/health"
  container_cpu                   = local.ecs_container_cpu
  container_memory                = local.ecs_container_memory
  container_port                  = 8080
  container_image_tag             = "latest"
  container_environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Development"
  }

  github_actions_user_name = data.terraform_remote_state.global.outputs.github_actions_user_name

  tags = {
    Application = local.api_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}



module "auth0_api" {
  source = "../../../modules/auth0-api"

  environment_stage           = local.environment_stage
  api_name                    = local.api_name
  api_audience                = local.api_audience
  custom_claims_namespace     = "https://line-item.app"
  
  client_grants = {
    line_item_app = {
      client_id        = data.terraform_remote_state.line_item_app.outputs.auth0_client_id
      subject_type     = "user"
      allow_all_scopes = true
    }
  }

  api_scopes = [
    {
      name        = "read:products"
      description = "Read products"
    },
    {
      name        = "write:products"
      description = "Create and modify products"
    },
    {
      name        = "read:quotes"
      description = "Read quotes"
    },
    {
      name        = "write:quotes"
      description = "Create and modify quotes"
    }
  ]

  api_roles = {
    administrator = {
      name        = "Administrator"
      description = "Full privileges"
      permissions = [
        "read:products",
        "write:products",
        "read:quotes",
        "write:quotes"
      ]
    }

    reader = {
      name        = "Reader"
      description = "Read-only access"
      permissions = [
        "read:products",
        "read:quotes"
      ]
    }
  }
}