variable "project_name" {
  description = "Logical project name used for tagging."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type applied to all nodes."
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to attach to instances."
  type        = string
}

variable "ssh_key_file_path" {
  description = "Local path to the SSH private key associated with the key pair."
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet ID used for the public bastion host."
  type        = string
}

variable "private_subnet_map" {
  description = "Mapping of subnet aliases to subnet IDs."
  type        = map(string)
}

variable "security_group_id" {
  description = "Security group applied to all instances."
  type        = string
}

variable "managers" {
  description = "Swarm managers to create."
  type = list(object({
    name        = string
    private_ip  = string
    subnet_name = string
  }))
}

variable "workers" {
  description = "Swarm workers to create."
  type = list(object({
    name        = string
    private_ip  = string
    subnet_name = string
  }))
}
