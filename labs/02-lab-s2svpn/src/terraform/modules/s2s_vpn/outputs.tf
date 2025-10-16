output "customer_gateway_id" {
  value       = aws_customer_gateway.this.id
  description = "Customer Gateway ID"
}

output "vpn_gateway_id" {
  value       = aws_vpn_gateway.this.id
  description = "Virtual Private Gateway ID"
}

output "vpn_connection_id" {
  value       = aws_vpn_connection.this.id
  description = "VPN Connection ID"
}

output "tunnel1_outside_address" {
  value       = aws_vpn_connection.this.tunnel1_address
  description = "AWS 측 터널 1 외부 IP"
}

output "tunnel2_outside_address" {
  value       = aws_vpn_connection.this.tunnel2_address
  description = "AWS 측 터널 2 외부 IP"
}
