resource "aws_sqs_queue" "this" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = 86400
  tags                       = var.tags
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = aws_sqs_queue.this.arn
  function_name                      = var.lambda_arn
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.batching_window
  scaling_config {
    maximum_concurrency = var.max_concurrency
  }
}
