output "glue_job_names" {
  value = [
    aws_glue_job.example_etl.name,
    # add more job names here as you create them
  ]
}

output "glue_role_arn" {
  value = aws_iam_role.glue.arn
}
