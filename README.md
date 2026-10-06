# terraform-aws-self-managed-kubernetes

Reusable AWS infrastructure module for a self-managed kubeadm cluster. It creates the VPC, public subnets, routing, security groups, IAM instance profile, SSH key pair, and EC2 control-plane/worker instances. Kubernetes bootstrap content is supplied by the caller so cluster lifecycle choices stay outside the infrastructure module.

## Usage

```hcl
module "cluster" {
  source = "git::https://github.com/HarishMatur/terraform-aws-self-managed-kubernetes.git//modules/cluster?ref=v1.0.0"

  cluster_name            = "assignment"
  vpc_cidr                = "10.50.0.0/16"
  availability_zones      = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  public_subnet_cidrs     = ["10.50.0.0/24", "10.50.1.0/24", "10.50.2.0/24"]
  allowed_admin_cidrs     = ["203.0.113.10/32"]
  ssh_key_name            = "assignment-key"
  create_ssh_key          = true
  ssh_public_key          = file(pathexpand("~/.ssh/id_ed25519.pub"))
  control_plane_user_data = local.control_plane_user_data
  worker_user_data        = local.worker_user_data
}
```

Set `create_ssh_key = false` to use an existing EC2 key pair named by `ssh_key_name`. Do not expose SSH or the Kubernetes API to `0.0.0.0/0`. Tag a release before consuming this module and pin the caller to that tag.
