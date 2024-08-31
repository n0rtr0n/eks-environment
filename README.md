# EKS Environment

Playground for testing Terraform configurations for EKS

## Pre-requisites

* Install Terraform >= 1.9
* AWS CLI in environment running Terraform
* AWS user/role with privileges to run Terraform 


## Setup 

Deployment order:
* global
* ssm-secrets
* vpc
* eks-cluster
* ssm-secrets
* eks-secrets/1-external-secrets # this *must* be deployed before the cluster secret store
* eks-secrets/2-clustersecretstore # this *must* be deployed before adding secrets to the clustersecretstore
* eks-secrets/3-secrets
* eks-config

## Tearing Down

The following resources must be removed from the cluster manually, prior to tearing everything else down:
```
kubectl delete ing -n applications-dev applications-dev 
```

Order:
* eks-config
* eks-secrets/3-secrets
* eks-secrets/2-clustersecretstore
* eks-secrets/1-external-secrets
* eks-cluster
* vpc
Optional:
* ssm-secrets
* global

## Decisions

* Secrets management - Parameter store with external secrets operator
* ParamterStore vs Secretsmanager - simplicity and cost
* State management - local w remote lookups
* Variable management - secrets.tfvars 
* Resource declaration in Helm vs Terraform