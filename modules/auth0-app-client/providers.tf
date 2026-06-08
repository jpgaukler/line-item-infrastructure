terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.46.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }
}