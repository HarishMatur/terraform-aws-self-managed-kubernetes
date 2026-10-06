output "vpc_id" {
  description = "ID of the cluster VPC."
  value       = aws_vpc.cluster.id
}
output "subnet_ids" {
  description = "Public subnet IDs used by the cluster nodes and load balancers."
  value       = aws_subnet.public[*].id
}
output "security_group_id" {
  description = "Security group shared by the Kubernetes nodes."
  value       = aws_security_group.nodes.id
}
output "control_plane_public_ip" {
  description = "Public address of the control-plane node."
  value       = aws_instance.control_plane.public_ip
}
output "control_plane_private_ip" {
  description = "Private Kubernetes API endpoint address."
  value       = aws_instance.control_plane.private_ip
}
output "worker_public_ips" {
  description = "Public addresses of worker nodes."
  value       = aws_instance.worker[*].public_ip
}
output "node_role_arn" {
  description = "IAM role assumed by the cluster nodes."
  value       = aws_iam_role.nodes.arn
}
