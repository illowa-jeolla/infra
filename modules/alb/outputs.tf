output "arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the API target group."
  value       = aws_lb_target_group.api.arn

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https,
  ]
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener when a certificate is configured."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "url" {
  description = "Direct ALB URL. A custom HTTPS domain replaces this for production use."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.this.dns_name}"
}
