# =============================================
# Load Balancer
# =============================================
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name    = "${local.name_prefix}-alb"
  vpc_id  = data.terraform_remote_state.network.outputs.vpc_id
  subnets = data.terraform_remote_state.network.outputs.public_subnet_ids
  
  enable_deletion_protection = false # allow deletion for dev
  route53_records = {
    A = {
      zone_id = data.terraform_remote_state.global_route53.outputs.route53_zone_id
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
      certificate_arn = data.terraform_remote_state.global_route53.outputs.acm_certificate_us_east_2_arn

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
      port              = local.api_container_port
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

  tags = local.tags
}



# =============================================
# ECS Service for API and Migrations
# =============================================
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "7.5.0"

  cluster_name = "${local.name_prefix}-ecs-cluster"

  services = {
    line_item_api = {
      name                   = "${local.name_prefix}-ecs-service"
      launch_type            = "FARGATE"
      desired_count          = local.api_container_count
      cpu                    = local.api_container_cpu
      memory                 = local.api_container_memory

      deployment_minimum_healthy_percent = 100
      deployment_maximum_percent         = 200
      deployment_circuit_breaker         = {
        enable   = true
        rollback = true
      }

      container_definitions = {
        api_container = {
          name      = local.api_name
          image     = jsondecode(data.aws_ecs_task_definition.current_api_revision.container_definitions)[0].image # image tag gets updated by Github Actions
          # image     = "${data.terraform_remote_state.global_ecr.outputs.ecr_api_repository_url}:latest" # uncomment for initial creation
          essential = true
          readonlyRootFilesystem = false

          portMappings = [
            {
              name          = "http"
              containerPort = local.api_container_port
              hostPort      = local.api_container_port
              protocol      = "tcp"
            }
          ]

          environment = [
            {
              name  = "DOTNET_ENVIRONMENT"
              value = local.environment_stage
            },
            {
              name  = "DatabaseOptions__Host"
              value = data.terraform_remote_state.database.outputs.db_instance_address
            },
            {
              name  = "DatabaseOptions__Port"
              value = data.terraform_remote_state.database.outputs.db_instance_port
            },
            {
              name  = "DatabaseOptions__Database"
              value = data.terraform_remote_state.database.outputs.db_instance_name
            },
          ]

          secrets = [
            {
              name      = "DatabaseOptions__Username"
              valueFrom = "${data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn}:username::"
            },
            {
              name      = "DatabaseOptions__Password"
              valueFrom = "${data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn}:password::"
            }
          ]

          enable_cloudwatch_logging              = true
          cloudwatch_log_group_name              = "/ecs/${local.api_name}/${local.environment_stage}"
          cloudwatch_log_group_retention_in_days = local.cloudwatch_log_retention_days
        }
      }

      vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
      subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids
      security_group_ingress_rules = {
        load_balancer = {
          description                  = "Allow inbound traffic from load balancer."
          from_port                    = local.api_container_port
          to_port                      = local.api_container_port
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
          container_port   = local.api_container_port
        }
      }

      task_exec_iam_role_use_name_prefix  = false
      tasks_iam_role_max_session_duration = 3600
      task_exec_iam_statements = [
        {
          actions = [
            "secretsmanager:GetSecretValue"
          ]
          resources = [
            data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn
          ]
        }
      ]
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "migrations" {
  name              = "/ecs/${local.migrations_name}/${local.environment_stage}"
  retention_in_days = local.cloudwatch_log_retention_days
  tags = local.tags
}

resource "aws_ecs_task_definition" "migrations" {
  family                   = "${local.name_prefix}-migrations"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.migrations_cpu
  memory                   = local.migrations_memory
  execution_role_arn       = module.ecs.services["line_item_api"].task_exec_iam_role_arn
  track_latest             = true

  container_definitions = jsonencode([
    {
      name      = local.migrations_name
      image     = jsondecode(data.aws_ecs_task_definition.current_migrations_revision.container_definitions)[0].image # image tag gets updated by Github Actions
      # image     =  "${data.terraform_remote_state.global_ecr.outputs.ecr_migrations_repository_url}:latest" # uncomment for initial creation
      essential = true
      readonlyRootFilesystem = false

      environment = [
        {
          name  = "DOTNET_ENVIRONMENT"
          value = local.environment_stage
        },
        {
          name  = "DatabaseOptions__Host"
          value = data.terraform_remote_state.database.outputs.db_instance_address
        },
        {
          name  = "DatabaseOptions__Port"
          value = tostring(data.terraform_remote_state.database.outputs.db_instance_port)
        },
        {
          name  = "DatabaseOptions__Database"
          value = data.terraform_remote_state.database.outputs.db_instance_name
        },
      ]

      secrets = [
        {
          name      = "DatabaseOptions__Username"
          valueFrom = "${data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn}:username::"
        },
        {
          name      = "DatabaseOptions__Password"
          valueFrom = "${data.terraform_remote_state.database.outputs.db_instance_master_user_secret_arn}:password::"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.migrations.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ecs_to_database" {
  security_group_id            = data.terraform_remote_state.database.outputs.db_security_group_id
  referenced_security_group_id = module.ecs.services["line_item_api"].security_group_id

  description = "Postgres traffic from ECS API"
  from_port   = data.terraform_remote_state.database.outputs.db_instance_port
  to_port     = data.terraform_remote_state.database.outputs.db_instance_port
  ip_protocol = "tcp"

  tags = local.tags
}




# =============================================
# Auth0 API Server
# =============================================
module "auth0_api" {
  source = "../../../modules/auth0-api"

  environment_stage           = local.environment_stage
  api_name                    = local.api_name
  api_audience                = local.auth0_api_audience
  custom_claims_namespace     = "https://line-item.app"
  
  client_grants = {
    line_item_app = {
      client_id        = data.terraform_remote_state.app.outputs.auth0_client_id
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




# =============================================
# IAM User for GitHub Actions CI/CD
# =============================================
resource "aws_iam_policy" "github_actions_ecr_policy" {
  name   = "${local.name_prefix}-github-actions-ecr-policy"
  policy = data.aws_iam_policy_document.github_actions_ecr_policy_document.json

  tags = local.tags
}

resource "aws_iam_user_policy_attachment" "github_actions_ecr_policy_attachment" {
  user       = data.terraform_remote_state.global_iam.outputs.github_actions_user_name
  policy_arn = aws_iam_policy.github_actions_ecr_policy.arn
}

