variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "private_subnets" {
  description = "CIDR ranges for VPC private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR ranges for VPC public subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "vpc_cidr" {
  description = "CIDR range for VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name for VPC"
  type        = string
}
