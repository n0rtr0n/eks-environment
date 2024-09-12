data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_kms_alias" "default" {
  name = "alias/aws/ssm"
}

data "aws_ssm_parameter" "tailscale_api_key" {
  name = data.terraform_remote_state.ssm_secrets.outputs.tailscale_api_key_ssm_name
}

data "aws_ssm_parameter" "tailscale_oauth_client_id" {
  name = data.terraform_remote_state.ssm_secrets.outputs.tailscale_oauth_client_id_ssm_name
}

data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name = data.terraform_remote_state.ssm_secrets.outputs.tailscale_oauth_client_secret_ssm_name
}
