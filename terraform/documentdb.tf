###############################################################################
# Amazon DocumentDB (MongoDB-compatible) — optional managed database
# Set enable_documentdb = true in terraform.tfvars to provision
###############################################################################

resource "random_password" "docdb_master" {
  count   = var.enable_documentdb ? 1 : 0
  length  = 32
  special = false # DocumentDB password cannot contain certain special chars
}

resource "aws_secretsmanager_secret" "docdb" {
  count = var.enable_documentdb ? 1 : 0
  name  = "${local.cluster_name}/docdb/master-password"
}

resource "aws_secretsmanager_secret_version" "docdb" {
  count     = var.enable_documentdb ? 1 : 0
  secret_id = aws_secretsmanager_secret.docdb[0].id
  secret_string = jsonencode({
    username = var.docdb_master_username
    password = random_password.docdb_master[0].result
  })
}

resource "aws_docdb_subnet_group" "main" {
  count      = var.enable_documentdb ? 1 : 0
  name       = "${local.cluster_name}-docdb-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_docdb_cluster_parameter_group" "main" {
  count  = var.enable_documentdb ? 1 : 0
  family = "docdb5.0"
  name   = "${local.cluster_name}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

resource "aws_docdb_cluster" "main" {
  count = var.enable_documentdb ? 1 : 0

  cluster_identifier              = "${local.cluster_name}-docdb"
  engine                          = "docdb"
  engine_version                  = "5.0.0"
  master_username                 = var.docdb_master_username
  master_password                 = random_password.docdb_master[0].result
  db_subnet_group_name            = aws_docdb_subnet_group.main[0].name
  vpc_security_group_ids          = [aws_security_group.docdb[0].id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main[0].name

  storage_encrypted       = true
  deletion_protection     = var.environment == "production"
  skip_final_snapshot     = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${local.cluster_name}-docdb-final" : null

  backup_retention_period = var.environment == "production" ? 7 : 1
  preferred_backup_window = "03:00-04:00"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

resource "aws_docdb_cluster_instance" "instances" {
  count = var.enable_documentdb ? var.docdb_instance_count : 0

  identifier         = "${local.cluster_name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main[0].id
  instance_class     = var.docdb_instance_class

  auto_minor_version_upgrade = true
}
