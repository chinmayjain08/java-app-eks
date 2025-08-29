output "cluster_id" {
  value = aws_eks_cluster.devopsshack.id
}
 
output "node_group_id" {
  value = aws_eks_node_group.devopsshack.id
}
 
output "vpc_id" {
  value = aws_vpc.devopsshack.id
}
 
output "subnet_ids" {
  value = aws_subnet.devopsshack-subnet[*].id
}
