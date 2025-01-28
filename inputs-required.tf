variable "name" {
  type        = string
  description = "Name prefix to append to resource names."
}

variable "vpc_address_range" {
  type        = string
  description = "CIDR prefix defining the IP addresses for the VPC."
}

variable "private_subnet_range" {
  type = list(string)
  default = ["10.151.134.0/27", "10.151.134.32/27"]
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the SSL certificate to use for HTTPS listeners."
}

variable "ami_id" {
  type = string
  description = "ID of the AMI to use for the EC2 instances."
}
