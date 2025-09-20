variable "project_name" {
  description = "Logical project name used for tagging."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_a" {
  description = "Primary Availability Zone."
  type        = string
}

variable "az_b" {
  description = "Secondary Availability Zone."
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR for public subnet A."
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR for public subnet B."
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR for private subnet A."
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR for private subnet B."
  type        = string
}
