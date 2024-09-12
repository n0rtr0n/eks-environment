data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter*"
    ]
    resources = [
      data.aws_ssm_parameter.tailscale_api_key.arn,
      data.aws_ssm_parameter.tailscale_oauth_client_id.arn,
      data.aws_ssm_parameter.tailscale_oauth_client_secret.arn,
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.default.arn]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "external-secrets-${local.env}"
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = data.terraform_remote_state.external_secrets.outputs.external_secrets_iam_role_name
  policy_arn = aws_iam_policy.external_secrets.arn
}

# Tailscale credentials
resource "kubernetes_manifest" "tailscale" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "tailscale-${local.env}"
      namespace = "default" # TODO: default for now, will probably change this shortly
    }
    spec = {
      secretStoreRef = {
        name = data.terraform_remote_state.clustersecretstore.outputs.clustersecretstore_name
        kind = "ClusterSecretStore"
      }
      refreshInterval = "60s"
      target = {
        name           = "tailscale"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "api_key"
          remoteRef = {
            key = data.aws_ssm_parameter.tailscale_api_key.name
          }
        },
        {
          secretKey = "oauth_client_id"
          remoteRef = {
            key = data.aws_ssm_parameter.tailscale_oauth_client_id.name
          }
        },
        {
          secretKey = "oauth_client_secret"
          remoteRef = {
            key = data.aws_ssm_parameter.tailscale_oauth_client_secret.name
          }
        }
      ]
    }
  }
}
