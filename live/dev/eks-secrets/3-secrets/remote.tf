data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../../eks-cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "external_secrets" {
  backend = "local"

  config = {
    path = "../1-external-secrets/terraform.tfstate"
  }
}

data "terraform_remote_state" "clustersecretstore" {
  backend = "local"

  config = {
    path = "../2-clustersecretstore/terraform.tfstate"
  }
}

data "terraform_remote_state" "ssm_secrets" {
  backend = "local"

  config = {
    path = "../../ssm-secrets/terraform.tfstate"
  }
}
