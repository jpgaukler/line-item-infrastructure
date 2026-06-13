data "terraform_remote_state" "global_route53" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/route53/terraform.tfstate"
    region  = "us-east-2"
  }
}
data "terraform_remote_state" "global_iam" {
  backend = "s3"

  config = {
    bucket  = "line-item-terraform-state"
    key     = "environments/global/iam/terraform.tfstate"
    region  = "us-east-2"
  }
}
