output "api_url" {
  value = module.api_gateway.invoke_url
}

output "lambda_arn" {
  value = module.lambda.arn
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}
