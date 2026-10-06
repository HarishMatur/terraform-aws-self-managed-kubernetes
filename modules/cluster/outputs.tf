output "vpc_id" { value = aws_vpc.this.id }
output "subnet_ids" { value = aws_subnet.public[*].id }
output "security_group_id" { value = aws_security_group.nodes.id }
output "control_plane_public_ip" { value = aws_instance.control_plane.public_ip }
output "control_plane_private_ip" { value = aws_instance.control_plane.private_ip }
output "worker_public_ips" { value = aws_instance.worker[*].public_ip }
output "node_role_arn" { value = aws_iam_role.nodes.arn }
