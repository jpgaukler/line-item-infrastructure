locals {
  name_prefix = "${var.app_name}-${var.environment_stage}"
}

# =============================================
# CloudWatch Logs
# =============================================
resource "aws_cloudwatch_log_group" "service_log_group" {
  name              = "/ecs/${var.app_name}/${var.environment_stage}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}



# =============================================
# ECS Express Gateway Service
# =============================================
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${local.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_trust_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_infrastructure_role" {
  name               = "${local.name_prefix}-ecs-infrastructure-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_infrastructure_trust_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure_policy" {
  role       = aws_iam_role.ecs_infrastructure_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

resource "aws_ecs_express_gateway_service" "app_service" {
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_infrastructure_role.arn
  health_check_path       = var.container_health_check_path
  cpu                     = var.container_cpu
  memory                  = var.container_memory

  primary_container {
    image          = "${var.ecr_repository_url}:${var.container_image_tag}"
    container_port = var.container_port

    aws_logs_configuration {
      log_group         = aws_cloudwatch_log_group.service_log_group.name
      log_stream_prefix = local.name_prefix
    }

    dynamic "environment" {
      for_each = var.container_environment_variables

      content {
        name  = environment.key
        value = environment.value
      }
    }

    dynamic "secret" {
      for_each = var.container_secrets

      content {
        name       = secret.key
        value_from = secret.value
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_infrastructure_policy
  ]
}

# =============================================
# IAM User for GitHub Actions CI/CD
# =============================================
resource "aws_iam_policy" "github_actions_ecr_policy" {
  name   = "${local.name_prefix}-github-actions-ecr-policy"
  policy = data.aws_iam_policy_document.github_actions_ecr_policy_document.json

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "github_actions_ecr_policy_attachment" {
  user       = var.github_actions_user_name
  policy_arn = aws_iam_policy.github_actions_ecr_policy.arn
}