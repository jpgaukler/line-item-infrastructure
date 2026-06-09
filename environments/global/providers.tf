terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }

  required_version = ">= 1.14"

  backend "s3" {
    region = "us-east-2"
    bucket = "line-item-terraform-state"
    key = "environments/global/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = "us-east-2"
}

# Provider must be us-east-1 for AWS Certificate Manager certificates used by CloudFront
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}
