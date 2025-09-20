output "bastion_public_ip" {
  description = "Public IP address of the bastion host."
  value       = module.compute.bastion_public_ip
}

output "manager_private_ip" {
  description = "Private IP address of the Swarm manager."
  value       = module.compute.manager_private_ip
}

output "worker_private_ips" {
  description = "Private IP addresses for Swarm workers."
  value       = module.compute.worker_private_ips
}

output "ssh_key_file_path" {
  description = "Path to the SSH private key for provisioning."
  value       = module.compute.ssh_key_file_path
}

output "private_subnet_a_id" {
  description = "ID of private subnet A."
  value       = module.network.private_subnet_a_id
}

output "private_subnet_a_cidr_block" {
  description = "CIDR block of private subnet A."
  value       = module.network.private_subnet_a_cidr_block
}

output "private_subnet_b_id" {
  description = "ID of private subnet B."
  value       = module.network.private_subnet_b_id
}

output "private_subnet_b_cidr_block" {
  description = "CIDR block of private subnet B."
  value       = module.network.private_subnet_b_cidr_block
}
