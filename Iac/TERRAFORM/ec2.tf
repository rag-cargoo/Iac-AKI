data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

locals {
  worker_subnet_ids_map = {
    for worker_name, worker_details in var.worker_nodes : worker_details.ip => (
      worker_details.subnet_cidr == var.private_subnet_a_cidr ? aws_subnet.private_a.id : aws_subnet.private_b.id
    )
  }
}

# Public Instance (Bastion)
resource "aws_instance" "public_bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-BASTION-HOST")
  }
}

# Manager Instance
resource "aws_instance" "manager" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  private_ip    = var.manager_ip
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-MANAGER-SERVER")
  }
}

# Worker Instances
resource "aws_instance" "worker" {
  for_each      = var.worker_nodes
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = local.worker_subnet_ids_map[each.value.ip]
  private_ip    = each.value.ip
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-${upper(each.key)}")
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = upper("${var.project_name}-BASTION-EIP")
  }
}

# Associate Elastic IP with Bastion Host
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.public_bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

# --- Outputs ---

# Output for the Bastion Host's Public IP
output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "manager_private_ip" {
  description = "Private IP address of the Swarm Manager"
  value       = aws_instance.manager.private_ip
}

output "worker_private_ips" {
  description = "List of private IP addresses of the Swarm Workers"
  value       = [for worker in aws_instance.worker : worker.private_ip]
}

output "ssh_key_file_path" {
  description = "The absolute path to the SSH private key file."
  value       = var.ssh_key_file_path
}

output "private_subnet_a_id" {
  description = "ID of private subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_a_cidr_block" {
  description = "CIDR block of private subnet A"
  value       = aws_subnet.private_a.cidr_block
}

output "private_subnet_b_id" {
  description = "ID of private subnet B"
  value       = aws_subnet.private_b.id
}

output "private_subnet_b_cidr_block" {
  description = "CIDR block of private subnet B"
  value       = aws_subnet.private_b.cidr_block
}