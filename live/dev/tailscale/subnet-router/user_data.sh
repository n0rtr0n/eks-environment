#!/bin/bash

cidr_range="${cidr_range}"
region="${region}"

sudo yum install yum-utils

sudo yum-config-manager --add-repo https://pkgs.tailscale.com/stable/amazon-linux/2/tailscale.repo
sudo yum install tailscale -y

echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

sudo systemctl enable --now tailscaled

tailscale_api_key=$(aws ssm get-parameter --region $region --name "/dev/tailscale-api-key" --with-decryption --query "Parameter.Value" --output text)

sudo tailscale up --advertise-routes=$cidr_range --auth-key=$tailscale_api_key --accept-dns=false
