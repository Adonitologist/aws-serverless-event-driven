variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to route validated events to"
  type        = string
}

variable "api_route_key" {
  type = string
}