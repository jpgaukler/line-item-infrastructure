data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/network/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "app" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/app/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "global_route53" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/route53/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "global_ecr" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/ecr/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "global_iam" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/iam/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/database/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "auth0_tenant" "current" {}


# grant IAM user permissions for Github actions workflow
data "aws_iam_policy_document" "github_actions_ecr_policy_document" {
  # Authenticate with ECR
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    effect    = "Allow"
    resources = ["*"]
  }
  
  # Push/pull images from ECR
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    effect    = "Allow"
    resources = [
      data.terraform_remote_state.global_ecr.outputs.ecr_api_repository_arn,
      data.terraform_remote_state.global_ecr.outputs.ecr_migrations_repository_arn
    ]
  }

  # Run ECS service and migration tasks
  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "ecs:TagResource"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:task-definition/${module.ecs.services["line_item_api"].task_definition_family}:*"
    ]
  }
  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    effect    = "Allow"
    resources = [
      module.ecs.services["line_item_api"].id
    ]
  }
  statement {
    actions = [
      "iam:PassRole"
    ]
    effect    = "Allow"
    resources = [
      module.ecs.services["line_item_api"].task_exec_iam_role_arn,
      module.ecs.services["line_item_api"].tasks_iam_role_arn
    ]
  }
  statement {
    actions = [
      "ecs:RunTask"
    ]
    effect    = "Allow"
    resources = [aws_ecs_task_definition.migrations.arn]
  }
  statement {
    actions   = [
      "ecs:DescribeTasks"
    ]
    effect    = "Allow"
    resources = ["arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:task/${module.ecs.cluster_name}/*"]
  }
  statement {
    actions = [
      "logs:FilterLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.migrations.arn}:*"]
  }
}