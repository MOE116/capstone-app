output "jenkins_public_ip" {
  description = "Public IP of the Jenkins host"
  value = aws_instance.jenkins.public_ip
}

output "eks_cluster_name" {
  value = aws_eks_cluster.devops_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.devops_cluster.endpoint
}

output "eks_nodegroup_status" {
  value = aws_eks_node_group.devops_nodes.status
}

