# allows us to use OIDC provider for short-lived access from Github Actions to AWS
# https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
}


data "aws_iam_policy_document" "github_actions_aws_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.iam_github_oidc_provider.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo_name}"]
    }
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_aws" {
  statement {
    effect    = "Deny"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }

  statement {
    sid    = "PullFromECR"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages"
    ]
    resources = [
      aws_ecr_repository.prime_generator_python.arn,
    ]
  }
  statement {
    sid    = "LimitedPushECRGithubActions"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      aws_ecr_repository.prime_generator_python.arn,
    ]
  }
  statement {
    sid       = "GetAuthorizationTokenFromECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_aws" {
  name        = "github-aws-oidc"
  path        = "/"
  description = "Policy for Github Actions to push to ECR"
  policy      = data.aws_iam_policy_document.github_actions_aws.json
}

resource "aws_iam_role" "github_actions_aws" {
  name               = "GithubActionsAWS"
  assume_role_policy = data.aws_iam_policy_document.github_actions_aws_assume_role.json
}

resource "aws_iam_role_policy_attachment" "github_actions_aws" {
  role       = aws_iam_role.github_actions_aws.name
  policy_arn = aws_iam_policy.github_actions_aws.arn
}
