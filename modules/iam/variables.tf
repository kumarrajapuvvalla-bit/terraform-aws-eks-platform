variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider for the EKS cluster."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC identity provider (with https://)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all IAM resources."
  type        = map(string)
  default     = {}
}
