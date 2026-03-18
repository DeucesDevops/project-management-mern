#!/usr/bin/env bash
# Bootstrap script: installs ArgoCD and applies all platform apps
set -euo pipefail

CLUSTER_NAME=${1:-"eks-gitops-dev"}
REGION=${2:-"us-east-1"}

echo "==> Updating kubeconfig for $CLUSTER_NAME..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "==> Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD server..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "==> Applying ArgoCD projects and apps..."
kubectl apply -f argocd/projects/
kubectl apply -f argocd/apps/

echo ""
echo "==> ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "Port-forward:  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "UI:            https://localhost:8080  (admin / password above)"
