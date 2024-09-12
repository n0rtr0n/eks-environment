# This must be completed in a separate step because it relies on CRDs installed by the external-secrets operator 
# Getting an error: API did not recognize GroupVersionKind from manifest (CRD may not be installed)
resource "kubernetes_manifest" "ssm_parameterstore_clustersecretstore" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "external-secrets-clustersecretstore-${local.env}"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = local.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = data.terraform_remote_state.external_secrets.outputs.external_secrets_service_account
                namespace = data.terraform_remote_state.external_secrets.outputs.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  }
}
