variable "project_name" {
  description = "Prefix used for bootstrap resources and IAM roles."
  type        = string
  default     = "platform-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for the remote-state bucket and bootstrap resources."
  type        = string
  default     = "eu-central-1"
}

variable "github_repository" {
  description = "GitHub repository allowed to request AWS credentials via OIDC, in owner/repo form."
  type        = string
  default     = "fadyy2k/platform-engineering-eks-gitops"
}

variable "environments" {
  description = "GitHub Environment names allowed to assume the apply role."
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}
