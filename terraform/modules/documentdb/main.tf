###############################################################################
# Amazon DocumentDB (MongoDB-compatible) + Secrets Manager
###############################################################################

resource "random_password" "master" {
  length  = 32
  special = false # DocumentDB passwords cannot contain certain special chars
}

resource "aws_secretsmanager_secret" "docdb_password" {
  name                    = "${var.cluster_name}/docdb/master-password"
  recovery_window_in_days = var.environment == "production" ? 7 : 0
}

resource "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = aws_secretsmanager_secret.docdb_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    endpoint = aws_docdb_cluster.this.endpoint
    port     = aws_docdb_cluster.this.port
  })
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "docdb" {
  name        = "${var.cluster_name}-docdb-sg"
  description = "Allow DocumentDB access from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MongoDB from EKS nodes"
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

# ── Subnet Group & Parameter Group ───────────────────────────────────────────

resource "aws_docdb_subnet_group" "this" {
  name       = "${var.cluster_name}-docdb-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_docdb_cluster_parameter_group" "this" {
  family = "docdb5.0"
  name   = "${var.cluster_name}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

# ── Cluster ───────────────────────────────────────────────────────────────────

resource "aws_docdb_cluster" "this" {
  cluster_identifier              = "${var.cluster_name}-docdb"
  engine                          = "docdb"
  engine_version                  = "5.0.0"
  master_username                 = var.master_username
  master_password                 = random_password.master.result
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name

  storage_encrypted         = true
  deletion_protection       = var.environment == "production"
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${var.cluster_name}-docdb-final" : null

  backup_retention_period = var.environment == "production" ? 7 : 1
  preferred_backup_window = "03:00-04:00"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

resource "aws_docdb_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.cluster_name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class

  auto_minor_version_upgrade = true
}
