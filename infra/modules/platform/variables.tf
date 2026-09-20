variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the environment VPC."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether to expose the EKS API publicly."
  type        = bool
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired managed node count."
  type        = number
}

variable "node_min_size" {
  description = "Minimum managed node count."
  type        = number
}

variable "node_max_size" {
  description = "Maximum managed node count."
  type        = number
}
