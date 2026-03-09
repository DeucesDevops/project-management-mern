###############################################################################
# ElastiCache Redis Module — optional managed cache
###############################################################################

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "this" {
  count       = var.enable_elasticache ? 1 : 0
  name        = "${var.cluster_name}-elasticache-sg"
  description = "Security group for ElastiCache — allow access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
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
resource "random_password" "auth_token" {
  count   = var.enable_elasticache ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "this" {
  count = var.enable_elasticache ? 1 : 0
  name  = "${var.cluster_name}/redis/auth-token"
}

resource "aws_secretsmanager_secret_version" "this" {
  count         = var.enable_elasticache ? 1 : 0
  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = random_password.auth_token[0].result
}

# ── Cluster ───────────────────────────────────────────────────────────────────
resource "aws_elasticache_subnet_group" "this" {
  count      = var.enable_elasticache ? 1 : 0
  name       = "${var.cluster_name}-redis-subnet"
  subnet_ids = var.private_subnets
}

resource "aws_elasticache_replication_group" "this" {
  count = var.enable_elasticache ? 1 : 0

  replication_group_id = "${var.cluster_name}-redis"
  description          = "Redis cluster for ${var.cluster_name}"

  engine               = "redis"
  engine_version       = "7.2"
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this[0].name
  security_group_ids = [aws_security_group.this[0].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token[0].result

  automatic_failover_enabled = var.num_cache_nodes > 1
  multi_az_enabled           = var.num_cache_nodes > 1

  apply_immediately = var.environment != "production"

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log[0].name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  count             = var.enable_elasticache ? 1 : 0
  name              = "/aws/elasticache/${var.cluster_name}-redis/slow-log"
  retention_in_days = 14
}
