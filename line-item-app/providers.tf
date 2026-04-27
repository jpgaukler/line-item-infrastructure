terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }

  required_version = ">= 1.14"

  backend "s3" {
    bucket       = "line-item-terraform-state"
    key          = "line-item-app/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

# Provider for ACM (Must be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}