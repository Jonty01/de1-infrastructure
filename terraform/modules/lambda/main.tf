##############################################################################
# modules/lambda/main.tf
# Creates Lambda functions — packages are pre-uploaded to S3 by de1-code-migration
##############################################################################

# ── IAM Role for Lambda ───────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda-s3-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.lambda_packages_bucket}",
          "arn:aws:s3:::${var.lambda_packages_bucket}/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-data-lake",
          "arn:aws:s3:::${var.project_name}-${var.environment}-data-lake/*"
        ]
      }
    ]
  })
}

# ── Lambda Functions ──────────────────────────────────────────────────────────
# Each function points to a zip package in S3 uploaded by de1-code-migration.

resource "aws_lambda_function" "example_function" {
  function_name = "${var.project_name}-${var.environment}-example-function"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  # Package uploaded by de1-code-migration CI/CD
  s3_bucket = var.lambda_packages_bucket
  s3_key    = "functions/example_function.zip"

  timeout     = 300
  memory_size = 256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-example-function"
  }
}

# ── To add more Lambda functions, copy the block above and change: ────────────
#   - resource label:   aws_lambda_function.your_function_name
#   - function_name:    "...-your-function-name"
#   - s3_key:           "functions/your_function.zip"
#   - handler:          "your_module.lambda_handler"
