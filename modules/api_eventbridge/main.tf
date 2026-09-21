# 1. Custom EventBridge Bus
resource "aws_cloudwatch_event_bus" "custom_bus" {
  name = "orders-event-bus-${var.environment}"
}

# 2. EventBridge Rule (Filters for 'OrderCreated' events)
resource "aws_cloudwatch_event_rule" "order_created_rule" {
  name           = "order-created-rule-${var.environment}"
  description    = "Capture Order Created events from API Gateway"
  event_bus_name = aws_cloudwatch_event_bus.custom_bus.name

  event_pattern = jsonencode({
    source        = ["api.orders"]
    "detail-type" = ["OrderCreated"]
  })
}

# 3. EventBridge Target (Routes matched events to the SNS Topic)
resource "aws_cloudwatch_event_target" "sns_target" {
  rule           = aws_cloudwatch_event_rule.order_created_rule.name
  event_bus_name = aws_cloudwatch_event_bus.custom_bus.name
  target_id      = "SendToSNS"
  arn            = var.sns_topic_arn
}

# 4. HTTP API Gateway v2
resource "aws_apigatewayv2_api" "events_api" {
  name          = "events-api-${var.environment}"
  protocol_type = "HTTP"
}

# 5. IAM Role for API Gateway to PutEvents into EventBridge
resource "aws_iam_role" "apigw_eventbridge_role" {
  name = "apigw-eventbridge-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "apigw_eventbridge_policy" {
  name = "apigw-eventbridge-policy-${var.environment}"
  role = aws_iam_role.apigw_eventbridge_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "events:PutEvents"
      Effect   = "Allow"
      Resource = aws_cloudwatch_event_bus.custom_bus.arn
    }]
  })
}

# 6. API Gateway Direct Integration to EventBridge
resource "aws_apigatewayv2_integration" "eventbridge_integration" {
  api_id              = aws_apigatewayv2_api.events_api.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "EventBridge-PutEvents"
  credentials_arn     = aws_iam_role.apigw_eventbridge_role.arn

  request_parameters = {
    "Source"       = "api.orders"
    "DetailType"   = "OrderCreated"
    "Detail"       = "$request.body"
    "EventBusName" = aws_cloudwatch_event_bus.custom_bus.name
  }
}

# 7. API Gateway Route
resource "aws_apigatewayv2_route" "post_event_route" {
  api_id    = aws_apigatewayv2_api.events_api.id
  route_key = var.api_route_key
  target    = "integrations/${aws_apigatewayv2_integration.eventbridge_integration.id}"
}

# 8. CloudWatch Log Group for API Gateway Access Logging
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/orders-api-${var.environment}"
  retention_in_days = 30
}

# 9. API Gateway Stage with Access Logging Enabled
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.events_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}