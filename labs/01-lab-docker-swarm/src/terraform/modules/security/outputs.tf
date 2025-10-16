output "security_group_id" {
  description = "Security group ID applied to bastion and swarm nodes."
  value       = aws_security_group.swarm.id
}
