data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_ses" {
  name = "${var.name}-sqs-ses"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.sqs_queue_arn
      },
      {
        Effect   = "Allow"
        Action   = "ses:SendEmail"
        Resource = "*"
      }
    ]
  })
}

resource "null_resource" "cargo_build" {
  triggers = {
    source_hash = sha256(join("", [for f in fileset(var.source_dir, "src/**/*.rs") : filesha256("${var.source_dir}/${f}")]))
    cargo_hash  = filesha256("${var.source_dir}/Cargo.toml")
  }

  provisioner "local-exec" {
    command     = "export PATH=$HOME/.cargo/bin:$HOME/Library/Python/3.9/lib/python/site-packages/ziglang:$PATH && cargo lambda build --release --arm64"
    working_dir = var.source_dir
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${var.source_dir}/target/lambda/lambda/bootstrap"
  output_path = "${path.module}/bootstrap.zip"

  depends_on = [null_resource.cargo_build]
}

resource "aws_lambda_function" "this" {
  function_name    = var.name
  filename         = data.archive_file.lambda.output_path
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda.arn
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = data.archive_file.lambda.output_base64sha256

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_vars) > 0 ? [1] : []
    content {
      variables = var.environment_vars
    }
  }

  tags = var.tags
}
