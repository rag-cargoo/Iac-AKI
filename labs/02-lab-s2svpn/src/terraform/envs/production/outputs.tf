output "customer_gateway_id" {
  description = "Customer Gateway ID"
  value       = module.s2s_vpn.customer_gateway_id
}

output "vpn_gateway_id" {
  description = "Virtual Private Gateway ID"
  value       = module.s2s_vpn.vpn_gateway_id
}

output "vpn_connection_id" {
  description = "VPN Connection ID"
  value       = module.s2s_vpn.vpn_connection_id
}

output "tunnel1_outside_address" {
  description = "AWS 측 터널 1 외부 IP"
  value       = module.s2s_vpn.tunnel1_outside_address
}

output "tunnel2_outside_address" {
  description = "AWS 측 터널 2 외부 IP"
  value       = module.s2s_vpn.tunnel2_outside_address
}
