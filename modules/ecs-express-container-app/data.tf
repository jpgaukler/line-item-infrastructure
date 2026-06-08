# policy for ECS task execution role, allowing it to pull container images from ECR and write logs to CloudWatch
data "aws_iam_policy_document" "ecs_execution_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# policy for ECS infrastructure role, allowing it to create and manage load balancers on your behalf
data "aws_iam_policy_document" "ecs_infrastructure_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

# grant IAM user permissions for Github actions workflow
data "aws_iam_policy_document" "github_actions_ecr_policy_document" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    effect    = "Allow"
    resources = ["*"]
  }

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
    resources = [var.ecr_repository_arn]
  }

  statement {
    actions = [
      "ecs:UpdateService"
    ]

    effect    = "Allow"
    resources = [aws_ecs_express_gateway_service.app_service.service_arn]
  }
}