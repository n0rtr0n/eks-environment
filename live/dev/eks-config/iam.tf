
# data "aws_iam_policy_document" "eks_admin_trust" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "eks_admin" {
#   name               = "${local.env}-${local.cluster_name}-eks-admin"
#   assume_role_policy = data.aws_iam_policy_document.eks_admin_trust.json
# }

# data "aws_iam_policy_document" "eks_admin" {
#   statement {
#     effect    = "Allow"
#     actions   = ["eks:*"]
#     resources = ["*"]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = ["iam:PassRole"]
#     resources = ["*"]

#     condition {
#       test     = "StringEquals"
#       variable = "iam:PassedToService"
#       values   = ["eks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_policy" "eks_admin" {
#   name   = "AmazonEKSAdminPolicy-${local.env}"
#   policy = data.aws_iam_policy_document.eks_admin.json
# }

# resource "aws_iam_role_policy_attachment" "eks_admin" {
#   role       = aws_iam_role.eks_admin.name
#   policy_arn = aws_iam_policy.eks_admin
# }
