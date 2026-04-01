# ---------------------------------------------------------------------------
# Root module outputs
# ---------------------------------------------------------------------------

output "region" {
  description = "AWS region where the platform was deployed."
  value       = var.aws_region
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL — used to create IRSA trust policies."
  value       = module.eks.oidc_provider_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "node_group_role_arn" {
  description = "ARN of the IAM role attached to EKS managed node groups."
  value       = module.iam.node_role_arn
}

output "alb_controller_role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller."
  value       = module.iam.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role for the Cluster Autoscaler."
  value       = module.iam.cluster_autoscaler_role_arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the IRSA role for the EBS CSI driver."
  value       = module.iam.ebs_csi_role_arn
}
