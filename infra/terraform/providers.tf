provider "kubernetes" {
  host                   = aws_eks_cluster.devops_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.devops_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.devops_cluster.token
}

data "aws_eks_cluster_auth" "devops_cluster" {
  name = aws_eks_cluster.devops_cluster.name
}
