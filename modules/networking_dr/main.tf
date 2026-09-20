resource "aws_route53_health_check" "api_health" {
  # Regex replacement to extract pure FQDN from the API endpoint URL
  fqdn              = replace(replace(var.api_endpoint, "https://", ""), "/", "")
  port              = 443
  type              = "HTTPS"
  resource_path     = "/orders"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "api-gw-health-${var.environment}"
  }
}