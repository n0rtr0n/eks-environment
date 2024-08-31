output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.eks_cluster_name
}

output "eks_oidc_arn" {
  description = "The ARN of the OIDC provider for this cluster"
  value       = module.eks_cluster.eks_oidc_arn
}
