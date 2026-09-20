output "sns_topic_arn" {
  value       = aws_sns_topic.event_topic.arn
  description = "ARN of the encrypted SNS topic for event routing"
}

output "sqs_main_queue_arn" {
  value       = aws_sqs_queue.main_queue.arn
  description = "ARN of the encrypted main processing SQS queue"
}

output "sqs_main_queue_url" {
  value       = aws_sqs_queue.main_queue.id
  description = "URL of the main processing SQS queue"
}

output "kms_key_arn" {
  value       = aws_kms_key.messaging_key.arn
  description = "ARN of the KMS key used for messaging encryption"
}

output "kms_replica_key_arn" {
  value       = aws_kms_replica_key.messaging_replica.arn
  description = "ARN of the KMS replica key in the secondary region"
}