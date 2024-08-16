output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks-cluster.eks_cluster_name
}
