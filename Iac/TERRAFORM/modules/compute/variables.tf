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

variable "private_subnet_a_id" {
  description = "Subnet ID for the primary private subnet."
  type        = string
}

variable "private_subnet_b_id" {
  description = "Subnet ID for the secondary private subnet."
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for the primary private subnet."
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for the secondary private subnet."
  type        = string
}

variable "security_group_id" {
  description = "Security group applied to all instances."
  type        = string
}

variable "manager_ip" {
  description = "Fixed private IP for the Swarm manager."
  type        = string
}

variable "worker_nodes" {
  description = "Map of worker node definitions keyed by name."
  type = map(object({
    ip          = string,
    subnet_cidr = string
  }))

  validation {
    condition = alltrue([
      for worker in values(var.worker_nodes) :
      can(regex("\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+", worker.subnet_cidr))
    ])
    error_message = "Each worker must specify subnet_cidr in CIDR notation."
  }
}
