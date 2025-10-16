variable "aws_region" {
  description = "배포할 AWS 리전"
  type        = string
}

variable "project_name" {
  description = "태깅에 사용할 프로젝트 접두사"
  type        = string
}

variable "vpc_id" {
  description = "VPN을 연결할 기존 VPC ID"
  type        = string
}

variable "customer_gateway_ip" {
  description = "온프레미스 게이트웨이의 고정 공인 IP"
  type        = string
}

variable "customer_gateway_bgp_asn" {
  description = "온프레미스 게이트웨이의 BGP ASN"
  type        = number
  default     = 65000
}

variable "amazon_side_asn" {
  description = "AWS VPN Gateway의 BGP ASN"
  type        = number
  default     = 64512
}

variable "remote_ipv4_cidrs" {
  description = "온프레미스 측 프라이빗 네트워크 CIDR 목록"
  type        = list(string)
}

variable "route_table_ids" {
  description = "VPN 경로 전파를 적용할 VPC 라우트 테이블 ID 목록"
  type        = list(string)
  default     = []
}

variable "tunnel1_preshared_key" {
  description = "터널 1 사전 공유 키 (옵션)"
  type        = string
  default     = null
}

variable "tunnel2_preshared_key" {
  description = "터널 2 사전 공유 키 (옵션)"
  type        = string
  default     = null
}
