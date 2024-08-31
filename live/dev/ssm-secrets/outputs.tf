output "tailscale_api_key_ssm_name" {
  description = "TailScale API Key SSM Parameter Name"
  value       = aws_ssm_parameter.tailscale_api_key.name
}
