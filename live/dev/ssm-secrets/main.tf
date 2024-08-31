locals {
  env    = "dev"
  region = "us-west-2"
}

data "aws_kms_alias" "default" {
  name = "alias/aws/ssm"
}

resource "random_string" "secret_seed" {
  length  = 24
  special = true
}

resource "aws_ssm_parameter" "tailscale_api_key" {
  name        = "/${local.env}/tailscale-api-key"
  type        = "SecureString"
  key_id      = data.aws_kms_alias.default.arn
  description = "TailScale API key for ${local.env} environment"
  value       = random_string.secret_seed.result

  # needs a value to start, but we will update it through AWS
  lifecycle {
    ignore_changes = [value]
  }
}
