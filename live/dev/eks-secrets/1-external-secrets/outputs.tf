output "external_secrets_iam_role_name" {
  description = "IAM Role name for external-secrets"
  value       = aws_iam_role.external_secrets.name
}

output "external_secrets_namespace" {
  description = "Namespace for external-secrets"
  value       = kubernetes_namespace_v1.secrets.id
}

output "external_secrets_service_account" {
  description = "Service account for external-secrets"
  value       = kubernetes_service_account_v1.secrets.metadata[0].name
}
