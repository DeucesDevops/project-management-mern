#!/usr/bin/env bash
# Destroys all infrastructure — USE WITH CAUTION
set -euo pipefail

ENV=${1:-"dev"}

echo "WARNING: This will destroy all infrastructure in $ENV."
read -r -p "Type the environment name to confirm: " confirm

if [ "$confirm" != "$ENV" ]; then
  echo "Aborted."
  exit 1
fi

cd terraform/environments/"$ENV"
terraform destroy -auto-approve
