output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role."
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node group IAM role."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the EKS node group IAM role."
  value       = aws_iam_role.node.name
}

output "alb_controller_role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller."
  value       = aws_iam_role.alb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role for the Cluster Autoscaler."
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the IRSA role for the EBS CSI Driver."
  value       = aws_iam_role.ebs_csi.arn
}
