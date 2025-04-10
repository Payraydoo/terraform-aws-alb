output "id" {
  description = "The ALB ID"
  value       = aws_lb.this.id
}

output "arn" {
  description = "The ALB ARN"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "List of target group ARNs"
  value       = aws_lb_target_group.this[*].arn
}

output "target_group_names" {
  description = "List of target group names"
  value       = aws_lb_target_group.this[*].name
}

output "http_tcp_listener_arns" {
  description = "List of HTTP/TCP listener ARNs"
  value       = aws_lb_listener.http_tcp[*].arn
}

output "https_listener_arns" {
  description = "List of HTTPS listener ARNs"
  value       = aws_lb_listener.https[*].arn
}

output "security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.this.id
}