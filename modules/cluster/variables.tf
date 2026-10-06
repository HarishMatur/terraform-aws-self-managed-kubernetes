variable "cluster_name" {
  description = "Name used for Kubernetes discovery tags and AWS resource naming."
  type        = string
}
variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the cluster VPC."
  type        = string
}
variable "availability_zones" {
  description = "Availability zones used by the public subnets."
  type = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two AZs are required."
  }
}
variable "public_subnet_cidrs" {
  description = "One public subnet CIDR for each availability zone."
  type = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "public_subnet_cidrs and availability_zones must contain the same number of entries."
  }
}
variable "allowed_admin_cidrs" {
  description = "CIDRs allowed to reach SSH and the Kubernetes API."
  type = list(string)
  validation {
    condition     = length(var.allowed_admin_cidrs) > 0 && !contains(var.allowed_admin_cidrs, "0.0.0.0/0")
    error_message = "Supply restricted admin CIDRs; 0.0.0.0/0 is rejected."
  }
}
variable "ssh_key_name" {
  description = "Existing EC2 key pair name used for break-glass SSH access."
  type        = string
}
variable "ami_id" {
  description = "Ubuntu AMI used by all cluster nodes."
  type        = string
}
variable "control_plane_instance_type" {
  description = "EC2 instance type for the control-plane node."
  type    = string
  default = "t3.medium"
}
variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes."
  type    = string
  default = "t3.medium"
}
variable "worker_count" {
  description = "Number of worker nodes."
  type    = number
  default = 2
  validation {
    condition     = var.worker_count >= 2
    error_message = "This assignment requires at least two worker nodes."
  }
}
variable "root_volume_size" {
  description = "Root volume size in GiB for every node."
  type    = number
  default = 30
}
variable "control_plane_private_ip" {
  description = "Stable private address used by the Kubernetes API endpoint."
  type        = string
}
variable "control_plane_user_data" {
  description = "Rendered bootstrap script for the control-plane node."
  type      = string
  sensitive = true
}
variable "worker_user_data" {
  description = "Rendered bootstrap script shared by worker nodes."
  type      = string
  sensitive = true
}
variable "tags" {
  description = "Additional tags applied to all supported AWS resources."
  type    = map(string)
  default = {}
}
