data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "global" {
  backend = "local"

  config = {
    path = "../../global/terraform.tfstate"
  }
}
