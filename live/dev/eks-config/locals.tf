locals {
  cluster_name                       = data.terraform_remote_state.eks.outputs.eks_cluster_name
  domain_name                        = var.domain_name
  env                                = "dev"
  load_balancer_hostname             = kubernetes_ingress_v1.applications.status.0.load_balancer.0.ingress.0.hostname
  namespace                          = kubernetes_namespace_v1.applications.metadata[0].name
  region                             = var.region
  prime_generator_python_app_name    = "prime-generator-python-${local.env}"
  prime_generator_python_domain_name = "${local.prime_generator_python_app_name}.${local.domain_name}"
  public_subnet_ids                  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
}
