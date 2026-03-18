# EKS GitOps Platform

> Production-grade Kubernetes platform on AWS — provisioned with Terraform, delivered via GitOps with ArgoCD, and observed with Prometheus & Grafana. Deploys a full MERN stack application across dev, staging, and prod environments.

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-7B42BC?logo=terraform)](https://terraform.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes)](https://kubernetes.io)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)](https://argoproj.github.io/cd)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks)

---

## Architecture Overview

```
  Developer
     │
     │  git push
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│  GitHub                                                              │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  GitHub Actions CI                                           │    │
│  │  lint → test → docker build → trivy scan → push ECR         │    │
│  │  → kustomize edit set image → git push [skip ci]            │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
└─────────────────────────────┼───────────────────────────────────────┘
                              │  image tag commit triggers ArgoCD
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  AWS Account                                                         │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  VPC  (10.0.0.0/16)                                          │   │
│  │                                                              │   │
│  │  Public Subnets                  Private Subnets             │   │
│  │  ┌──────────────────┐           ┌─────────────────────────┐ │   │
│  │  │  ALB (Ingress)   │           │  EKS Cluster            │ │   │
│  │  │  NAT Gateways    │           │                         │ │   │
│  │  └──────────────────┘           │  ┌─────────────────┐   │ │   │
│  │                                 │  │  system nodes   │   │ │   │
│  │  ┌──────────────────┐           │  │  ArgoCD         │   │ │   │
│  │  │  ECR             │◄──pull────│  │  Prometheus     │   │ │   │
│  │  │  (container      │           │  │  cert-manager   │   │ │   │
│  │  │   registry)      │           │  └─────────────────┘   │ │   │
│  │  └──────────────────┘           │                         │ │   │
│  │                                 │  ┌─────────────────┐   │ │   │
│  │  ┌──────────────────┐           │  │ workload nodes  │   │ │   │
│  │  │  Secrets Manager │◄──ESO─────│  │  client (React) │   │ │   │
│  │  │  JWT / DB creds  │           │  │  server (API)   │   │ │   │
│  │  └──────────────────┘           │  │  mongodb        │   │ │   │
│  │                                 │  │  redis          │   │ │   │
│  │  ┌──────────────────┐           │  └─────────────────┘   │ │   │
│  │  │  S3 + DynamoDB   │           │                         │ │   │
│  │  │  (Terraform      │           │  Karpenter auto-scales  │ │   │
│  │  │   remote state)  │           │  nodes on demand        │ │   │
│  │  └──────────────────┘           └─────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### GitOps Delivery Flow

```
Git (source of truth)
       │
       │  ArgoCD polls every 3 minutes
       ▼
  ArgoCD detects diff
       │
       ├── dev / staging  →  automatic sync (prune + self-heal)
       │
       └── prod           →  manual approval required
                                 argocd app sync project-management-prod
```

---

## Stack

| Layer | Tool | Purpose |
|---|---|---|
| Infrastructure | Terraform + AWS | VPC, EKS, IAM, ECR, S3 |
| Container Runtime | EKS (Kubernetes 1.29) | Managed control plane |
| Node Autoscaling | Karpenter | Provision nodes on demand, bin-pack efficiently |
| GitOps | ArgoCD | Continuous delivery — Git is the only deploy mechanism |
| Secrets | AWS Secrets Manager + External Secrets Operator | Zero plaintext secrets in Git |
| Ingress | AWS ALB Controller | L7 load balancing, HTTPS termination |
| DNS | external-dns | Automatic Route53 record management |
| TLS | cert-manager | Automated certificate lifecycle |
| Observability | Prometheus + Grafana | Metrics, dashboards, alerting |
| CI | GitHub Actions | Test, build, scan, push, update manifests |
| Security Scanning | Trivy | Block CRITICAL/HIGH CVEs before they reach the cluster |
| Config Management | Kustomize | DRY manifests with per-environment patches |

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── app-ci.yaml             # Build → scan → push → update GitOps manifests
│       ├── terraform-plan.yaml     # PR: plan all environments, post results as comment
│       └── terraform-apply.yaml    # Merge to main: apply dev (staging manually gated)
│
├── terraform/
│   ├── modules/
│   │   ├── vpc/                    # VPC, subnets, NAT, subnet tags for EKS + Karpenter
│   │   ├── eks/                    # EKS cluster, managed node groups, addons, IRSA
│   │   └── iam/                    # IRSA roles: ALB controller, ExternalDNS, Karpenter
│   └── environments/
│       ├── dev/                    # main.tf, variables.tf, tfvars.example
│       ├── staging/
│       └── prod/
│
├── argocd/
│   ├── projects/
│   │   ├── platform.yaml           # Cluster-wide infra apps (unrestricted)
│   │   └── apps.yaml               # Application workloads (namespace-scoped)
│   └── apps/
│       ├── monitoring.yaml         # kube-prometheus-stack
│       ├── karpenter.yaml          # Node autoscaler
│       ├── cert-manager.yaml       # TLS automation
│       ├── project-management-dev.yaml
│       ├── project-management-staging.yaml
│       └── project-management-prod.yaml    # No automated sync — manual gate
│
├── kubernetes/
│   ├── base/                       # Environment-agnostic manifests
│   │   ├── external-secrets/       # ClusterSecretStore + ExternalSecret
│   │   ├── mongodb/                # StatefulSet + dual PVCs + headless + ClusterIP service
│   │   ├── redis/                  # StatefulSet + PVC + password injected from secret
│   │   ├── server/                 # Deployment + HPA (2→10 pods) + PodDisruptionBudget
│   │   └── client/                 # Deployment + Service + ALB Ingress (HTTPS redirect)
│   └── overlays/
│       ├── dev/                    # 1 replica, 5Gi PVC, latest tag, auto-sync
│       ├── staging/                # 2 replicas, 20Gi PVC, pinned SHA tag, auto-sync
│       └── prod/                   # 3 replicas, 50Gi PVC, semver tag, manual sync
│
├── monitoring/
│   └── alerts/
│       ├── node-alerts.yaml        # CPU, memory, disk pressure
│       ├── pod-alerts.yaml         # CrashLoopBackOff, NotReady
│       └── project-management-alerts.yaml  # API error rate, latency, DB down
│
└── scripts/
    ├── bootstrap.sh                # Install ArgoCD + apply all platform apps
    ├── setup-secrets.sh            # Create secrets in AWS Secrets Manager interactively
    └── teardown.sh                 # Destroy infrastructure (confirmation required)
```

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| AWS CLI | v2 | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Terraform | >= 1.6 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| kubectl | >= 1.29 | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Helm | >= 3.x | [helm.sh](https://helm.sh/docs/intro/install/) |
| ArgoCD CLI | latest | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| kustomize | >= 5.x | [kubectl.docs.kubernetes.io](https://kubectl.docs.kubernetes.io/installation/kustomize/) |

AWS permissions: `AdministratorAccess` for initial setup. Scope down after bootstrapping.

---

## Getting Started

### 1. Bootstrap Terraform state backend

```bash
# S3 bucket for remote state
aws s3api create-bucket \
  --bucket your-tfstate-bucket \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket your-tfstate-bucket \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket your-tfstate-bucket \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update the bucket name in `terraform/environments/dev/main.tf` backend block.

### 2. Provision the EKS cluster

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars  # fill in your values

terraform init
terraform plan    # review before applying
terraform apply
```

Provisions: VPC + subnets, EKS cluster, managed node groups, IRSA roles for ALB controller / ExternalDNS / Karpenter, and all EKS addons (CoreDNS, kube-proxy, vpc-cni, ebs-csi-driver).

### 3. Create secrets in AWS Secrets Manager

```bash
./scripts/setup-secrets.sh
```

Interactively creates secrets per environment. External Secrets Operator will pull these into the cluster automatically. The secret structure created:

```json
{
  "MONGO_ROOT_USER":     "...",
  "MONGO_ROOT_PASSWORD": "...",
  "MONGO_DB":            "project_management",
  "JWT_SECRET":          "...",
  "REDIS_PASSWORD":      "..."
}
```

Paths: `project-management/dev`, `project-management/staging`, `project-management/prod`.

### 4. Bootstrap ArgoCD and all platform apps

```bash
./scripts/bootstrap.sh eks-gitops-dev us-east-1
```

Installs ArgoCD and applies all `argocd/apps/` manifests. ArgoCD then self-manages everything — Karpenter, cert-manager, Prometheus/Grafana, and the application itself are all deployed automatically via GitOps.

### 5. Access the ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Open https://localhost:8080 — login with `admin` and the password above.

### 6. Replace placeholder values

| Placeholder | File(s) | Replace with |
|---|---|---|
| `YOUR_ECR_REPO` | `kubernetes/base/*/deployment.yaml` | Your ECR registry URL |
| `YOUR_GITHUB_USERNAME` | `argocd/apps/*.yaml` | Your GitHub username or org |
| `YOUR_ACM_CERT_ARN` | `kubernetes/base/client/service.yaml` | Your ACM certificate ARN |
| `ACCOUNT_ID` | `kubernetes/overlays/*/kustomization.yaml` | Your 12-digit AWS account ID |
| `yourdomain.com` | `kubernetes/overlays/*/kustomization.yaml` | Your domain |

---

## Deployment Flow

### Application pipeline (every code push)

```
git push
    │
    ├── lint + unit tests
    ├── docker build (server + client)
    ├── trivy scan — blocks on CRITICAL or HIGH CVEs
    ├── push images to ECR with branch-sha tag
    ├── kustomize edit set image (updates overlay kustomization.yaml)
    ├── git commit + push manifest change [skip ci]
    │
    └── ArgoCD detects manifest diff → syncs to cluster
```

### Environment promotion

| Branch | Deploys to | Sync |
|---|---|---|
| `develop` | dev | Automatic |
| `main` | staging | Automatic |
| Manual | prod | **Explicit approval** |

Promoting to prod:

```bash
# Pin a specific image tag in the prod overlay first
cd kubernetes/overlays/prod
kustomize edit set image YOUR_ECR_REPO/pm-server=YOUR_ECR_REPO/pm-server:1.2.0
kustomize edit set image YOUR_ECR_REPO/pm-client=YOUR_ECR_REPO/pm-client:1.2.0
git commit -am "chore(deploy): promote v1.2.0 to prod"
git push

# Then manually trigger the sync
argocd app sync project-management-prod
```

### Infrastructure changes

PRs touching `terraform/**` automatically post a plan per environment as a PR comment. Merge to `main` applies dev. Staging and prod require a GitHub environment approval gate before apply runs.

---

## Observability

### Grafana

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
# Default: admin / prom-operator  (change this immediately)
```

### Alert reference

| Alert | Severity | Condition |
|---|---|---|
| `NodeCPUHighUsage` | warning | CPU > 85% for 5m |
| `NodeMemoryPressure` | critical | Available memory < 15% for 5m |
| `NodeDiskPressure` | warning | Root filesystem < 20% free |
| `PodCrashLooping` | critical | > 3 restarts in 15m |
| `PodNotReady` | warning | Not ready for 10m |
| `APIHighErrorRate` | critical | 5xx rate > 5% for 2m |
| `APIHighLatency` | warning | p95 latency > 2s for 5m |
| `APIPodDown` | critical | 0 available server replicas |
| `MongoDBDown` | critical | 0 ready MongoDB replicas |
| `RedisDown` | critical | 0 ready Redis replicas |
| `PersistentVolumeNearFull` | warning | PVC < 15% space remaining |

---

## Security Design

**No secrets in Git.** All credentials live in AWS Secrets Manager. External Secrets Operator pulls them into Kubernetes Secrets on a 1-hour refresh cycle. If a secret rotates in AWS, the cluster picks it up automatically.

**IRSA over node-level IAM.** Every AWS-integrated component (ALB controller, ExternalDNS, Karpenter, ESO) has its own fine-grained IAM role bound to its Kubernetes service account via OIDC. No broad permissions on the node IAM role.

**Non-root containers.** All pods run with `runAsNonRoot: true` and explicit `runAsUser` values.

**CVE blocking in CI.** Trivy scans every image before it reaches ECR. Pipelines fail hard on CRITICAL or HIGH severity findings — nothing untested reaches the cluster.

**Prod is never auto-deployed.** The prod ArgoCD Application intentionally has no `automated` sync policy. Every production deployment is a deliberate, manual action with a clear audit trail.

**PodDisruptionBudget.** The API maintains a minimum of 2 available replicas during node drains or rolling updates, ensuring zero downtime during cluster maintenance.

---

## Environment Comparison

| | dev | staging | prod |
|---|---|---|---|
| Server replicas | 1 | 2 | 3 |
| Client replicas | 1 | 2 | 3 |
| HPA ceiling | 10 | 5 | 10 |
| HPA CPU target | 70% | 70% | 60% |
| MongoDB PVC | 5Gi | 20Gi | 50Gi |
| ArgoCD sync | Automatic | Automatic | **Manual** |
| Image tag strategy | `latest` | `branch-sha` | `semver` |
| AWS secret path | `/dev` | `/staging` | `/prod` |

---

## Useful Commands

```bash
# View all ArgoCD app statuses
argocd app list

# Force sync an app
argocd app sync project-management-dev

# Watch a rollout in real time
kubectl rollout status deployment/server -n app-project-management

# Check External Secrets are syncing
kubectl get externalsecret -n app-project-management

# Check HPA status
kubectl get hpa -n app-project-management

# Get the ALB DNS name (before DNS is configured)
kubectl get ingress -n app-project-management

# Tail API server logs
kubectl logs -f deployment/server -n app-project-management

# Check Karpenter is provisioning nodes correctly
kubectl get nodeclaim

# Destroy dev environment
./scripts/teardown.sh dev
```

---

## Skills Demonstrated

| Area | What's covered |
|---|---|
| **Terraform** | Modular IaC, remote state with locking, multi-environment, IRSA, provider tagging strategy |
| **Kubernetes** | Deployments, StatefulSets, Services, Ingress, HPA, PDB, resource limits, health probes, security contexts |
| **GitOps** | ArgoCD Applications + AppProjects, automated + gated sync, self-healing, drift detection |
| **AWS** | EKS, VPC, ALB, ECR, Secrets Manager, IAM OIDC, S3, DynamoDB, Karpenter node provisioning |
| **CI/CD** | GitHub Actions, multi-stage pipelines, Docker layer caching, image promotion strategy |
| **Security** | Trivy scanning, IRSA least-privilege, non-root containers, zero secrets in Git, ESO rotation |
| **Observability** | Prometheus, Grafana, PrometheusRules, infrastructure + application-level alerting |

---

## License

MIT
