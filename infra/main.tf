# Pomo SSR Demo Site Infrastructure
# Demo site at ssr.pomo.dev
# Terraform Cloud Workspace: pomossr

module "ssr" {
  source = "github.com/apitanga/serverless-ssr-module?ref=v2.0.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name    = "pomo-ssr"
  domain_name     = "pomo.dev"
  subdomain       = "ssr" # Creates ssr.pomo.dev
  route53_managed = true  # Zone exists in pomo repo

  # Disable CICD user - we use GitHub Actions OIDC instead
  create_ci_cd_user = false

  tags = {
    Project   = "pomo-ssr"
    Purpose   = "demo"
    ManagedBy = "terraform"
  }
}
