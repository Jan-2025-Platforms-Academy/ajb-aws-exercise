variable "region" {
  type        = string
  description = "Region to deploy resources into."
  default     = "eu-west-2"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability zones to deploy resources into."
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "app_instance_count" {
  type        = number
  description = "The number of EC2 Instance to deploy."
  default     = 4
}

variable "use_fargate" {
  type        = bool
  description = "Whether to deploy an ECS cluster using Fargate instead of EC2 instances."
  default     = false
}

variable "postgres_db_name" {
  type        = string
  description = "The name of the PostgreSQL database to create."
  default     = "sample"
}

variable "postgres_db_username" {
  type        = string
  description = "The username for the PostgreSQL database."
  default     = "pgadmin"
}
