variable "primary_region" {
  description = "Primary AWS Region for event-driven infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS Region for Multi-Region Disaster Recovery replication"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Optional custom domain name for Route 53 multi-region routing"
  type        = string
  default     = ""
}