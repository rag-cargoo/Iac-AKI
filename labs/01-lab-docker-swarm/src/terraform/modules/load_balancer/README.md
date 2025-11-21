# Load Balancer Module

Creates an internet-facing Application Load Balancer that fronts the Swarm manager's Jenkins service. The module:

- Provisions an ALB and security group exposed over HTTP/HTTPS.
- Registers all Swarm manager EC2 instances in an HTTP target group (default port 8080).
- Redirects HTTP → HTTPS using the provided ACM certificate.
- Optionally creates Route 53 alias records (e.g., `*.example.com`).
- Adds an ingress rule so the ALB can reach the Swarm security group on the Jenkins port.

## Inputs
- `project_name` – Tag prefix.
- `vpc_id` – Target VPC ID.
- `public_subnet_ids` – Subnets for the ALB.
- `certificate_arn` – ACM certificate for HTTPS.
- `manager_instance_ids` – List of manager EC2 IDs to attach.
- `manager_security_group_id` – Security group protecting the managers.
- `route53_zone_name` – Hosted zone to create aliases in.
- `route53_record_names` – FQDNs (e.g., `goopang.me`, `*.goopang.me`).
- `target_port` – Jenkins port (default 8080).
- `health_check_path` – Path for ALB health checks (default `/`).

## Outputs
- `alb_dns_name` – Public DNS name of the ALB.
- `alb_security_group_id` – Security group securing the ALB.
- `route53_record_fqdns` – Created Route 53 record names.
