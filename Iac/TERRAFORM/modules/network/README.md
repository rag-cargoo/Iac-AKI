# Network Module

Provision the core VPC networking stack for the Docker Swarm environment, including:

- VPC with DNS support
- Public and private subnets across two Availability Zones
- Internet Gateway, NAT Gateway, and associated Elastic IP
- Public and private route tables with associations

## Inputs
- `project_name` (string): Prefix used in resource tags.
- `vpc_cidr` (string): CIDR block for the VPC.
- `az_a` / `az_b` (string): Availability Zones.
- `public_subnet_*_cidr` (string): CIDR blocks for public subnets.
- `private_subnet_*_cidr` (string): CIDR blocks for private subnets.

## Outputs
- `vpc_id`
- `public_subnet_a_id`, `public_subnet_b_id`
- `private_subnet_a_id`, `private_subnet_b_id`
- `private_subnet_a_cidr_block`, `private_subnet_b_cidr_block`

Use this module from an environment entry point to feed subnet IDs to compute and security modules.
