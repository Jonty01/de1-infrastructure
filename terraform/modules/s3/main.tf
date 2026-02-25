##############################################################################
# modules/s3/main.tf
# Creates per-environment S3 buckets for:
#   - Glue scripts    (uploaded by de1-code-migration CI/CD)
#   - Lambda packages (uploaded by de1-code-migration CI/CD)
##############################################################################

resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.project_name}-${var.environment}-glue-scripts"
}

resource "aws_s3_bucket_versioning" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket                  = aws_s3_bucket.glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Lambda Packages Bucket ────────────────────────────────────────────────────

resource "aws_s3_bucket" "lambda_packages" {
  bucket = "${var.project_name}-${var.environment}-lambda-packages"
}

resource "aws_s3_bucket_versioning" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_packages" {
  bucket                  = aws_s3_bucket.lambda_packages.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Data Lake Bucket (raw / processed / curated zones) ───────────────────────

resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-${var.environment}-data-lake"
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Pre-create the zone prefixes (folders) inside the data lake
resource "aws_s3_object" "data_lake_zones" {
  for_each = toset(["raw/", "processed/", "curated/"])
  bucket   = aws_s3_bucket.data_lake.id
  key      = each.value
  content  = ""
}
