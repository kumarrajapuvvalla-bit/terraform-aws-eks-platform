output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC identity provider."
  value       = aws_iam_openid_connect_provider.this.url
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster."
  value       = aws_security_group.cluster.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption."
  value       = aws_kms_key.eks_secrets.arn
}
