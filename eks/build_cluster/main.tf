provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "${var.project}-${var.mode}-cluster"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${var.project}-vpc"

  cidr = var.network-ip-range
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = var.private-net
  public_subnets  = var.public-net

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

resource "aws_eks_cluster" "eks" {
  name = "${var.project}-${var.mode}-cluster"
  role_arn = var.iam-role-eks-arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }

  # TODO
  depends_on = [
    # aws_iam_role.eks-iam-role,
  ]
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.eks.name
  node_group_name = "${var.project}-workernodes"
  node_role_arn  = var.iam-role-node-arn
  subnet_ids   = module.vpc.public_subnets
  instance_types = ["t2.micro"]
 
  scaling_config {
    desired_size = 2
    max_size   = 5
    min_size   = 1
  }
 
  # TODO
  depends_on = [
   # aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   # aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   ##aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

# Update ~/.kube/config
resource "local_file" "kubeconfig" {
  content = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
    server: ${aws_eks_cluster.eks.endpoint}
  name: ${aws_eks_cluster.eks.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.eks.arn}
    user: ${aws_eks_cluster.eks.arn}
  name: ${aws_eks_cluster.eks.arn}
current-context: ${aws_eks_cluster.eks.arn}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.eks.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - us-east-1
      - eks
      - get-token
      - --cluster-name
      - ${aws_eks_cluster.eks.name}
      command: aws
EOT
  filename = "/home/brianlk/.kube/config-${aws_eks_cluster.eks.name}"
}
