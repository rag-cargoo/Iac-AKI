output "vpc_id" {
  description = "Identifier of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "ID of public subnet A."
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of public subnet B."
  value       = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "ID of private subnet A."
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID of private subnet B."
  value       = aws_subnet.private_b.id
}

output "private_subnet_a_cidr_block" {
  description = "CIDR block of private subnet A."
  value       = aws_subnet.private_a.cidr_block
}

output "private_subnet_b_cidr_block" {
  description = "CIDR block of private subnet B."
  value       = aws_subnet.private_b.cidr_block
}
