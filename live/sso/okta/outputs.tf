output "aws_admins_group" {
  description = "Okta Group Name of AWS Admins"
  value       = okta_group.aws_admins.name
}

output "aws_read_only_group" {
  description = "Okta Group Name of AWS ReadOnly"
  value       = okta_group.aws_read_only.name
}
