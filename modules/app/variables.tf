variable "name" {
  description = "Name of the Kubernetes app"
}

variable "namespace" {
  description = "Namespace to deploy app into"
}

variable "image_name" {
  description = "Container image of app"
}

variable "image_tag" {
  description = "Tag of container image"
}

variable "labels" {
  description = "Labels to apply to the deployment"
  type        = map(string)
}

variable "service_port" {
  description = "Port of service"
  type        = number
}

variable "container_port" {
  description = "Port of container"
  type        = number
}

variable "replica_count" {
  description = "Number of pods to deploy"
  default     = 1
  type        = number
}
