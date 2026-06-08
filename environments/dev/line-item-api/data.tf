data "terraform_remote_state" "line_item_app" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/line-item-app/terraform.tfstate"
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

data "auth0_tenant" "current" {}

