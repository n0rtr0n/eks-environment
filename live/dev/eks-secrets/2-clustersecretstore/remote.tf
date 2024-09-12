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
