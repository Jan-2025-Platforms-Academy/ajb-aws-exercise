terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.6-alpha1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }

  backend "s3" {}
}

provider "aws" {
  profile = "aws-sso-kpa"

  region = var.region
}

provider "cloudinit" {}

provider "http" {}

provider "random" {}
