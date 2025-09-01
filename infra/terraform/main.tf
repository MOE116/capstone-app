terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4"
}

provider "aws" {
  region = var.region
}

# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "devops_vpc" {
  cidr_block = var.vpc_cidr
  tags = { Name = "devops-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.devops_vpc.id
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-a" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-b" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "devops_sg" {
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devops-sg" }
}

# -----------------------------
# IAM roles for Jenkins EC2
# -----------------------------
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_EKSClusterPolicy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_EKSWorkerNodePolicy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_EC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-eks-profile"
  role = aws_iam_role.jenkins_role.name
}

# -----------------------------
# Jenkins EC2
# -----------------------------
resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_a.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y openjdk-17-jdk curl gnupg2 unzip apt-transport-https ca-certificates lsb-release software-properties-common docker.io
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip -o awscliv2.zip
              ./aws/install

              # kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Jenkins
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
              apt-get update -y
              apt-get install -y jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = { Name = "jenkins-host" }
}

# -----------------------------
# IAM Roles for EKS
# -----------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service" 
      identifiers = ["eks.amazonaws.com"] 
      }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eksNodeRole"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes_assume.json
}

data "aws_iam_policy_document" "eks_nodes_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service" 
      identifiers = ["ec2.amazonaws.com"] 
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -----------------------------
# EKS Cluster + Node Group
# -----------------------------
resource "aws_eks_cluster" "devops_cluster" {
  name     = "devops-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

resource "aws_eks_node_group" "devops_nodes" {
  cluster_name    = aws_eks_cluster.devops_cluster.name
  node_group_name = "devops-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  instance_types = ["t3.small"]

  # ✅ Ensure rolling updates happen
  update_config {
    max_unavailable = 1   # only 1 node at a time can go down
    # alternatively: max_unavailable_percentage = 50
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly
  ]
}

# -----------------------------
# aws-auth ConfigMap (Terraform-managed)
# -----------------------------
resource "kubernetes_config_map" "aws_auth" {
  depends_on = [aws_eks_node_group.devops_nodes]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.jenkins_role.arn
        username = "jenkins"
        groups   = ["system:masters"]
      }
    ])
  }
}
