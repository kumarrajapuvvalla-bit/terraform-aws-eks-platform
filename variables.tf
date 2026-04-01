# ---------------------------------------------------------------------------
# Root module variables — all have validation blocks for fail-fast behaviour.
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region, e.g. us-east-1."
  }
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster (3-63 chars, alphanumeric and hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.cluster_name))
    error_message = "cluster_name must be 3-63 characters, start with a letter, and contain only alphanumeric characters and hyphens."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.cluster_version))
    error_message = "cluster_version must be in the format 1.XX (e.g. 1.29)."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of exactly 3 Availability Zones to deploy into."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for 3 public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 3 && alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Exactly 3 valid CIDR blocks must be provided for public subnets."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for 3 private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 3 && alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Exactly 3 valid CIDR blocks must be provided for private subnets."
  }
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cheaper but less resilient)."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "EC2 instance types for the worker node group."
  type        = list(string)
  default     = ["m5.xlarge"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "node_min_size must be at least 1."
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 10

  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size <= 100
    error_message = "node_max_size must be between 1 and 100."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes at launch."
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "node_desired_size must be at least 1."
  }
}

variable "enable_monitoring" {
  description = "Deploy kube-prometheus-stack (Prometheus + Grafana) via Helm."
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Must be at least 12 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "grafana_admin_password must be at least 12 characters long."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
