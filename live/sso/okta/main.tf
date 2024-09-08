terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.10.0"
    }
  }
}

# All values except scope are set through env vars
# Additionally, each scope defined here must be granted to the client app
# And the client app must be assigned the "Organization Administrator" and "Application Administrator" roles
# See https://developer.okta.com/docs/guides/terraform-enable-org-access/main/
provider "okta" {
  scopes = [
    "okta.apps.manage",
    "okta.apps.read",
    "okta.groups.manage",
    "okta.groups.read",
  ]
}

locals {
  aws_app_id = data.okta_app.aws.id
}

resource "okta_group" "aws_read_only" {
  name        = "AWS_SSO_ReadOnly"
  description = "AWS SSO Read Only"
}

resource "okta_group" "aws_admins" {
  name        = "AWS_SSO_Admins"
  description = "AWS SSO Admins"
}

# label must match the name that was configured in Okta app
data "okta_app" "aws" {
  label = "AWS IAM Identity Center"
}

resource "okta_app_group_assignments" "aws-admin" {
  app_id = local.aws_app_id
  group {
    id = okta_group.aws_admins.id
  }
  group {
    id = okta_group.aws_read_only.id
  }
}
