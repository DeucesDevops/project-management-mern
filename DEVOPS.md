# Project Management App — DevOps Explained for Beginners

This document walks through every layer of the DevOps setup for this project — from writing code to having it running live on the internet, monitored around the clock.

---

## The Big Picture

```
You write code
     ↓
GitHub Actions tests and packages it    (CI — Continuous Integration)
     ↓
Docker images pushed to AWS ECR         (the warehouse)
     ↓
Trivy checks for security issues        (customs inspection)
     ↓
ArgoCD sees new image tags in Git       (the delivery driver)
     ↓
Kubernetes runs it on AWS EKS           (the destination building)
     ↓
Prometheus + Grafana watch it live      (the security cameras)
```

---

## Layer 1 — Infrastructure: Terraform

**What it is:** Terraform reads `.tf` files and creates AWS cloud resources automatically.
Instead of clicking through the AWS console, you describe what you want and Terraform builds it.

**What it creates for this project:**

| Resource | What it is |
|---|---|
| VPC | A private network in AWS — your isolated space |
| EKS | A Kubernetes cluster — the platform that runs your containers |
| IAM | Roles and permissions — who is allowed to do what |

**File map:**
```
terraform/
├── environments/
│   └── dev/            ← development environment config
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.example
└── modules/
    ├── vpc/            ← VPC, subnets, NAT gateways
    ├── eks/            ← EKS cluster + worker nodes + OIDC
    └── iam/            ← IAM roles for GitHub Actions and EKS
```

**How to use it:**
```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init
terraform plan    # preview
terraform apply   # build (takes ~15 min)
terraform destroy # tear down when done
```

**Multiple environments:** The `environments/` folder is designed for `dev`, `staging`, and `prod` each with their own state — so you can test in dev before promoting to staging.

---

## Layer 2 — Containers: Docker

**What it is:** Docker packages the app and everything it needs into a portable image.
That image runs identically on your laptop, a teammate's machine, or AWS.

**This project's images:**

| Image | Context | Serves |
|---|---|---|
| `pm-server` | `server/` | Express + Mongoose API |
| `pm-client` | `client/` | React SPA via nginx |

**How the client image works differently:**
The server is a Node.js process. The client is different — it's compiled into static HTML/JS/CSS files,
then served by **nginx** (a fast web server). The `VITE_API_URL=/api` build arg tells the React app
where to send API calls at build time (nginx proxies `/api` to the backend).

**Local development:**
```bash
cp .env.example .env      # fill in secrets
docker-compose up         # starts MongoDB, Redis, server, and nginx client
```

---

## Layer 3 — CI/CD: GitHub Actions

**What it is:** GitHub Actions automatically runs a pipeline every time you push code.

**Three workflow files:**

### `pr-checks.yml` — Runs on every Pull Request
```
Install server deps → TypeScript build (catches type errors)
Install client deps → Lint + Vite build (catches import errors)
```

### `ci-cd.yml` — Runs on push to `main`, `staging`, `develop`
```
build-and-push
  ├── Build server image → push to ECR (pm-server)
  └── Build client image → push to ECR (pm-client)
          ↓
trivy-scan (gates gitops update)
  ├── Scan server for CRITICAL/HIGH CVEs
  └── Scan client for CRITICAL/HIGH CVEs
          ↓
gitops-update
  ├── Determine target overlay (main/staging → staging, develop → dev)
  ├── kustomize edit set image (updates the image tag in kustomization.yaml)
  ├── Commit + push to Git
  └── ArgoCD detects the change and deploys automatically
```

### `terraform.yml` — Runs on `terraform/**` changes
```
On PR:   terraform plan → comment the plan on the PR
On push: terraform apply (dev environment only, auto-approved)
```

**Key decisions explained:**

| Decision | Why |
|---|---|
| ECR (AWS Elastic Container Registry) | Private registry that integrates with EKS without extra auth |
| `branch-sha` image tags | Every image is traceable to an exact Git commit AND branch |
| Trivy gates GitOps update | If a critical CVE is found, the kustomization.yaml is never updated |
| Branch → overlay mapping | `develop` → dev overlay, `main` → staging overlay, prod is manual |

**Secrets needed (GitHub → Settings → Secrets):**

| Secret | Value |
|---|---|
| `AWS_ROLE_ARN_CI` | IAM role ARN GitHub can assume via OIDC |

---

## Layer 4 — GitOps: ArgoCD

**What it is:** ArgoCD watches your Git repository. When it sees `kustomization.yaml` change
(new image tag), it automatically syncs the cluster to match.

**Three environments:**

| App | Sync | Who approves |
|---|---|---|
| `project-management-dev` | Automatic | ArgoCD does it on its own |
| `project-management-staging` | Automatic | ArgoCD does it on its own |
| `project-management-prod` | Manual | You run `argocd app sync project-management-prod` |

**Why prod is manual:** Production deployments are too important to automate fully.
You want a human to look at what changed and press the button.

**File:** `argocd/apps/project-management-*.yaml`

**One-time setup:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/apps/project-management-dev.yaml
```

---

## Layer 5 — Kubernetes: Running the App

**What it is:** Kubernetes manages the containers — starts them, restarts crashed ones,
scales them up under load, and routes traffic to healthy ones only.

**File map:**
```
kubernetes/
├── base/                       ← shared definitions for all environments
│   ├── server/                 ← Express API (Deployment, Service, PodDisruptionBudget)
│   ├── client/                 ← React/nginx (Deployment, Service)
│   ├── mongodb/                ← MongoDB StatefulSet + Service
│   ├── redis/                  ← Redis StatefulSet + Service
│   ├── external-secrets/       ← pull secrets from AWS Secrets Manager
│   └── kustomization.yaml
└── overlays/
    ├── dev/                    ← dev-specific image tags and replica counts
    ├── staging/                ← staging-specific overrides
    └── prod/                   ← prod-specific overrides (higher replicas, etc.)
```

**How Kustomize overlays work:**
The `base/` has the full definition. The `overlays/` only contain the *differences*:
```
base: server replicas = 1, image = pm-server:placeholder
staging overlay: image = ECR/pm-server:staging-abc1234
prod overlay: replicas = 3, image = ECR/pm-server:main-xyz9876
```
This avoids copy-pasting the same YAML three times.

**External Secrets (how passwords stay safe):**
```
AWS Secrets Manager holds JWT_SECRET, MONGO_URI, REDIS_URL
          ↓
External Secrets Operator (running in the cluster) pulls them every 1h
          ↓
Kubernetes Secret is created/updated in the namespace
          ↓
Server pod reads the secret as an environment variable
```

Passwords never live in Git. If you need to rotate a secret, update it in AWS Secrets Manager
and External Secrets will propagate it automatically.

**PodDisruptionBudget (server):**
Ensures at least one server pod is always running, even during cluster maintenance or node upgrades.
Kubernetes will not evict the last pod.

---

## Layer 6 — Observability: Prometheus + Grafana + Alertmanager

**What it is:** Once the app is live, this layer watches it 24/7 and alerts you if something goes wrong.

**Alert rules configured** (in `monitoring/alerts/`):

| Alert file | What it watches |
|---|---|
| `project-management-alerts.yaml` | HTTP errors, latency, API availability |
| `pod-alerts.yaml` | Pod restarts, crash loops |
| `node-alerts.yaml` | Node CPU, memory, disk pressure |

**How metrics flow:**
```
Express API (/api/metrics endpoint)
       ↓ prom-client exposes Node.js + HTTP metrics
Prometheus scrapes every 15 seconds
       ↓
Grafana draws charts from Prometheus
       ↓
Alertmanager sends Slack alerts when rules fire
```

**The `/api/metrics` endpoint:**
The server uses `prom-client` to expose metrics in the format Prometheus expects.
Metrics tracked:
- `pm_http_request_duration_seconds` — HTTP request latency histogram (by route, method, status code)
- `pm_nodejs_heap_size_used_bytes` — Node.js memory usage
- `pm_nodejs_eventloop_lag_seconds` — Event loop responsiveness
- `pm_process_cpu_seconds_total` — CPU usage

---

## End-to-End Deploy Walkthrough

Here's what happens from `git push origin develop` to running in the dev cluster:

```
1. git push origin develop
2. GitHub Actions triggers ci-cd.yml
3. Docker builds server + client images
4. Images pushed to ECR: 123456789.dkr.ecr.us-east-1.amazonaws.com/pm-server:develop-abc12345
5. Trivy scans both images — stops if CRITICAL/HIGH CVEs found
6. kustomize edit set image updates kubernetes/overlays/dev/kustomization.yaml
7. git commit + push → ArgoCD detects the change within 3 minutes
8. ArgoCD applies the updated manifests to the dev namespace
9. Kubernetes pulls new images, starts new pods
10. Health probes on /api/health pass → traffic shifts to new pods
11. Old pods terminate gracefully
12. Prometheus begins collecting metrics from new pods
13. Grafana charts reflect the new deployment
```

For **prod**, steps 6-8 are the same but ArgoCD stops and waits for manual approval:
```bash
argocd app sync project-management-prod
```

---

## Key Differences vs Other Projects in This Portfolio

| Feature | This project | grocery-tracker | Inkframe |
|---|---|---|---|
| Registry | AWS ECR | GHCR (free) | AWS ECR |
| Database | MongoDB | PostgreSQL | PostgreSQL |
| K8s structure | base + overlays (3 environments) | flat (1 environment) | flat (1 environment) |
| Frontend serving | nginx in container | Next.js standalone | Next.js standalone |
| ArgoCD sync (prod) | Manual approval | Auto | Auto |

---

## Glossary

| Term | Plain English |
|---|---|
| **Container** | A packaged app that runs the same everywhere |
| **Image** | The recipe for a container (stored in ECR) |
| **ECR** | AWS's private Docker image registry |
| **EKS** | AWS's managed Kubernetes service |
| **Pod** | A running container inside Kubernetes |
| **StatefulSet** | Like a Deployment but for apps that need stable storage (databases) |
| **Kustomize** | Patches K8s YAML without copying it (used for environment overlays) |
| **Overlay** | Environment-specific overrides on top of a shared base |
| **ArgoCD** | Keeps the cluster in sync with Git automatically |
| **OIDC** | Lets GitHub Actions authenticate to AWS without storing passwords |
| **External Secrets** | Pulls passwords from AWS Secrets Manager into K8s |
| **PDB** | PodDisruptionBudget — guarantees minimum pods stay running during maintenance |
| **Prometheus** | Collects and stores metrics numbers over time |
| **Grafana** | Charts and dashboards built from Prometheus data |
