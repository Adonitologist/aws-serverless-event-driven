variable "primary_region" {
  description = "Primary AWS Region for event-driven infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS Region for Multi-Region Disaster Recovery replication"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "lambda_runtime" {
  description = "Runtime environment for the Lambda processor"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_memory_size" {
  description = "Allocated memory for the Lambda function in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 3
}

variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB tables"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "api_route_key" {
  description = "Route key for the API Gateway integration"
  type        = string
  default     = "POST /orders"
}