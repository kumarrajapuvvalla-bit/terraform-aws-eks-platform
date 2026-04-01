variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster is deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for the node groups."
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster."
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the node groups."
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for the worker node group."
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API server endpoint."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
