output "clustersecretstore_name" {
  description = "Name of the ClusterSecretStore resource"
  value       = kubernetes_manifest.ssm_parameterstore_clustersecretstore.manifest.metadata.name
}
