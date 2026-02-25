output "glue_scripts_bucket_name" {
  value       = aws_s3_bucket.glue_scripts.bucket
  description = "Bucket where de1-code-migration uploads Glue scripts"
}

output "glue_scripts_bucket_arn" {
  value = aws_s3_bucket.glue_scripts.arn
}

output "lambda_packages_bucket_name" {
  value       = aws_s3_bucket.lambda_packages.bucket
  description = "Bucket where de1-code-migration uploads Lambda packages"
}

output "lambda_packages_bucket_arn" {
  value = aws_s3_bucket.lambda_packages.arn
}

output "data_lake_bucket_name" {
  value       = aws_s3_bucket.data_lake.bucket
  description = "Data lake bucket with raw/processed/curated zones"
}

output "data_lake_bucket_arn" {
  value = aws_s3_bucket.data_lake.arn
}
