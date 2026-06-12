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

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/terraform.tfstate"
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

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn
}

data "auth0_tenant" "current" {}
