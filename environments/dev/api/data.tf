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


data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/database/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "aws_region" "current" {}

data "auth0_tenant" "current" {}
