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
    key          = "dev/line-item-app/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

# Provider for AWS Certificate Manager (Must be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "auth0" {
  domain        = local.auth0_secrets.domain
  client_id     = local.auth0_secrets.client_id
  client_secret = local.auth0_secrets.client_secret
}
