output "lambda_function_names" {
  value = [
    aws_lambda_function.example_function.function_name,
    # add more function names here as you create them
  ]
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}
