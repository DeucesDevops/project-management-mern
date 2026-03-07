###############################################################################
# Security Groups — additional ingress/egress rules
###############################################################################

# Allow nodes to communicate with DocumentDB (if enabled)
resource "aws_security_group" "docdb" {
  count       = var.enable_documentdb ? 1 : 0
  name        = "${local.cluster_name}-docdb-sg"
  description = "Security group for DocumentDB — allow access from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MongoDB/DocumentDB from EKS nodes"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow nodes to communicate with ElastiCache Redis (if enabled)
resource "aws_security_group" "elasticache" {
  count       = var.enable_elasticache ? 1 : 0
  name        = "${local.cluster_name}-elasticache-sg"
  description = "Security group for ElastiCache — allow access from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
