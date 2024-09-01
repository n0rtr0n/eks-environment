
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
  name               = "eks-worker-nodes-testing-${var.env}"
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

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  version         = var.eks_version
  node_group_name = "${var.eks_cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks-nodes.arn

  subnet_ids = var.private_subnets

  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.worker_node_scaling_config.desired_size
    max_size     = var.worker_node_scaling_config.max_size
    min_size     = var.worker_node_scaling_config.min_size
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
