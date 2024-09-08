provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

data "terraform_remote_state" "okta" {
  backend = "local"

  config = {
    path = "../okta/terraform.tfstate"
  }
}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# Admins

resource "aws_ssoadmin_permission_set" "admin" {
  name         = "AWSSSOAdmin"
  instance_arn = local.instance_arn
}

data "aws_iam_policy_document" "admin" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "admin" {
  inline_policy      = data.aws_iam_policy_document.admin.json
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

data "aws_identitystore_group" "admin" {
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = data.terraform_remote_state.okta.outputs.aws_admins_group
    }
  }
}

resource "aws_ssoadmin_account_assignment" "admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_group.admin.group_id
  principal_type = "GROUP"

  target_id   = local.account_id
  target_type = "AWS_ACCOUNT"
}

# ReadOnly

resource "aws_ssoadmin_permission_set" "read_only" {
  name         = "AWSSSOReadOnly"
  instance_arn = local.instance_arn
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}

data "aws_identitystore_group" "read_only" {
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = data.terraform_remote_state.okta.outputs.aws_read_only_group
    }
  }
}

resource "aws_ssoadmin_account_assignment" "read_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn

  principal_id   = data.aws_identitystore_group.read_only.group_id
  principal_type = "GROUP"

  target_id   = local.account_id
  target_type = "AWS_ACCOUNT"
}
