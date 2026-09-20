terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Primary Region
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "aws-serverless-event-driven"
      ManagedBy   = "Terraform"
    }
  }
}

# Secondary Region (Required for DynamoDB Global Tables & DR)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "aws-serverless-event-driven"
      ManagedBy   = "Terraform"
    }
  }
}