variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue that triggers the Lambda function"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for decrypting SQS and encrypting DynamoDB"
  type        = string
}

variable "secondary_region" {
  description = "Region for DynamoDB Global Table replication"
  type        = string
}