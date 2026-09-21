terraform {
  required_providers {
    aws = {
      source             = "hashicorp/aws"
      configuration_aliases = [aws.secondary]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Enterprise KMS Key (Multi-Region Primary)
resource "aws_kms_key" "messaging_key" {
  description             = "KMS CMK for SNS, SQS, and CloudWatch Logs encryption in ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  multi_region            = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Services to generate and decrypt data keys"
        Effect = "Allow"
        Principal = {
          Service = [
            "sns.amazonaws.com",
            "sqs.amazonaws.com",
            "events.amazonaws.com"
          ]
        }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsToUseTheKey"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/orders-api-test"
          }
        }
      }
    ]
  })
}

# KMS Replica Key for Secondary Region
resource "aws_kms_replica_key" "messaging_replica" {
  provider                = aws.secondary
  description             = "Multi-Region KMS replica for ${var.environment}"
  deletion_window_in_days = 7
  primary_key_arn         = aws_kms_key.messaging_key.arn
}

resource "aws_kms_alias" "messaging_key_alias" {
  name          = "alias/messaging-key-${var.environment}"
  target_key_id = aws_kms_key.messaging_key.key_id
}

# Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "dlq" {
  name                              = "event-processing-dlq-${var.environment}"
  kms_master_key_id                 = aws_kms_key.messaging_key.arn
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600
}

# Main SQS Queue
resource "aws_sqs_queue" "main_queue" {
  name                              = "event-processing-queue-${var.environment}"
  kms_master_key_id                 = aws_kms_key.messaging_key.arn
  kms_data_key_reuse_period_seconds = 300
  visibility_timeout_seconds        = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# SNS Topic
resource "aws_sns_topic" "event_topic" {
  name              = "event-routing-topic-${var.environment}"
  kms_master_key_id = aws_kms_key.messaging_key.arn
}

# SNS Subscription to SQS
resource "aws_sns_topic_subscription" "queue_subscription" {
  topic_arn = aws_sns_topic.event_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main_queue.arn
}

# --- CRITICAL RESOURCE POLICIES ---

# 1. Allow EventBridge to publish securely to SNS (Confused Deputy Protected)
resource "aws_sns_topic_policy" "eventbridge_sns_policy" {
  arn = aws_sns_topic.event_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.event_topic.arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}

# 2. Allow SNS to publish securely to SQS
resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.event_topic.arn }
        }
      }
    ]
  })
}