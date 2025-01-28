module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${var.name}-alb"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  enable_deletion_protection = false

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
      cidr_ipv4   = var.vpc_address_range
    }
  }

  listeners = {
    https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = var.use_fargate ? "${var.name}-ecs" : "${var.name}-ec2"
      }
    }
  }

  target_groups = {
    "${var.name}-ecs" = {
      protocol                          = "HTTP"
      port                              = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
    "${var.name}-ec2" = {
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false
    }
  }

  additional_target_group_attachments = {
    for index in range(var.app_instance_count) : "${var.name}-ec2-${index}" => {
      target_group_key = "${var.name}-ec2"
      target_type      = "instance"
      target_id        = module.app_ec2[index].id
      port             = "80"
    }
  }

  tags = local.tags
}
