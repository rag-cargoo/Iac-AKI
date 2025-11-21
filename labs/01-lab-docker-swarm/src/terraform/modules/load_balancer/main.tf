locals {
  alb_name          = upper("${var.project_name}-jenkins-alb")
  tg_name           = upper("${var.project_name}-jenkins-tg")
  alb_security_name = upper("${var.project_name}-jenkins-alb-sg")
  record_map        = { for name in var.route53_record_names : name => name }
}

resource "aws_security_group" "alb" {
  name        = local.alb_security_name
  description = "Allow HTTPS traffic to Jenkins ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.alb_security_name
  }
}

resource "aws_security_group_rule" "allow_jenkins_from_alb" {
  description              = "Allow ALB to reach Jenkins on managers"
  type                     = "ingress"
  from_port                = var.target_port
  to_port                  = var.target_port
  protocol                 = "tcp"
  security_group_id        = var.manager_security_group_id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "jenkins" {
  name               = replace(local.alb_name, "_", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = 60

  tags = {
    Name = local.alb_name
  }
}

resource "aws_lb_target_group" "jenkins" {
  name     = replace(local.tg_name, "_", "-")
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "managers" {
  for_each         = { for idx, id in var.manager_instance_ids : idx => id }
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = each.value
  port             = var.target_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

data "aws_route53_zone" "selected" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "alias" {
  for_each = local.record_map

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.jenkins.dns_name
    zone_id                = aws_lb.jenkins.zone_id
    evaluate_target_health = true
  }
}
