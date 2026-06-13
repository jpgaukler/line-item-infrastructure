module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  create_database_subnet_group = true
  create_database_subnet_route_table = true # isolate the database subnet completely so it has no route to the internet

  enable_nat_gateway = true # Required for ECS Fargate tasks to reach the internet
  single_nat_gateway = true # Cost-saving for dev. For production, prefer one NAT Gateway per AZ.

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}
