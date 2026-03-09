###############################################################################
# DocumentDB Module (MongoDB-compatible) — optional managed database
###############################################################################

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "this" {
  count       = var.enable_documentdb ? 1 : 0
  name        = "${var.cluster_name}-docdb-sg"
  description = "Security group for DocumentDB — allow access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MongoDB/DocumentDB from EKS nodes"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── Secret ────────────────────────────────────────────────────────────────────
resource "random_password" "master" {
  count   = var.enable_documentdb ? 1 : 0
  length  = 32
  special = false # DocumentDB password cannot contain certain special chars
}

resource "aws_secretsmanager_secret" "this" {
  count = var.enable_documentdb ? 1 : 0
  name  = "${var.cluster_name}/docdb/master-password"
}

resource "aws_secretsmanager_secret_version" "this" {
  count     = var.enable_documentdb ? 1 : 0
  secret_id = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master[0].result
  })
}

# ── Cluster ───────────────────────────────────────────────────────────────────
resource "aws_docdb_subnet_group" "this" {
  count      = var.enable_documentdb ? 1 : 0
  name       = "${var.cluster_name}-docdb-subnet"
  subnet_ids = var.private_subnets
}

resource "aws_docdb_cluster_parameter_group" "this" {
  count  = var.enable_documentdb ? 1 : 0
  family = "docdb5.0"
  name   = "${var.cluster_name}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

resource "aws_docdb_cluster" "this" {
  count = var.enable_documentdb ? 1 : 0

  cluster_identifier              = "${var.cluster_name}-docdb"
  engine                          = "docdb"
  engine_version                  = "5.0.0"
  master_username                 = var.master_username
  master_password                 = random_password.master[0].result
  db_subnet_group_name            = aws_docdb_subnet_group.this[0].name
  vpc_security_group_ids          = [aws_security_group.this[0].id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this[0].name

  storage_encrypted         = true
  deletion_protection       = var.environment == "production"
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${var.cluster_name}-docdb-final" : null

  backup_retention_period = var.environment == "production" ? 7 : 1
  preferred_backup_window = "03:00-04:00"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

resource "aws_docdb_cluster_instance" "this" {
  count = var.enable_documentdb ? var.instance_count : 0

  identifier         = "${var.cluster_name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.this[0].id
  instance_class     = var.instance_class

  auto_minor_version_upgrade = true
}
