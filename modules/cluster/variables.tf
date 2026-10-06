variable "cluster_name" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" {
  type = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two AZs are required."
  }
}
variable "public_subnet_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two subnets are required."
  }
}
variable "allowed_admin_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.allowed_admin_cidrs) > 0 && !contains(var.allowed_admin_cidrs, "0.0.0.0/0")
    error_message = "Supply restricted admin CIDRs; 0.0.0.0/0 is rejected."
  }
}
variable "ssh_key_name" { type = string }
variable "ami_id" { type = string }
variable "control_plane_instance_type" {
  type    = string
  default = "t3.medium"
}
variable "worker_instance_type" {
  type    = string
  default = "t3.medium"
}
variable "worker_count" {
  type    = number
  default = 2
}
variable "root_volume_size" {
  type    = number
  default = 30
}
variable "control_plane_private_ip" { type = string }
variable "control_plane_user_data" {
  type      = string
  sensitive = true
}
variable "worker_user_data" {
  type      = string
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
