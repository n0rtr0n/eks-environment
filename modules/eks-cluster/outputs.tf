output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "eks_oidc_arn" {
  description = "The ARN of the OIDC provider for this cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}
