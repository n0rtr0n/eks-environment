data "aws_kms_alias" "default" {
  name = "alias/aws/ssm"
}

data "aws_ssm_parameter" "tailscale_api_key" {
  name = data.terraform_remote_state.ssm_secrets.outputs.tailscale_api_key_ssm_name
}

# latest amazon linux AMI
data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
