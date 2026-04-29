terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    terraform = "true"
    project   = var.project_name
  }
}

module "lambda" {
  source        = "./modules/lambda"
  name          = var.project_name
  source_dir    = "${path.root}/../lambda"
  sqs_queue_arn = module.sqs.queue_arn
  timeout       = 30
  memory_size   = 128

  reserved_concurrent_executions = 10

  environment_vars = {
    SES_FROM_EMAIL = var.ses_from_email
    SES_TO_EMAIL   = var.ses_to_email
  }

  tags = local.tags
}

module "sqs" {
  source          = "./modules/sqs"
  name            = "${var.project_name}-queue"
  lambda_arn      = module.lambda.arn
  batch_size      = 10
  max_concurrency = 10
  tags            = local.tags
}

module "api_gateway" {
  source        = "./modules/api-gateway"
  name          = var.project_name
  sqs_queue_arn = module.sqs.queue_arn
  sqs_queue_url = module.sqs.queue_url
  rate_limit    = 15
  tags          = local.tags
}
