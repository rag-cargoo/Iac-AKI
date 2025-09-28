variable "project_name" {
  description = "Logical name used for tagging security resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier to attach the security group to."
  type        = string
}

variable "operator_cidr" {
  description = "CIDR block allowed to SSH into the bastion host."
  type        = string
}
