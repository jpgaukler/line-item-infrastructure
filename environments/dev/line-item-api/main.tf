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

  tags = {
    Application = local.api_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name    = "${local.name_prefix}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  
  enable_deletion_protection = false # allow deletion for dev

  # access_logs = {
  #   bucket = module.log_bucket.s3_bucket_id
  #   prefix = "access-logs"
  # }
  # 
  # connection_logs = {
  #   bucket  = module.log_bucket.s3_bucket_id
  #   enabled = true
  #   prefix  = "connection-logs"
  # }
  # 
  # health_check_logs = {
  #   bucket = module.log_bucket.s3_bucket_id
  #   prefix = "health-check-logs"
  # }

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    # HTTPS Listener (Forwards secure traffic to your ECS tasks)
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.global.outputs.acm_certificate_us_east_2_arn

      forward = {
        target_group_key = "ecs-tasks"
      }
    }

    # HTTP Listener (Catch-all that redirects users to HTTPS)
    http-redirect = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301" # Permanent redirect
      }
    }
  }

  target_groups = {
    ecs-tasks = {
      protocol          = "HTTP" # Traffic FROM ALB to ECS can remain HTTP inside your private network
      port              = local.ecs_container_port
      target_type       = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        matcher             = "200"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
      }
    }
  }

  tags = {
    Application = local.api_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}

# module "ecs" {
#   source  = "terraform-aws-modules/ecs/aws"
#   version = "7.5.0"
# 
#   cluster_name = "${local.name_prefix}-ecs-cluster"
# 
#   services = {
#     line_item_api = {
#       name                   = "${local.name_prefix}-ecs-service"
#       desired_count          = 1 # should set to 2 or more for production
#       launch_type            = "FARGATE"
#       
#       subnet_ids             = module.vpc.private_subnets
#       security_group_ingress_rules = {
#         load_balancer_inbound = {
#           description     = "Allow application traffic from ALB"
#           from_port       = local.ecs_container_port
#           to_port         = local.ecs_container_port
#           protocol        = "tcp"
#           security_groups = [aws_security_group.load_balancer.id]
#         }
#       }
#       security_group_egress_rules = {
#         all_outbound = {
#           # ip_protocol = "-1"
#           # cidr_ipv4   = "0.0.0.0/0"
#           description = "Allow all outbound traffic"
#           from_port   = 0
#           to_port     = 0
#           protocol    = "-1"
#           cidr_blocks = ["0.0.0.0/0"]
#         }
#       }
# 
#       cpu    = local.ecs_container_cpu
#       memory = local.ecs_container_memory
#       enable_execute_command = true # allows exec into the container for debugging, should set to false for production
# 
#       deployment_minimum_healthy_percent = 100
#       deployment_maximum_percent         = 200
# 
#       deployment_circuit_breaker = {
#         enable   = true
#         rollback = true
#       }
# 
#       container_definitions = {
#         api_container = {
#           name      = local.api_name
#           image     = "${data.terraform_remote_state.global.outputs.ecr_repository_url}:latest"
#           essential = true
# 
#           port_mappings = [
#             {
#               name          = "http"
#               containerPort = local.ecs_container_port
#               hostPort      = local.ecs_container_port
#               protocol      = "tcp"
#             }
#           ]
# 
#           environment = [
#             {
#               name  = "ASPNETCORE_ENVIRONMENT"
#               value = "Development"
#             }
#           ]
# 
#           # secrets = {
#           #   {
#           #     name=
#           #     valueFrom=
#           #   }
#           # }
# 
#           readonly_root_filesystem = true
# 
#           enable_cloudwatch_logging = true
#           log_configuration = {
#             logDriver = "awslogs"
#             options = {
#               awslogs-group         = "/ecs/${local.name_prefix}"
#               awslogs-region        = data.aws_region.current
#               awslogs-stream-prefix = local.api_name
#             }
#           }
#         }
#       }
# 
#       load_balancer = {
#         service = {
#           target_group_arn = "arn" #aws_lb_target_group.api.arn
#           container_name   = local.api_name
#           container_port   = local.ecs_container_port
#         }
#       }
#     }
#   }
# 
#   tags = {
#     Application = local.api_name
#     Environment = local.environment_stage
#     ManagedBy   = "Terraform"
#   }
# }
# 

module "auth0_api" {
  source = "../../../modules/auth0-api"

  environment_stage           = local.environment_stage
  api_name                    = local.api_name
  api_audience                = local.auth0_api_audience
  custom_claims_namespace     = "https://line-item.app"
  
  client_grants = {
    line_item_app = {
      client_id        = data.terraform_remote_state.line_item_app.outputs.auth0_client_id
      subject_type     = "user"
      allow_all_scopes = true
    }
  }

  api_scopes = [
    {
      name        = "read:products"
      description = "Read products"
    },
    {
      name        = "write:products"
      description = "Create and modify products"
    },
    {
      name        = "read:quotes"
      description = "Read quotes"
    },
    {
      name        = "write:quotes"
      description = "Create and modify quotes"
    }
  ]

  api_roles = {
    administrator = {
      name        = "Administrator"
      description = "Full privileges"
      permissions = [
        "read:products",
        "write:products",
        "read:quotes",
        "write:quotes"
      ]
    }

    reader = {
      name        = "Reader"
      description = "Read-only access"
      permissions = [
        "read:products",
        "read:quotes"
      ]
    }
  }
}