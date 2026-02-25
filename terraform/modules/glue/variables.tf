variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "glue_scripts_bucket" {
  description = "S3 bucket name where Glue scripts are stored"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for Glue network connection"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Glue jobs"
  type        = string
}

variable "glue_worker_type" {
  description = "Glue worker type (G.1X, G.2X, G.025X for small jobs)"
  type        = string
  default     = "G.1X"
}

variable "glue_num_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}
