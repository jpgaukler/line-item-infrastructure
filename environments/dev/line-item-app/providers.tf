terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }

    auth0 = {
      source  = "auth0/auth0"
      version = "1.46.0"
    }
  }

  required_version = ">= 1.14"

  backend "s3" {
    region       = "us-east-2"
    bucket       = "line-item-terraform-state"
    key          = "environments/dev/line-item-app/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

# Pull Auth0 credentials from AWS Secrets Manager.See documentation about Auth0 Terraform provider here: 
# https://registry.terraform.io/providers/auth0/auth0/latest/docs/guides/quickstart#create-a-machine-to-machine-application
data "aws_secretsmanager_secret" "auth0_keys" {
  name = local.auth0_secrets_key
}

data "aws_secretsmanager_secret_version" "auth0_keys_latest" {
  secret_id = data.aws_secretsmanager_secret.auth0_keys.id
}

locals {
  auth0_secrets = jsondecode(data.aws_secretsmanager_secret_version.auth0_keys_latest.secret_string)
}

provider "auth0" {
  domain        = local.auth0_secrets.domain
  client_id     = local.auth0_secrets.client_id
  client_secret = local.auth0_secrets.client_secret
}
