# Infrastructure Setup

Before deploying this application, you need to provision the AWS infrastructure using the [serverless-ssr-module](https://github.com/apitanga/serverless-ssr-module).

## Quick Start

### 1. Create Infrastructure Directory

```bash
mkdir -p ~/my-app-infrastructure
cd ~/my-app-infrastructure
```

### 2. Create main.tf

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "ssr" {
  source = "github.com/apitanga/serverless-ssr-module"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name = "my-app"
  domain_name  = "example.com"
  subdomain    = "app"
  environment  = "prod"

  # Optional features
  enable_dr         = true
  create_ci_cd_user = true
}

output "app_config" {
  value = module.ssr.app_config
  sensitive = true
}

output "application_url" {
  value = module.ssr.application_url
}
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Export Outputs for App

```bash
terraform output -json app_config > ~/my-app/config/infra-outputs.json
```

### 5. Get CI/CD Credentials (if created)

```bash
terraform output cicd_aws_access_key_id
terraform output cicd_aws_secret_access_key  # sensitive
```

## Alternative: Using Examples

The module includes pre-built examples:

```bash
git clone https://github.com/apitanga/serverless-ssr-module.git
cd serverless-ssr-module/examples/basic
# Edit variables.tf or create terraform.tfvars
terraform init
terraform apply
```

## Required GitHub Secrets

Add these to your app repository (`serverless-ssr-app`):

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | From `cicd_aws_access_key_id` output |
| `AWS_SECRET_ACCESS_KEY` | From `cicd_aws_secret_access_key` output |
| `AWS_PRIMARY_REGION` | e.g., `us-east-1` |
| `INFRA_OUTPUTS_JSON` | Contents of `infra-outputs.json` |

## Infrastructure Resources Created

- **Lambda Functions**: Primary and DR regions with bootstrap code
- **CloudFront Distribution**: Global CDN with origin failover
- **S3 Buckets**: Static assets + Lambda deployment packages
- **DynamoDB**: Global table for data persistence
- **IAM Roles**: Execution role + optional CI/CD user

## Module Documentation

For full module documentation, see:
- [serverless-ssr-module README](https://github.com/apitanga/serverless-ssr-module#readme)
- [Basic Example](https://github.com/apitanga/serverless-ssr-module/tree/main/examples/basic)
- [Complete Example](https://github.com/apitanga/serverless-ssr-module/tree/main/examples/complete)

## Next Steps

See [Deployment Guide](deployment.md) for application deployment.
