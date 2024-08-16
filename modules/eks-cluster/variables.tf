variable "cluster_admin_principal_arn" {
  description = "ARN of the AWS Principal for the k8s cluster admin"
  type        = string
}
variable "env" {
  description = "Environment"
  type        = string
}

variable "instance_types" {
  description = "EC2 instance types of worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Version of EKS to use"
  type        = string
}

variable "private_subnets" {
  description = "CIDR ranges for VPC private subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

