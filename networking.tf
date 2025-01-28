module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}-vpc"
  cidr = var.vpc_address_range

  azs                   = var.availability_zones
  private_subnets       = local.private_subnets
  private_subnet_names  = [for index in range(length(local.private_subnets)) : "${var.name}-private-${index + 1}"]
  database_subnets      = local.database_subnets
  database_subnet_names = [for index in range(length(local.database_subnets)) : "${var.name}-db-${index + 1}"]
  public_subnets        = local.public_subnets
  public_subnet_names   = ["${var.name}-alb-1", "${var.name}-alb-2", "${var.name}-mgmt"]

  enable_nat_gateway = true
  single_nat_gateway = true

  create_database_nat_gateway_route = true
  create_private_nat_gateway_route  = true

  create_igw = true

  tags = local.tags
}

resource "aws_ec2_managed_prefix_list" "kainos" {
  name           = "Kainos ZScaler IPs"
  address_family = "IPv4"
  max_entries    = 2

  entry {
    cidr = "172.187.228.24/30"
  }

  entry {
    cidr = "20.39.229.20/30"
  }

  tags = local.tags
}

resource "aws_ec2_managed_prefix_list" "zscaler" {
  name           = "ZScaler IPs"
  address_family = "IPv4"
  max_entries    = length(local.zscaler_prefixes)
}

resource "aws_ec2_managed_prefix_list_entry" "zscaler_ips" {
  for_each       = { for ip in local.zscaler_prefixes : ip => ip if !strcontains(ip, ":") }
  prefix_list_id = aws_ec2_managed_prefix_list.zscaler.id
  cidr           = each.value
}
