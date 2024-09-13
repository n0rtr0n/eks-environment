resource "aws_security_group" "tailscale_subnet_router" {
  name        = "tailscale-subnet-router-${local.env}"
  description = "Tailscale Subnet Router rules"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "tailscale-subnet-router-${local.env}"
  }
}

# recommendation is to open UDP 41641 from everywhere, which is why this is in a public subnet:
# https://tailscale.com/kb/1141/aws-rds#step-1-set-up-a-subnet-router
resource "aws_vpc_security_group_ingress_rule" "allow_tailscale_udp" {
  security_group_id = aws_security_group.tailscale_subnet_router.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 41641
  ip_protocol       = "udp"
  to_port           = 41641
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tailscale_subnet_router.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# instance permissions to allow ec2 to grab tailscale params
resource "aws_iam_instance_profile" "tailscale_subnet_router" {
  name = "tailscale-subnet-router-${local.env}"
  role = aws_iam_role.tailscale_subnet_router.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "tailscale_subnet_router" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter*"
    ]
    resources = [
      data.aws_ssm_parameter.tailscale_api_key.arn,
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.default.arn]
  }
}

resource "aws_iam_policy" "tailscale_subnet_router" {
  name   = "tailscale-subnet-router-${local.env}"
  policy = data.aws_iam_policy_document.tailscale_subnet_router.json
}

resource "aws_iam_role_policy_attachment" "tailscale_subnet_router" {
  role       = aws_iam_role.tailscale_subnet_router.name
  policy_arn = aws_iam_policy.tailscale_subnet_router.arn
}

resource "aws_iam_role" "tailscale_subnet_router" {
  name               = "tailscale-subnet-router-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_key_pair" "tailscale_ssh" {
  key_name   = "tailscale-ssh"
  public_key = var.ssh_public_key
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  instance_type = "t3.micro"
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [
    aws_security_group.tailscale_subnet_router.id
  ]
  iam_instance_profile        = aws_iam_instance_profile.tailscale_subnet_router.name
  key_name                    = aws_key_pair.tailscale_ssh.key_name
  associate_public_ip_address = true
  tags = {
    Environment = local.env
    Name        = "tailscale-subnet-router-${local.env}"
  }
  user_data = templatefile(
    "${path.module}/user_data.sh",
    {
      region     = local.region,
      cidr_range = local.cidr_range,
    }
  )
}
