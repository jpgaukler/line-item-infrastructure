# ============================================= AWS ECS Express =============================================

# Create the ECS Execution IAM Role
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs-execution-role-${local.api_name}-${local.environment_stage}"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create the ECS Infrastructure IAM Role
resource "aws_iam_role" "ecs_infrastructure_role" {
  name               = "ecs-infrastructure-role-${local.api_name}-${local.environment_stage}"
  assume_role_policy = data.aws_iam_policy_document.ecs_infrastructure_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

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

# Create CloudWatch Log Group for Container logs
resource "aws_cloudwatch_log_group" "api_log_group" {
  name              = "/ecs/${local.api_name}/${local.environment_stage}"
  retention_in_days = 7  
}

# 3. The Express Mode Service (Automates the deployment)
resource "aws_ecs_express_gateway_service" "api_ecs_service" {
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_infrastructure_role.arn
  health_check_path       = "/health"

  primary_container {
    image          = "${aws_ecr_repository.api_repo.repository_url}:latest"
    container_port = 8080

    aws_logs_configuration {
      log_group = aws_cloudwatch_log_group.api_log_group.name
      log_stream_prefix = "${local.api_name}-${local.environment_stage}"
    }

    # environment {
    #   name  = "ENV"
    #   value = "development"
    # }

    # environment {
    #   name  = "PORT"
    #   value = "8080"
    # }

    # secret {
    #   name       = "DB_PASSWORD"
    #   value_from = aws_secretsmanager_secret.db_password.arn
    # }
  }

  # NOT SURE IF I NEED THIS, AI TOLD ME TO DO IT BUT IT SEEMS TO HAVE NO EFFECT
  # ignore changes to the container image to prevent Terraform from flagging state changes, 
  # since the Github Actions workflow will be deploying new images with the same "latest" tag
  # lifecycle {
  #   ignore_changes = [
  #     primary_container[0].image
  #   ]
  # }

  # Prevent race conditions 
  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy_attachment.ecs_infrastructure
  ]
}



# ============================================= IAM User for CI/CD =============================================
resource "aws_iam_policy" "github_actions_user_ecr_policy" {
  name   = "github-actions-ecr-policy-${local.api_name}-${local.environment_stage}"
  policy = data.aws_iam_policy_document.github_actions_user_ecr_policy_document.json
}

resource "aws_iam_user_policy_attachment" "github_actions_user_ecr_policy_attachment" {
  user       = data.terraform_remote_state.global.outputs.github_actions_user_name
  policy_arn = aws_iam_policy.github_actions_user_ecr_policy.arn
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

