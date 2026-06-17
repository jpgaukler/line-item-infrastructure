terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.42.0"
    }
  }

  required_version = ">= 1.14"

  backend "s3" {
    region = "us-east-2"
    bucket = "line-item-terraform-state"
    key = "environments/global/s3/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = "us-east-2"
}
