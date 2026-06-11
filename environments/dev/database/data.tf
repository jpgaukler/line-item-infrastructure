data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/dev/network/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "terraform_remote_state" "api" {
  backend = "s3"

  config = {
    bucket = "line-item-terraform-state"
    key    = "environments/dev/api/terraform.tfstate"
    region = "us-east-2"
  }
}