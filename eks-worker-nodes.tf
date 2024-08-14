
data "aws_iam_policy_document" "eks-worker-nodes-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-nodes" {
  name               = "eks-worker-nodes-testing-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.eks-worker-nodes-assume_role.json
}

# TODO: customize to restrict the permissions of this role
resource "aws_iam_role_policy_attachment" "eks-worker-node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodes.name
}

# TODO: customize to restrict the permissions of this role
resource "aws_iam_role_policy_attachment" "eks-worker-node-cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodes.name
}

# TODO: customize to restrict the permissions of this role
resource "aws_iam_role_policy_attachment" "eks-worker-nodes-ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodes.name
}

resource "aws_eks_node_group" "testing" {
  cluster_name    = aws_eks_cluster.testing.name
  version         = local.eks_version
  node_group_name = "testing"
  node_role_arn   = aws_iam_role.eks-nodes.arn

  subnet_ids = module.vpc.private_subnets

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "testing"
  }

  lifecycle {
    # this value may conflict with Terraform state
    ignore_changes = [scaling_config[0].desired_size]
  }
}
