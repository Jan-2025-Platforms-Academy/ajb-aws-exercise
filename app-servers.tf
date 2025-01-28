module "app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.name}-app-sg"
  description = "Security group for App EC2 instance(s)"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.mgmt_sg.security_group_id
    },
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.mgmt_sg.security_group_id
    },
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = var.vpc_address_range
    }
  ]

  tags = local.tags
}


module "app_ec2" {
  count  = var.app_instance_count
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-app-${count.index}"

  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ajb.key_name
  monitoring                  = true
  vpc_security_group_ids      = [module.app_sg.security_group_id]
  subnet_id                   = count.index % 2 == 0 ? module.vpc.private_subnets[0] : module.vpc.private_subnets[1]
  associate_public_ip_address = false

  user_data = data.cloudinit_config.app_ec2_config[count.index].rendered

  tags = local.tags
}
