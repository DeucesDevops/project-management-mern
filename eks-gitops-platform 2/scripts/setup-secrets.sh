#!/usr/bin/env bash
# Creates the required secrets in AWS Secrets Manager for each environment.
# Run this once before deploying — External Secrets Operator will pull from here.
set -euo pipefail

AWS_REGION=${AWS_REGION:-"us-east-1"}

create_secret() {
  local ENV=$1
  local SECRET_NAME="project-management/${ENV}"

  echo "==> Creating/updating secret: $SECRET_NAME"

  # Prompt for values (never hardcode secrets in scripts)
  read -r -p "  MONGO_ROOT_USER [$ENV]: "   MONGO_USER
  read -r -s -p "  MONGO_ROOT_PASSWORD [$ENV]: " MONGO_PASS; echo
  read -r -p "  MONGO_DB [$ENV]: "           MONGO_DB
  read -r -s -p "  JWT_SECRET [$ENV]: "      JWT_SECRET; echo
  read -r -s -p "  REDIS_PASSWORD [$ENV]: "  REDIS_PASS; echo

  SECRET_JSON=$(jq -n \
    --arg u  "$MONGO_USER" \
    --arg p  "$MONGO_PASS" \
    --arg db "$MONGO_DB" \
    --arg j  "$JWT_SECRET" \
    --arg r  "$REDIS_PASS" \
    '{
      MONGO_ROOT_USER:     $u,
      MONGO_ROOT_PASSWORD: $p,
      MONGO_DB:            $db,
      JWT_SECRET:          $j,
      REDIS_PASSWORD:      $r
    }'
  )

  # Create or update
  if aws secretsmanager describe-secret \
      --secret-id "$SECRET_NAME" \
      --region "$AWS_REGION" &>/dev/null; then
    aws secretsmanager put-secret-value \
      --secret-id "$SECRET_NAME" \
      --secret-string "$SECRET_JSON" \
      --region "$AWS_REGION"
    echo "  Updated existing secret."
  else
    aws secretsmanager create-secret \
      --name "$SECRET_NAME" \
      --description "Project Management app secrets — $ENV" \
      --secret-string "$SECRET_JSON" \
      --region "$AWS_REGION"
    echo "  Created new secret."
  fi
}

echo "========================================"
echo "  Project Management — Secrets Setup"
echo "========================================"
echo ""
echo "This will create secrets in AWS Secrets Manager."
echo "Region: $AWS_REGION"
echo ""

for ENV in dev staging prod; do
  read -r -p "Configure secrets for '$ENV'? [y/N] " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    create_secret "$ENV"
    echo ""
  fi
done

echo "Done. External Secrets Operator will sync these into Kubernetes automatically."
echo ""
echo "Verify with:"
echo "  kubectl get externalsecret -n app-project-management"
echo "  kubectl get secret project-management-secrets -n app-project-management"
