output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  description = "First private subnet (used by Glue)"
  value       = aws_subnet.private[0].id
}

output "private_subnet_ids" {
  description = "All private subnet IDs (used by Lambda)"
  value       = aws_subnet.private[*].id
}

output "glue_security_group_id" {
  value = aws_security_group.glue.id
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}
