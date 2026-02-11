# Terraform and Provider Versions

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store state in Terraform Cloud
  cloud {
    organization = "Pitangaville"
    workspaces {
      name = "pomossr"
    }
  }
}
