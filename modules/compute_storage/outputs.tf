output "dynamodb_table_name" {
  value       = aws_dynamodb_table.global_orders.name
  description = "The name of the DynamoDB Global Table"
}

output "lambda_function_name" {
  value       = aws_lambda_function.event_processor.function_name
  description = "The name of the Lambda event processor"
}