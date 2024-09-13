data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../../vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "ssm_secrets" {
  backend = "local"

  config = {
    path = "../../ssm-secrets/terraform.tfstate"
  }
}
