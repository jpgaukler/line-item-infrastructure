data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/terraform.tfstate"
    region  = "us-east-2"
  }
}
