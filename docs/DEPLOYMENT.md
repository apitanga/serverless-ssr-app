# Deployment Workflow

This document explains the deployment workflow for pomo-ssr using Terraform Cloud and GitHub integration.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│                     apitanga/pomo-ssr                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
        infra/** changes          app/** changes
              │                         │
              ▼                         ▼
    ┌──────────────────┐      ┌──────────────────┐
    │ Terraform Cloud  │      │ GitHub Actions   │
    │ Workspace:       │      │ deploy.yml       │
    │ pomossr          │      │                  │
    │                  │      │ Uses OIDC to     │
    │ Creates:         │      │ authenticate     │
    │ - Lambda         │      │ to AWS           │
    │ - CloudFront     │      │                  │
    │ - S3 buckets     │      │ Deploys app code │
    │ - DynamoDB       │      │ to Lambda        │
    │ - DNS (ssr...)   │      │                  │
    └──────────────────┘      └──────────────────┘
```

---

## How It Works

### Infrastructure Changes (infra/**)

**Trigger**: Push to `main` with changes to `infra/**/*.tf` or `infra/**/*.tfvars`

**Workflow**:
1. GitHub detects push via VCS integration
2. TFC workspace `pomossr` automatically runs `terraform plan`
3. Plan appears in TFC UI for review
4. **Manual approval required** - Review plan and click "Confirm & Apply"
5. TFC applies infrastructure changes
6. Resources updated in AWS

**Key Setting**: `working_directory = "infra"` in TFC workspace

### Application Changes (app/**)

**Trigger**: Push to `main` with changes to `app/**` or `scripts/**`

**Workflow**:
1. GitHub Actions workflow `deploy.yml` triggers
2. Workflow uses OIDC to authenticate to AWS (no static credentials!)
3. Builds Nuxt application for Lambda
4. Uploads code to S3 deployment buckets
5. Updates Lambda function code (primary + DR)
6. Syncs static assets to S3
7. Invalidates CloudFront cache
8. Application deployed!

**Authentication**: Uses `github-actions-pomo-ssr` IAM role via OIDC

---

## Day-to-Day Workflow

### Infrastructure Changes

```bash
# 1. Edit Terraform files
cd ~/code/pomo-ssr
vim infra/main.tf

# 2. Commit and push
git add infra/
git commit -m "Update Lambda memory"
git push origin main

# 3. TFC automatically runs plan
# 4. Review plan in TFC UI: https://app.terraform.io/app/Pitangaville/pomossr
# 5. Approve and apply
# 6. Infrastructure updated!
```

### Application Changes

```bash
# 1. Edit app code
cd ~/code/pomo-ssr
vim app/pages/index.vue

# 2. Test locally (optional)
cd app && npm run dev

# 3. Deploy manually
cd ~/code/pomo-ssr
./scripts/deploy.sh

# OR: Commit and push (GitHub Actions auto-deploys)
git add app/
git commit -m "Update homepage"
git push origin main  # GitHub Actions handles deploy
```

---

## TFC Configuration

### Workspace: `pomossr`

**Settings**:
- Organization: `Pitangaville`
- Working Directory: `infra/`
- Trigger Patterns: `["infra/**/*.tf", "infra/**/*.tfvars"]`
- Auto-apply: `false` (requires manual approval)
- VCS: `apitanga/pomo-ssr` (GitHub App)
- Branch: `main`

**Authentication**: OIDC dynamic credentials (no static AWS keys!)
- Environment variables set via variable sets (managed by pomo repo)
- `TFC_AWS_PROVIDER_AUTH=true`
- `TFC_AWS_RUN_ROLE_ARN=arn:aws:iam::137064409667:role/terraform-cloud-pomossr`

---

## GitHub Actions Configuration

### Secrets (Repository Settings)

| Secret | Value | Purpose |
|--------|-------|---------|
| `AWS_ROLE_ARN` | `arn:aws:iam::137064409667:role/github-actions-pomo-ssr` | OIDC role for deployment |
| `TF_API_TOKEN` | Terraform Cloud API token | Sync workflow (reads TF outputs) |
| `GH_PAT` | GitHub Personal Access Token | Sync workflow (updates variables) |

### Variables (Repository Settings)

| Variable | Value | Purpose |
|----------|-------|---------|
| `INFRA_OUTPUTS_JSON` | Auto-updated JSON | Infrastructure config for deployment |

**Note**: `INFRA_OUTPUTS_JSON` is automatically synced by the `sync-infra-config.yml` workflow after infrastructure changes.

---

## Deployment Checklist

### First-Time Setup

- [x] pomo repo deployed (creates DNS, certs, OIDC provider)
- [x] TFC workspace `pomossr` created (managed by pomo repo)
- [x] GitHub secrets configured (AWS_ROLE_ARN, TF_API_TOKEN, GH_PAT)
- [x] VCS integration connected (GitHub App)

### Infrastructure Deployment

1. Push infra changes to `main`
2. Wait for TFC plan to generate
3. Review plan in TFC UI
4. Approve and apply
5. Wait for apply to complete
6. Sync workflow automatically updates `INFRA_OUTPUTS_JSON`

### Application Deployment

1. Push app changes to `main` (or run `./scripts/deploy.sh` locally)
2. GitHub Actions workflow runs (or local script)
3. Application builds and deploys
4. Verify at https://ssr.pomo.dev

---

## Troubleshooting

### TFC plan fails

**Check**:
- AWS credentials: OIDC role has correct permissions?
- Terraform syntax: Run `terraform validate` locally
- State lock: Another run already in progress?

### GitHub Actions deployment fails

**Check**:
- AWS_ROLE_ARN secret exists and is correct
- INFRA_OUTPUTS_JSON variable exists and is valid JSON
- OIDC trust policy allows `apitanga/pomo-ssr` repo
- Lambda function names match outputs

### Sync workflow fails

**Check**:
- TF_API_TOKEN secret exists and is valid
- GH_PAT secret exists with `repo` scope
- TFC workspace accessible with token
- GitHub Actions has `actions: write` permission

---

## State Management

### Where is state stored?

- **pomo-ssr infrastructure**: Terraform Cloud workspace `pomossr`
- **Never local**: Always use TFC for state management

### Can I run terraform locally?

Yes, but it uses remote state in TFC:

```bash
cd ~/code/pomo-ssr/infra
terraform init   # Connects to TFC workspace
terraform plan   # Runs locally, uses remote state
terraform apply  # Applies via TFC (requires auth)
```

**Recommended**: Always use TFC UI for applies to maintain audit trail.

---

## Security

### No Static Credentials!

This project uses **OIDC dynamic credentials** throughout:

**Terraform Cloud**:
- Uses OIDC to assume `terraform-cloud-pomossr` IAM role
- Short-lived tokens (1 hour)
- Scoped to specific workspace

**GitHub Actions**:
- Uses OIDC to assume `github-actions-pomo-ssr` IAM role
- Short-lived tokens (1 hour)
- Scoped to specific repository

**Benefits**:
- No AWS access keys to rotate or leak
- Automatic expiration
- Better audit trail (CloudTrail shows which run/workflow)
- Principle of least privilege

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [pomo repo](https://github.com/apitanga/pomo) - Core infrastructure
- [serverless-ssr-module](https://github.com/apitanga/serverless-ssr-module) - Infrastructure module

---

**Last Updated**: 2026-02-09
