variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_packages_bucket" {
  description = "S3 bucket name where Lambda zip packages are stored"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for Lambda VPC config"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
}
