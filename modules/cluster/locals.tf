locals {
  tags = merge(var.tags, { ManagedBy = "Terraform", Cluster = var.cluster_name })
}