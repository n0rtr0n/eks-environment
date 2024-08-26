# EKS Environment

Playground for testing Terraform configurations for EKS

## Pre-requisites

* Install Terraform >= 1.9
* AWS CLI in environment running Terraform
* AWS user/role with privileges to run Terraform 

## Setup 

Deployment order:
* global
* vpc
* eks-cluster
* eks-config
