provider "aws" {
  region = "ap-south-1"
}
 
##########################
# VPC and Subnets
##########################
resource "aws_vpc" "board_game_vpc" {
  cidr_block = "10.0.0.0/16"
 
  tags = {
    Name = "board-game-VPC"
  }
}
 
resource "aws_subnet" "board_game_subnet" {
  count = 2
  vpc_id                  = aws_vpc.board_game_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.board_game_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true
 
  tags = {
    Name = "board-game-subnet-${count.index}"
  }
}
 
resource "aws_internet_gateway" "board_game_igw" {
  vpc_id = aws_vpc.board_game_vpc.id
 
  tags = {
    Name = "board-game-igw"
  }
}
 
resource "aws_route_table" "board_game_route_table" {
  vpc_id = aws_vpc.board_game_vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.board_game_igw.id
  }
 
  tags = {
    Name = "board-game-route-table"
  }
}
 
resource "aws_route_table_association" "board_game_rta" {
  count          = 2
  subnet_id      = aws_subnet.board_game_subnet[count.index].id
  route_table_id = aws_route_table.board_game_route_table.id
}
 
##########################
# Security Groups
##########################
resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = aws_vpc.board_game_vpc.id
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "boardGame-cluster-sg"
  }
}
 
resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.board_game_vpc.id
 
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "boardGame-node-sg"
  }
}
 
##########################
# IAM Roles
##########################
resource "aws_iam_role" "eks_cluster_role" {
  name = "boardGame-cluster-role"
 
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
 
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
 
resource "aws_iam_role" "eks_node_role" {
  name = "boardGame-node-role"
 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
 
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
 
resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
 
##########################
# EKS Cluster
##########################
resource "aws_eks_cluster" "board_game_cluster" {
  name     = "boardGame-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
 
  vpc_config {
    subnet_ids         = aws_subnet.board_game_subnet[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
 
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
 
##########################
# EKS Node Group
##########################
resource "aws_eks_node_group" "board_game_nodes" {
  cluster_name    = aws_eks_cluster.board_game_cluster.name
  node_group_name = "boardGame-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.board_game_subnet[*].id
 
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
 
  instance_types = ["t2.medium"]
 
 
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy
  ]
}
