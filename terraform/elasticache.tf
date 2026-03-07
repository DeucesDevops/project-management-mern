###############################################################################
# Amazon ElastiCache Redis — optional managed cache
# Set enable_elasticache = true in terraform.tfvars to provision
###############################################################################

resource "random_password" "redis_auth" {
  count   = var.enable_elasticache ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  count = var.enable_elasticache ? 1 : 0
  name  = "${local.cluster_name}/redis/auth-token"
}

resource "aws_secretsmanager_secret_version" "redis" {
  count         = var.enable_elasticache ? 1 : 0
  secret_id     = aws_secretsmanager_secret.redis[0].id
  secret_string = random_password.redis_auth[0].result
}

resource "aws_elasticache_subnet_group" "main" {
  count      = var.enable_elasticache ? 1 : 0
  name       = "${local.cluster_name}-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_elasticache ? 1 : 0

  replication_group_id = "${local.cluster_name}-redis"
  description          = "Redis cluster for ${local.cluster_name}"

  engine               = "redis"
  engine_version       = "7.2"
  node_type            = var.elasticache_node_type
  num_cache_clusters   = var.elasticache_num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.elasticache[0].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth[0].result

  automatic_failover_enabled = var.elasticache_num_cache_nodes > 1
  multi_az_enabled           = var.elasticache_num_cache_nodes > 1

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
  name              = "/aws/elasticache/${local.cluster_name}-redis/slow-log"
  retention_in_days = 14
}
