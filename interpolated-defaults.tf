locals {
  tags = {
    Terraform   = "true"
    Owner       = "ajb"
    Environment = "dev"
  }

  subnet_split           = cidrsubnets(var.vpc_address_range, 1, 1)
  private_address_range  = cidrsubnets(local.subnet_split[0], 1, 1)
  private_subnets        = cidrsubnets(local.private_address_range[0], 2, 2)
  database_address_range = cidrsubnets(local.private_address_range[1], 1, 1)[1]
  database_subnets       = cidrsubnets(local.database_address_range, 2, 2, 2)
  public_address_range   = local.subnet_split[1]
  public_subnets         = cidrsubnets(local.public_address_range, 2, 2, 2)

  zscaler_prefixes = jsondecode(data.http.zscaler_ips.response_body).prefixes

  container_name = "ecs-sample-php-webapp"
  container_port = 80
}

data "http" "zscaler_ips" {
  url = "https://config.zscaler.com/api/zscaler.net/future/json"
  request_headers = {
    Accept = "application/json"
  }
}

data "cloudinit_config" "app_ec2_config" {
  count         = var.app_instance_count
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    content = <<-EOL
    #cloud-config
    ${jsonencode({
    write_files = [
      {
        path        = "/etc/nginx/sites-available/webapp"
        permissions = "0644"
        owner       = "root:root"
        encoding    = "b64"
        content     = base64encode(file("./templates/nginx_config"))
      },
      {
        path        = "/var/www/inc/dbinfo.inc"
        permissions = "0644"
        owner       = "root:root"
        encoding    = "b64"
        content = base64encode(templatefile("./templates/dbinfo.inc", {
          DB_ENDPOINT = module.db.db_instance_address
          DB_USER     = var.postgres_db_username
          DB_PASSWORD = random_password.pgsql.result
          DB_DATABASE = var.postgres_db_name
        }))
      },
      {
        path        = "/var/www/html/index.php"
        permissions = "0644"
        owner       = "root:root"
        encoding    = "b64"
        content = base64encode(templatefile("./templates/index.php", {
          INSTANCE_NAME = "${var.name}-app-${count.index}"
        }))
      }
    ]
})}
  EOL
}

part {
  content_type = "text/x-shellscript"
  filename     = "install.sh"
  content      = <<-EOF
      #!/bin/bash
      apt update && apt upgrade-y
      apt install -y nginx php8.3-fpm php-pgsql
      rm /var/www/html/index.nginx-debian.html
      rm /var/www/html/index.html

      ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
      unlink /etc/nginx/sites-enabled/default
      systemctl reload nginx
    EOF
}
}
