variable "environment" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "api_route_key" {
  type = string
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN for CloudWatch Log Group encryption"
}