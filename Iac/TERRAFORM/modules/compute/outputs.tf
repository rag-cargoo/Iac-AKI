output "bastion_public_ip" {
  description = "Public IP address assigned to the bastion host."
  value       = aws_eip.bastion.public_ip
}

output "manager_private_ip" {
  description = "Private IP address of the Swarm manager."
  value       = aws_instance.manager.private_ip
}

output "worker_private_ips" {
  description = "Private IP addresses for Swarm workers."
  value       = [for worker in aws_instance.worker : worker.private_ip]
}

output "ssh_key_file_path" {
  description = "Absolute path to the SSH private key."
  value       = var.ssh_key_file_path
}
