resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags, { Name = "${var.cluster_name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.cluster_name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    Name                                    = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"               = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(local.tags, { Name = "${var.cluster_name}-public" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  vpc_id      = aws_vpc.this.id
  description = "Kubernetes node traffic"
  ingress {
    description = "SSH administration"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_admin_cidrs
  }
  ingress {
    description = "Kubernetes API"
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = var.allowed_admin_cidrs
  }
  ingress {
    description = "All traffic between nodes"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
  ingress {
    description = "NodePort from VPC/LB"
    from_port = 30000
    to_port = 32767
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags, { Name = "${var.cluster_name}-nodes" })
  lifecycle { create_before_destroy = true }
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name_prefix        = "${var.cluster_name}-nodes-"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ccm" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "ebs" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy_document" "bootstrap" {
  statement {
    actions   = ["ssm:PutParameter", "ssm:GetParameter", "ssm:DeleteParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/${var.cluster_name}/*"]
  }
  statement {
    actions   = ["ec2:DescribeInstances", "ec2:DescribeRegions", "ec2:DescribeAvailabilityZones", "ec2:DescribeRouteTables", "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVolumes", "ec2:CreateTags", "ec2:AttachVolume", "ec2:DetachVolume", "ec2:CreateVolume", "ec2:DeleteVolume", "ec2:ModifyVolume", "ec2:DescribeVolumesModifications"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "bootstrap"
  role   = aws_iam_role.nodes.id
  policy = data.aws_iam_policy_document.bootstrap.json
}
resource "aws_iam_instance_profile" "nodes" {
  name_prefix = "${var.cluster_name}-"
  role        = aws_iam_role.nodes.name
}

resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.control_plane_instance_type
  subnet_id                   = aws_subnet.public[0].id
  private_ip                  = var.control_plane_private_ip
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = var.ssh_key_name
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  associate_public_ip_address = true
  user_data                   = var.control_plane_user_data
  user_data_replace_on_change = true
  root_block_device {
    encrypted = true
    volume_type = "gp3"
    volume_size = var.root_volume_size
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }
  tags = merge(local.tags, { Name = "${var.cluster_name}-control-plane", "kubernetes.io/cluster/${var.cluster_name}" = "owned" })
  depends_on = [aws_iam_role_policy.bootstrap]
}

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = var.ami_id
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.public[(count.index + 1) % length(aws_subnet.public)].id
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = var.ssh_key_name
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  associate_public_ip_address = true
  user_data                   = var.worker_user_data
  user_data_replace_on_change = true
  root_block_device {
    encrypted = true
    volume_type = "gp3"
    volume_size = var.root_volume_size
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }
  tags = merge(local.tags, { Name = "${var.cluster_name}-worker-${count.index + 1}", "kubernetes.io/cluster/${var.cluster_name}" = "owned" })
  depends_on = [aws_instance.control_plane]
}