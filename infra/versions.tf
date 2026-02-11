# Terraform and Provider Versions

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store state in Terraform Cloud.
  # When forking: update organization and workspace name.
  # Keep this block — the sync workflow reads outputs via terraform output -json.
  cloud {
    organization = "Pitangaville" # ← your TFC organization
    workspaces {
      name = "pomossr" # ← your TFC workspace name
    }
  }
}
