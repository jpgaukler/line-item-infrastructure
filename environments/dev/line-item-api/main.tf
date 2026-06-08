# Create the Private ECR repository to store container images
resource "aws_ecr_repository" "api_repo" {
  name                 = "aws-ecr-${local.api_name}-${local.environment_stage}"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "line_item_api_ecs_express_container_app" {
  source = "../../../modules/ecs-express-container-app"

  environment_stage        = local.environment_stage
  app_name                 = local.api_name
  
  ecr_repository_arn = aws_ecr_repository.api_repo.arn
  ecr_repository_url = aws_ecr_repository.api_repo.repository_url

  container_health_check_path = "/health"
  container_cpu    = local.ecs_container_cpu
  container_memory = local.ecs_container_memory
  container_port   = 8080
  container_image_tag = "latest"
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




# ============================================= Auth0 API =============================================
resource "auth0_resource_server" "api" {
  name        = "${local.api_name}-${local.environment_stage}"
  identifier  = local.api_audience
  signing_alg = "RS256"

  token_lifetime           = 86400 # 24 hours (in seconds)
  token_lifetime_for_web   = 7200  # 2 hours

  allow_offline_access                            = true
  skip_consent_for_verifiable_first_party_clients = true

  enforce_policies = true // enable RBAC
  token_dialect    = "access_token_authz" // include permission claims in access token

  # Application Access Policy (AAP) settings to enforce "per-app authorization"
  subject_type_authorization {
    user {
      policy = "require_client_grant" 
    }
    client {
      policy = "require_client_grant" 
    }
  }
}

# define api permissions (scopes)
resource "auth0_resource_server_scopes" "api_scopes" {
  resource_server_identifier = auth0_resource_server.api.identifier

  scopes {
    name        = "read:products"
    description = "Read products"
  }

  scopes {
    name        = "write:products"
    description = "Create and modify products"
  }

  scopes {
    name        = "read:quotes"
    description = "Read quotes"
  }

  scopes {
    name        = "write:quotes"
    description = "Create and modify quotes"
  }
}

# authorize client application to access API 
resource "auth0_client_grant" "app_client" {
  client_id        = data.terraform_remote_state.line_item_app.outputs.auth0_client_id
  audience         = auth0_resource_server.api.identifier
  subject_type     = "user"
  allow_all_scopes = true 
}

# define roles and permissions 
resource "auth0_role" "admin_role" {
  name        = "Administrator"
  description = "Full privileges"
}

resource "auth0_role_permissions" "admin_permissions" {
  role_id = auth0_role.admin_role.id

  dynamic "permissions" {
    for_each = auth0_resource_server_scopes.api_scopes.scopes
    
    content {
      name                       = permissions.value.name
      resource_server_identifier = auth0_resource_server.api.identifier
    }
  }

  depends_on = [auth0_resource_server_scopes.api_scopes]
}

# add custom claims to access token via Auth0 Action (for user initialization flow)
resource "auth0_action" "append_custom_claims" {
  name    = "Append Custom Claims"
  runtime = "node22"
  deploy  = true

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }

  code    = <<-EOT
  exports.onExecutePostLogin = async (event, api) => {
    const namespace = 'https://line-item.app';

    if (event.authorization) {
      api.accessToken.setCustomClaim(`$${namespace}/name`, event.user.name);
    }
  };
  EOT
}

resource "auth0_trigger_actions" "post_login" {
  trigger = "post-login"

  actions {
    id           = auth0_action.append_custom_claims.id
    display_name = auth0_action.append_custom_claims.name
  }
}

