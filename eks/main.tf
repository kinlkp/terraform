/*
 * create EKS iam role resources
*/

resource "aws_iam_role" "eks-iam-role" {
  name = "abc-eks-iam-role"

  path = "/"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
   ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}


/*
 * create EKS worknode iam role resources
*/

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}


/*
* Create EKS cluster in region us-east-1 and us-west-1
*/

module "create-active-eks" {
  source            = "./build_cluster"
  project           = "project-b-"
  region            = "us-east-1"
  network-ip-range  = "10.0.0.0/16"
  public-net        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  private-net       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  iam-role-eks-arn  = aws_iam_role.eks-iam-role.arn
  iam-role-node-arn = aws_iam_role.workernodes.arn
  mode              = "active"
}

# module "k8s" {
#   source = "./k8s"
#   cluster_name = module.create-active-eks.cluster_id
#   cert = module.create-active-eks.cert
#   endpoint = module.create-active-eks.endpoint
# }


# module "create-passive-eks" {
#   source = "./build_cluster"
#   project = "project-b-"
#   region = "us-west-1"
#   network-ip-range = "10.10.0.0/16"
#   public-net = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
#   private-net = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
#   iam-role-eks-arn = aws_iam_role.eks-iam-role.arn
#   iam-role-node-arn = aws_iam_role.workernodes.arn
#   mode = "passive"
# }

# module "k8s" {
#   source = "./k8s"
# }


# output "active-eks-id" {
#   value = module.create-active-eks.cluster_id
# }

# output "active-eks-status" {
#   value = module.create-active-eks.cluster_status
# }

# output "passvie-eks-id" {
#   value = module.create-passive-eks.cluster_id
# }

# output "passive-eks-status" {
#   value = module.create-passive-eks.cluster_status
# }

