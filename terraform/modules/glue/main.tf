##############################################################################
# modules/glue/main.tf
# Creates AWS Glue jobs — scripts are pre-uploaded to S3 by de1-code-migration
##############################################################################

# ── IAM Role for Glue ─────────────────────────────────────────────────────────

resource "aws_iam_role" "glue" {
  name = "${var.project_name}-${var.environment}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue-s3-access"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.glue_scripts_bucket}",
          "arn:aws:s3:::${var.glue_scripts_bucket}/*",
          # Also allow read/write to the data lake
          "arn:aws:s3:::${var.project_name}-${var.environment}-data-lake",
          "arn:aws:s3:::${var.project_name}-${var.environment}-data-lake/*"
        ]
      }
    ]
  })
}

# ── Glue Jobs ─────────────────────────────────────────────────────────────────
# Add one block per ETL job. Each job points to its script in S3.
# The script must already exist in S3 (uploaded by de1-code-migration pipeline).

resource "aws_glue_job" "example_etl" {
  name         = "${var.project_name}-${var.environment}-example-etl"
  role_arn     = aws_iam_role.glue.arn
  glue_version = "4.0"
  worker_type  = var.glue_worker_type
  number_of_workers = var.glue_num_workers

  command {
    name            = "glueetl"
    script_location = "s3://${var.glue_scripts_bucket}/jobs/example_etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-job-insights"              = "true"
    "--TempDir"                          = "s3://${var.glue_scripts_bucket}/tmp/"
    "--environment"                      = var.environment
  }

  connections = []

  tags = {
    Name = "${var.project_name}-${var.environment}-example-etl"
  }
}

# ── To add more Glue jobs, copy the block above and change: ──────────────────
#   - resource label:    aws_glue_job.your_job_name
#   - name:              "...-your-job-name"
#   - script_location:   s3://.../jobs/your_script.py
