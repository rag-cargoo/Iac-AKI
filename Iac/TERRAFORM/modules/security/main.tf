resource "aws_security_group" "swarm" {
  name        = upper("${var.project_name}-WEB-SG")
  description = "Allow HTTP and SSH traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.operator_cidr]
  }

  ingress {
    description = "Allow SSH from within this security group"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Grafana from within this security group"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Prometheus from within this security group"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Node Exporter from within this security group"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Docker Swarm management (2377/TCP)"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Docker Swarm node communication (7946/TCP)"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Docker Swarm node communication (7946/UDP)"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Allow Docker Swarm overlay network (4789/UDP)"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = upper("${var.project_name}-WEB-SG")
  }
}
