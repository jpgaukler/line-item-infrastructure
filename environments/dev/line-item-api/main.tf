module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name    = "${local.name_prefix}-alb"
  vpc_id  = data.terraform_remote_state.network.outputs.vpc_id
  subnets = data.terraform_remote_state.network.outputs.public_subnet_ids
  
  enable_deletion_protection = false # allow deletion for dev
  route53_records = {
    A = {
      zone_id = data.terraform_remote_state.global.outputs.route53_zone_id
      name    = local.api_domain
      type    = "A"
    }
  }

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

  security_group_tags = { 
    Name = "${local.name_prefix}-alb"
  }
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
      cidr_ipv4   = data.terraform_remote_state.network.outputs.vpc_cidr_block
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
      port              = local.container_port
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

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "7.5.0"

  cluster_name = "${local.name_prefix}-ecs-cluster"

  services = {
    line_item_api = {
      name                   = "${local.name_prefix}-ecs-service"
      desired_count          = 1 # should set to 2 or more for production
      launch_type            = "FARGATE"
      cpu                    = local.container_cpu
      memory                 = local.container_memory

      deployment_minimum_healthy_percent = 100
      deployment_maximum_percent         = 200
      deployment_circuit_breaker         = {
        enable   = true
        rollback = true
      }

      container_definitions = {
        api_container = {
          name      = local.api_name
          image     = "${data.terraform_remote_state.global.outputs.ecr_repository_url}:latest"
          essential = true
          readonlyRootFilesystem = false


          portMappings = [
            {
              name          = "http"
              containerPort = local.container_port
              hostPort      = local.container_port
              protocol      = "tcp"
            }
          ]

          environment = [
            {
              name  = "ASPNETCORE_ENVIRONMENT"
              value = "Development"
            }
          ]

          # secrets = {
          #   {
          #     name=
          #     valueFrom=
          #   }
          # }

          enable_cloudwatch_logging              = true
          cloudwatch_log_group_name              = "/ecs/${local.name_prefix}"
          cloudwatch_log_group_retention_in_days = 30
        }
      }

      vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
      subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids
      security_group_ingress_rules = {
        load_balancer = {
          description                  = "Allow inbound traffic from load balancer."
          from_port                    = local.container_port
          to_port                      = local.container_port
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.alb.security_group_id
        }
      }
      security_group_egress_rules = {
        all = {
          description = "Allow all outbound traffic."
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ecs-tasks"].arn
          container_name   = local.api_name
          container_port   = local.container_port
        }
      }

      task_exec_iam_role_use_name_prefix  = false
      tasks_iam_role_max_session_duration = 3600
    }
  }

  tags = {
    Application = local.api_name
    Environment = local.environment_stage
    ManagedBy   = "Terraform"
  }
}

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