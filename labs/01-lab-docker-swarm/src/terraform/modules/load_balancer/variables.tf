variable "project_name" {
  description = "Logical project name for tagging resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and target group will be created."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}

variable "target_port" {
  description = "Port exposed on the Swarm manager for Jenkins HTTP traffic."
  type        = number
  default     = 8080
}

variable "manager_instance_ids" {
  description = "Instance IDs for Swarm managers to register in the target group."
  type        = list(string)
}

variable "manager_security_group_id" {
  description = "Security group ID applied to Swarm manager instances."
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com)."
  type        = string
}

variable "route53_record_names" {
  description = "Fully-qualified DNS names to alias to the ALB."
  type        = list(string)
  default     = []
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks."
  type        = string
  default     = "/"
}
