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
  for_each               = { for mgr in var.managers : mgr.name => mgr }
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_map[each.value.subnet_name]
  private_ip             = each.value.private_ip
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = upper("${var.project_name}-${upper(each.key)}")
  }
}

resource "aws_instance" "worker" {
  for_each               = { for wk in var.workers : wk.name => wk }
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_map[each.value.subnet_name]
  private_ip             = each.value.private_ip
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = upper("${var.project_name}-${upper(each.key)}")
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
