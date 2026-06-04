data "terraform_remote_state" "line_item_app" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "dev/line-item-app/terraform.tfstate"
    region  = "us-east-2"
  }
}

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

# used to output Auth0 tenant domain in outputs.tf
data "auth0_tenant" "current" {}

# used to retrieve Auth0 credentials from AWS Secrets Manager, this was manually added to AWS via the Management Console
# see documenation about Auth0 Terraform provider here: 
# https://registry.terraform.io/providers/auth0/auth0/latest/docs/guides/quickstart#create-a-machine-to-machine-application
data "aws_secretsmanager_secret" "auth0_keys" {
  name = local.auth0_secrets_key
}

data "aws_secretsmanager_secret_version" "auth0_keys_latest" {
  secret_id = data.aws_secretsmanager_secret.auth0_keys.id
}
