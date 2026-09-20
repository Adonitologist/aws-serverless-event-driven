# 1. DynamoDB Global Table (Active-Active Replication)
resource "aws_dynamodb_table" "global_orders" {
  name             = "OrdersTable-${var.environment}"
  billing_mode     = var.dynamodb_billing_mode
  hash_key         = "orderId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "orderId"
    type = "S"
  }

  replica {
    region_name = var.secondary_region
    kms_key_arn = var.replica_kms_key_arn
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
}

# 2. Package Lambda Source Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/src/lambda_processor/index.js"
  output_path = "${path.root}/src/lambda_processor/lambda.zip"
}

# 3. IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "event-processor-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 4. Attach standard AWS Managed Policies
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# 5. Least-Privilege Custom Policy
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "lambda-custom-policy-${var.environment}"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.global_orders.arn,
          "${aws_dynamodb_table.global_orders.arn}/*"
        ]
      }
    ]
  })
}

# 6. Lambda Function
resource "aws_lambda_function" "event_processor" {
  function_name    = "event-processor-${var.environment}"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.global_orders.name
    }
  }
}

# 7. SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.event_processor.arn
  batch_size       = 10
}
