module "database_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.name}-db-sg"
  description = "Security group for RDS instance(s)"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp"]

  tags = local.tags
}

resource "random_password" "pgsql" {
  length  = 64
  special = false
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.name}-db"

  allocated_storage = 8

  engine                   = "postgres"
  engine_version           = "16"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres16" # DB parameter group
  major_engine_version     = "16"         # DB option group
  instance_class           = "db.c6gd.medium"

  db_name                     = var.postgres_db_name
  username                    = var.postgres_db_username
  manage_master_user_password = false
  password                    = random_password.pgsql.result
  port                        = 5432

  multi_az = true

  vpc_security_group_ids = [module.database_sg.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = local.tags

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}
