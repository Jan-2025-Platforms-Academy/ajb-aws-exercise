module "ecs_cluster" {
  count  = var.use_fargate ? 1 : 0
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = "${var.name}-ecs"

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}
resource "aws_service_discovery_http_namespace" "this" {
  name        = var.name
  description = "CloudMap namespace for ${var.name}"
  tags        = local.tags
}
module "ecs_service" {
  count  = var.use_fargate ? 1 : 0
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "${var.name}-ecs-service"
  cluster_arn = module.ecs_cluster[0].arn

  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = true


  # Container definition(s)
  container_definitions = {

    (local.container_name) = {
      readonly_root_filesystem = false
      cpu                      = 512
      memory                   = 1024
      essential                = true
      image                    = "ghcr.io/bancey/academy-sample-php-app:sha-f93e144"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "DB_SERVER"
          value = module.db.db_instance_address
        },
        {
          name  = "DB_USERNAME"
          value = var.postgres_db_username
        },
        {
          name  = "DB_PASSWORD"
          value = random_password.pgsql.result
        },
        {
          name  = "DB_DATABASE"
          value = var.postgres_db_name
        }
      ]
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["${var.name}-ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids            = module.vpc.private_subnets
  security_group_ids    = [module.app_sg.security_group_id]
  create_security_group = false

  service_tags = local.tags

  tags = local.tags
}
