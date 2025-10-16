terraform {
  required_version = ">= 1.5.0"
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

module "s2s_vpn" {
  source = "../../modules/s2s_vpn"

  project_name             = var.project_name
  vpc_id                   = var.vpc_id
  customer_gateway_ip      = var.customer_gateway_ip
  customer_gateway_bgp_asn = var.customer_gateway_bgp_asn
  amazon_side_asn          = var.amazon_side_asn
  remote_ipv4_cidrs        = var.remote_ipv4_cidrs
  tunnel1_preshared_key    = var.tunnel1_preshared_key
  tunnel2_preshared_key    = var.tunnel2_preshared_key
  route_table_ids          = var.route_table_ids
}
