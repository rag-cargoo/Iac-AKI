terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = [var.az_a, var.az_b]
  public_subnets  = [var.public_subnet_a_cidr, var.public_subnet_b_cidr]
  private_subnets = [var.private_subnet_a_cidr, var.private_subnet_b_cidr]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway   = true
  single_nat_gateway   = true
  one_nat_gateway_per_az = false
}

module "security" {
  source = "../../modules/security"

  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
  operator_cidr = var.my_ip
}

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  instance_type         = var.instance_type
  ssh_key_name          = var.ssh_key_name
  ssh_key_file_path     = var.ssh_key_file_path
  public_subnet_id      = module.vpc.public_subnets[0]
  private_subnet_map    = {
    "private-a" = module.vpc.private_subnets[0]
    "private-b" = module.vpc.private_subnets[1]
  }
  security_group_id     = module.security.security_group_id
  managers              = var.managers
  workers               = var.workers
}
