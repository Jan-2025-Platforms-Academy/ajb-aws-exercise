data "aws_route53_zone" "public" {
  name         = "aws.lab.bancey.xyz"
  private_zone = false
}

resource "aws_route53_record" "public" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "ajb-webapp"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mgmt" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "ajb-mgmt"
  type    = "A"
  ttl     = 300
  records = [module.mgmt_ec2.public_ip]
}

resource "aws_route53_zone" "private" {
  name = "aws-internal.lab.bancey.xyz"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "private_ec2" {
  count   = var.app_instance_count
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.name}-app-${count.index}"
  type    = "A"
  ttl     = 300
  records = [module.app_ec2[count.index].private_ip]
}
