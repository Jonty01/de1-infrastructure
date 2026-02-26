# Very tough job

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Populated after bootstrap — replace these values with bootstrap outputs
    bucket         = "de1-terraform-state-8c0a954b" # ← from bootstrap output
    dynamodb_table = "de1-terraform-state-lock"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "de1-infrastructure"
    }
  }
}

# ── S3 Buckets (Glue scripts + Lambda packages per env) ─────────────────────

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

# ── Networking (VPC, Subnets, Security Groups) ───────────────────────────────

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

# ── Glue Jobs ────────────────────────────────────────────────────────────────

module "glue" {
  source              = "./modules/glue"
  project_name        = var.project_name
  environment         = var.environment
  glue_scripts_bucket = module.s3.glue_scripts_bucket_name
  subnet_id           = module.networking.private_subnet_id
  security_group_id   = module.networking.glue_security_group_id
}

# ── Lambda Functions ─────────────────────────────────────────────────────────

module "lambda" {
  source                 = "./modules/lambda"
  project_name           = var.project_name
  environment            = var.environment
  lambda_packages_bucket = module.s3.lambda_packages_bucket_name
  subnet_ids             = module.networking.private_subnet_ids
  security_group_id      = module.networking.lambda_security_group_id
}
