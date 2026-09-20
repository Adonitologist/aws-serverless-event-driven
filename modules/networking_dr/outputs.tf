output "health_check_id" {
  value       = aws_route53_health_check.api_health.id
  description = "ID of the Route 53 Health Check"
}