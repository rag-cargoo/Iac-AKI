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

  owners = ["099720109477"]
}

locals {
  worker_subnet_assignment = {
    (var.private_subnet_a_cidr) = var.private_subnet_a_id,
    (var.private_subnet_b_cidr) = var.private_subnet_b_id
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = upper("${var.project_name}-BASTION-HOST")
  }
}

resource "aws_instance" "manager" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_a_id
  private_ip             = var.manager_ip
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = upper("${var.project_name}-MANAGER-SERVER")
  }
}

resource "aws_instance" "worker" {
  for_each               = var.worker_nodes
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = lookup(local.worker_subnet_assignment, each.value.subnet_cidr, null)
  private_ip             = each.value.ip
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = upper("${var.project_name}-${upper(each.key)}")
  }

  lifecycle {
    precondition {
      condition     = lookup(local.worker_subnet_assignment, each.value.subnet_cidr, null) != null
      error_message = "Worker \"${each.key}\" references unsupported subnet CIDR ${each.value.subnet_cidr}."
    }
  }
}

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = upper("${var.project_name}-BASTION-EIP")
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}
