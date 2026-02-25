##############################################################################
# terraform/bootstrap/main.tf
#
# Run ONCE manually before anything else.
# Creates:
#   - S3 bucket for Terraform remote state (shared across dev/qa/prod)
#   - DynamoDB table for state locking
#   - GitHub OIDC provider
#   - IAM role for de1-infrastructure GitHub Actions (prod deploy)
#   - IAM role for de1-code-migration GitHub Actions (prod deploy)
#
# Usage:
#   cd de1-infrastructure/terraform/bootstrap
#   terraform init
#   terraform apply
#
# After apply, copy outputs into:
#   - terraform/main.tf           (bucket name)
#   - GitHub Secrets in both repos (role ARNs, region)
##############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # Bootstrap intentionally uses LOCAL state
}

provider "aws" {
  region = "us-east-1" # ← update if using a different region
}

# username added
locals {
  project_name = "de1"
  github_org   = "Jonty01" # ← replace with your GitHub username or org
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ── S3 Bucket for Terraform State ────────────────────────────────────────────

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.project_name}-terraform-state-${random_id.suffix.hex}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── DynamoDB Table for State Locking ─────────────────────────────────────────

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "${local.project_name}-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ── GitHub OIDC Provider ──────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# ── IAM Role: de1-infrastructure (Terraform apply on prod) ───────────────────

resource "aws_iam_role" "infra_deploy" {
  name = "${local.project_name}-infra-prod-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/de1-infrastructure:ref:refs/heads/prod"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "infra_deploy" {
  role       = aws_iam_role.infra_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# ── IAM Role: de1-code-migration (S3 sync on prod) ───────────────────────────

resource "aws_iam_role" "code_deploy" {
  name = "${local.project_name}-code-prod-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/de1-code-migration:ref:refs/heads/prod"
        }
      }
    }]
  })
}

# Code deploy only needs S3 write access (upload scripts/packages)
resource "aws_iam_role_policy" "code_deploy_s3" {
  name = "s3-sync-glue-lambda"
  role = aws_iam_role.code_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${local.project_name}-*-glue-scripts",
          "arn:aws:s3:::${local.project_name}-*-glue-scripts/*",
          "arn:aws:s3:::${local.project_name}-*-lambda-packages",
          "arn:aws:s3:::${local.project_name}-*-lambda-packages/*"
        ]
      }
    ]
  })
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Paste into de1-infrastructure/terraform/main.tf backend block"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_state_lock.name
  description = "Paste into de1-infrastructure/terraform/main.tf backend block"
}

output "infra_role_arn" {
  value       = aws_iam_role.infra_deploy.arn
  description = "Add as GitHub Secret AWS_ROLE_ARN in de1-infrastructure repo"
}

output "code_deploy_role_arn" {
  value       = aws_iam_role.code_deploy.arn
  description = "Add as GitHub Secret AWS_ROLE_ARN in de1-code-migration repo"
}
