output "tailscale_api_key_ssm_name" {
  description = "TailScale API Key SSM Parameter Name"
  value       = aws_ssm_parameter.tailscale_api_key.name
}

output "tailscale_oauth_client_id_ssm_name" {
  description = "TailScale OAuth client id SSM Parameter Name"
  value       = aws_ssm_parameter.tailscale_oauth_client_id.name
}

output "tailscale_oauth_client_secret_ssm_name" {
  description = "TailScale OAuth client secret SSM Parameter Name"
  value       = aws_ssm_parameter.tailscale_oauth_client_secret.name
}
