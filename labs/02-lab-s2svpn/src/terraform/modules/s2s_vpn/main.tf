locals {
  name_prefix = upper("${var.project_name}-S2S")
}

resource "aws_customer_gateway" "this" {
  bgp_asn    = var.customer_gateway_bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-CGW"
  }
}

resource "aws_vpn_gateway" "this" {
  amazon_side_asn = var.amazon_side_asn

  tags = {
    Name = "${local.name_prefix}-VGW"
  }
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id        = var.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this.id
}

resource "aws_vpn_connection" "this" {
  vpn_gateway_id      = aws_vpn_gateway.this.id
  customer_gateway_id = aws_customer_gateway.this.id
  type                = "ipsec.1"
  static_routes_only  = true
  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_preshared_key = var.tunnel2_preshared_key

  tags = {
    Name = "${local.name_prefix}-VPN"
  }
}

resource "aws_vpn_connection_route" "this" {
  for_each           = toset(var.remote_ipv4_cidrs)
  vpn_connection_id  = aws_vpn_connection.this.id
  destination_cidr_block = each.value
}

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each       = toset(var.route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}
