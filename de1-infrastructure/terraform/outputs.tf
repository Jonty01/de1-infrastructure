output "environment" {
  description = "Deployed environment"
  value       = var.environment
}

output "glue_scripts_bucket" {
  description = "S3 bucket where Glue scripts are uploaded by de1-code-migration"
  value       = module.s3.glue_scripts_bucket_name
}

output "lambda_packages_bucket" {
  description = "S3 bucket where Lambda packages are uploaded by de1-code-migration"
  value       = module.s3.lambda_packages_bucket_name
}

output "glue_job_names" {
  description = "List of Glue job names created"
  value       = module.glue.glue_job_names
}

output "lambda_function_names" {
  description = "List of Lambda function names created"
  value       = module.lambda.lambda_function_names
}
