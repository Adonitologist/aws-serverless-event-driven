output "api_gateway_endpoint" {
  value       = module.api_eventbridge.api_endpoint
  description = "The HTTP API Gateway URL to send POST requests to"
}

output "dynamodb_table_name" {
  value       = module.compute_storage.dynamodb_table_name
  description = "The DynamoDB Global Table name"
}

output "dlq_url" {
  value       = module.messaging.sqs_main_queue_url
  description = "The SQS Queue URL"
}