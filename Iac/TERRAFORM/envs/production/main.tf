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

module "network" {
  source = "../../modules/network"

  project_name           = var.project_name
  vpc_cidr               = var.vpc_cidr
  az_a                   = var.az_a
  az_b                   = var.az_b
  public_subnet_a_cidr   = var.public_subnet_a_cidr
  public_subnet_b_cidr   = var.public_subnet_b_cidr
  private_subnet_a_cidr  = var.private_subnet_a_cidr
  private_subnet_b_cidr  = var.private_subnet_b_cidr
}

module "security" {
  source = "../../modules/security"

  project_name  = var.project_name
  vpc_id        = module.network.vpc_id
  operator_cidr = var.my_ip
}

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  instance_type         = var.instance_type
  ssh_key_name          = var.ssh_key_name
  ssh_key_file_path     = var.ssh_key_file_path
  public_subnet_id      = module.network.public_subnet_a_id
  private_subnet_a_id   = module.network.private_subnet_a_id
  private_subnet_b_id   = module.network.private_subnet_b_id
  private_subnet_a_cidr = module.network.private_subnet_a_cidr_block
  private_subnet_b_cidr = module.network.private_subnet_b_cidr_block
  security_group_id     = module.security.security_group_id
  manager_ip            = var.manager_ip
  worker_nodes          = var.worker_nodes
}
