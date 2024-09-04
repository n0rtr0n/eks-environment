output "subnet_router_security_group_id" {
  description = "The security group id of the Tailscale Subnet Router"
  value       = aws_security_group.tailscale_subnet_router.id
}
