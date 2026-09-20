output "api_endpoint" {
  value       = aws_apigatewayv2_api.events_api.api_endpoint
  description = "The public endpoint URL of the HTTP API Gateway"
}

output "event_bus_arn" {
  value       = aws_cloudwatch_event_bus.custom_bus.arn
  description = "ARN of the custom EventBridge bus"
}