locals {
  oidc_url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
