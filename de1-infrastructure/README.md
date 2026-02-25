# de1-infrastructure

Terraform infrastructure for the DE1 data engineering project.

## Branch Flow

```
feature/* → dev → qa → prod
```

Always branch off `dev`. On merge to `prod`, GitHub Actions runs `terraform apply` after manual approval.

## Folder Structure

```
de1-infrastructure/
├── terraform/
│   ├── main.tf                        # Root: provider, backend, module calls
│   ├── variables.tf                   # Shared variables
│   ├── outputs.tf                     # Shared outputs
│   ├── bootstrap/
│   │   └── main.tf                    # Run ONCE to create S3 + DynamoDB + IAM roles
│   ├── environments/
│   │   ├── dev/  {backend.hcl, terraform.tfvars}
│   │   ├── qa/   {backend.hcl, terraform.tfvars}
│   │   └── prod/ {backend.hcl, terraform.tfvars}
│   └── modules/
│       ├── s3/          # Glue scripts, Lambda packages, data lake buckets
│       ├── glue/        # AWS Glue jobs
│       ├── lambda/      # Lambda functions
│       └── networking/  # VPC, subnets, security groups
└── .github/workflows/
    ├── terraform-validate.yml   # PRs → plan as PR comment
    └── terraform-deploy.yml     # Prod merge → approval → apply
```

## First-Time Setup

See full instructions in the project wiki or follow these steps:

```powershell
# 1. Edit bootstrap/main.tf — set your GitHub username
# 2. Run bootstrap
cd terraform\bootstrap
terraform init
terraform apply

# 3. Copy outputs into terraform\main.tf (bucket name)
# 4. Add GitHub Secrets to BOTH repos:
#    de1-infrastructure: AWS_ROLE_ARN = infra_role_arn
#    de1-code-migration: AWS_ROLE_ARN = code_deploy_role_arn
#    Both repos:         AWS_REGION, PROJECT_NAME
# 5. Create GitHub Environment "production" with required reviewers in both repos
```

## State Layout (Single S3 Bucket)

```
s3://de1-terraform-state-xxxx/
├── dev/terraform.tfstate
├── qa/terraform.tfstate
└── prod/terraform.tfstate
```

## Adding New Infrastructure

- **New Glue job** → add resource block in `modules/glue/main.tf`
- **New Lambda** → add resource block in `modules/lambda/main.tf`
- **New S3 bucket** → add resource block in `modules/s3/main.tf`

Always deploy `de1-code-migration` to prod first, then `de1-infrastructure`.
