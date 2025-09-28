variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "project_name" {
  description = "Logical project name for tagging."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_a" {
  description = "Primary Availability Zone identifier."
  type        = string
}

variable "az_b" {
  description = "Secondary Availability Zone identifier."
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A."
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B."
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A."
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion, manager, and workers."
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to use."
  type        = string
}

variable "ssh_key_file_path" {
  description = "Absolute path to the SSH private key file."
  type        = string
}

variable "my_ip" {
  description = "Operator CIDR allowed for SSH access (e.g., 1.2.3.4/32)."
  type        = string
}

variable "managers" {
  description = "Swarm manager instances to create."
  type = list(object({
    name        = string
    private_ip  = string
    subnet_name = string
  }))
}

variable "workers" {
  description = "Swarm worker instances to create."
  type = list(object({
    name        = string
    private_ip  = string
    subnet_name = string
  }))
}
