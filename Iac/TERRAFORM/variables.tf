variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "az_a" {
  description = "Availability Zone A"
  type        = string
}

variable "az_b" {
  description = "Availability Zone B"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "The CIDR block for public subnet A."
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "The CIDR block for public subnet B."
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "The CIDR block for private subnet A."
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "The CIDR block for private subnet B."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to launch."
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the EC2 key pair to use."
  type        = string
}

variable "ssh_key_file_path" {
  description = "The absolute path to the SSH private key file."
  type        = string
}

variable "my_ip" {
  description = "Your public IP address to allow SSH access."
  type        = string
}

variable "manager_ip" {
  description = "Fixed private IP for manager instance."
  type        = string
}

variable "worker_nodes" {
  description = "Map of worker node names to their fixed private IP addresses and subnet CIDR."
  type = map(object({
    ip = string,
    subnet_cidr = string
  }))
}