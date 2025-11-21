output "alb_dns_name" {
  description = "Public DNS name of the Jenkins ALB."
  value       = aws_lb.jenkins.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID associated with the Jenkins ALB."
  value       = aws_security_group.alb.id
}

output "route53_record_fqdns" {
  description = "Fully-qualified domain names aliased to the ALB."
  value       = [for record in aws_route53_record.alias : record.fqdn]
}
