resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "sqs" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_subtype    = "SQS-SendMessage"
  credentials_arn        = aws_iam_role.apigw_sqs.arn
  payload_format_version = "1.0"

  request_parameters = {
    QueueUrl    = var.sqs_queue_url
    MessageBody = "$request.body"
  }
}

resource "aws_apigatewayv2_route" "post_events" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.sqs.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags

  default_route_settings {
    throttling_rate_limit  = var.rate_limit
    throttling_burst_limit = var.burst_limit
  }
}

# IAM role para que API Gateway pueda enviar a SQS
data "aws_iam_policy_document" "apigw_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_sqs" {
  name               = "${var.name}-apigw-sqs-role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "apigw_sqs" {
  name = "${var.name}-apigw-sqs-policy"
  role = aws_iam_role.apigw_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = var.sqs_queue_arn
    }]
  })
}
