resource "aws_key_pair" "cluster" {
  count = var.create_ssh_key ? 1 : 0

  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key != null ? trimspace(var.ssh_public_key) : null

  tags = merge(local.common_tags, {
    Name = var.ssh_key_name
  })
}

# EC2 nodes are intentionally kept in this entry-point file. Supporting
# network, IAM and security resources are split by responsibility.
resource "aws_instance" "control_plane" {
  ami           = var.ami_id
  instance_type = var.control_plane_instance_type
  subnet_id     = aws_subnet.public[0].id
  private_ip    = var.control_plane_private_ip

  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = local.key_name
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  associate_public_ip_address = true

  user_data                   = var.control_plane_user_data
  user_data_replace_on_change = true

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(local.common_tags, {
    Name                = "${var.cluster_name}-control-plane"
    (local.cluster_tag) = "owned"
    NodeRole            = "control-plane"
  })

  depends_on = [aws_iam_role_policy.cluster_operations]
}

resource "aws_instance" "worker" {
  count = var.worker_count

  ami           = var.ami_id
  instance_type = var.worker_instance_type
  subnet_id     = aws_subnet.public[(count.index + 1) % length(aws_subnet.public)].id

  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = local.key_name
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  associate_public_ip_address = true

  user_data                   = var.worker_user_data
  user_data_replace_on_change = true

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(local.common_tags, {
    Name                = format("%s-worker-%02d", var.cluster_name, count.index + 1)
    (local.cluster_tag) = "owned"
    NodeRole            = "worker"
  })

  depends_on = [aws_instance.control_plane]
}
