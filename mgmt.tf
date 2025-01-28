module "mgmt_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.name}-mgmt-sg"
  description = "Security group for MGMT EC2 instance(s)"
  vpc_id      = module.vpc.vpc_id

  ingress_prefix_list_ids = [aws_ec2_managed_prefix_list.kainos.id, aws_ec2_managed_prefix_list.zscaler.id]
  ingress_with_prefix_list_ids = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    }
  ]

  egress_cidr_blocks = [var.vpc_address_range]
  egress_rules       = ["http-80-tcp", "https-443-tcp", "postgresql-tcp", "ssh-tcp"]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}


module "mgmt_ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-mgmt"

  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ajb.key_name
  monitoring                  = true
  vpc_security_group_ids      = [module.mgmt_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[2]
  associate_public_ip_address = true
  create_eip                  = true

  tags = local.tags
}
