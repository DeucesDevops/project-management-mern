# Project Management MERN

A full-stack project management application built with the MERN stack (MongoDB, Express, React, Node.js). Manage projects and tasks collaboratively with role-based access control and a modern glassmorphic UI.

## Features

- **Authentication** — JWT-based login/registration with role-based access (Admin, Manager, Member)
- **Project Management** — Create, update, and delete projects with status, priority, deadlines, and team members
- **Task Board** — Kanban-style board with columns: To Do, In Progress, Review, Done
- **Dashboard** — Overview stats for projects and tasks, recent activity widgets
- **Team View** — Browse all registered team members and their roles
- **Profile Settings** — Update name, email, and password

## Tech Stack

| Layer          | Technology                                                      |
|----------------|-----------------------------------------------------------------|
| Frontend       | React 19, TypeScript, Vite, Tailwind CSS, Axios                 |
| Backend        | Node.js, Express 4, TypeScript                                  |
| Database       | MongoDB 7 with Mongoose                                         |
| Cache          | Redis 7                                                         |
| Auth           | JWT (30-day expiry), bcrypt                                     |
| Containers     | Docker, Docker Compose, Nginx                                   |
| Orchestration  | AWS EKS (Kubernetes 1.29), Karpenter, HPA                       |
| IaC            | Terraform (VPC, EKS, IAM modules), S3 + DynamoDB state backend  |
| GitOps / CD    | ArgoCD (automated dev/staging, manual prod gate)                |
| CI             | GitHub Actions (test → build → scan → push → manifest update)  |
| Secrets        | AWS Secrets Manager + External Secrets Operator                 |
| Observability  | Prometheus, Grafana, PrometheusRules, Slack alerts              |

## Project Structure

```
project-management-mern/
├── client/                      # React frontend (Vite + TypeScript)
│   ├── src/
│   │   ├── pages/               # Dashboard, Projects, Tasks, Team, Settings, Auth
│   │   ├── components/          # Layout, Sidebar, Header, ProtectedRoute
│   │   ├── context/             # AuthContext
│   │   └── services/            # Axios API client
│   ├── nginx.conf               # Reverse proxy + SPA routing + security headers
│   └── Dockerfile               # Multi-stage: Node builder → Nginx 1.25-alpine
├── server/                      # Express backend (TypeScript)
│   ├── src/
│   │   ├── models/              # User, Project, Task (Mongoose)
│   │   ├── routes/              # auth, projects, tasks, users
│   │   ├── middleware/          # JWT auth, metrics
│   │   └── config/             # DB connection, logger
│   └── Dockerfile               # Multi-stage: deps → builder → Node 20-alpine
├── docker-compose.yml           # Local dev: mongodb + redis + server + client
└── eks-gitops-platform/         # Production Kubernetes platform
    ├── .github/workflows/       # CI/CD pipelines
    ├── kubernetes/
    │   ├── base/                # Kustomize base manifests
    │   └── overlays/            # Per-environment patches (dev/staging/prod)
    ├── argocd/
    │   ├── projects/            # ArgoCD AppProjects
    │   └── apps/                # ArgoCD Applications
    ├── terraform/
    │   ├── environments/        # dev / staging / prod configs
    │   └── modules/             # vpc, eks, iam reusable modules
    ├── monitoring/alerts/       # PrometheusRules for API, node, pod alerts
    └── scripts/                 # bootstrap.sh, setup-secrets.sh, teardown.sh
```

## Architecture

### Local / Docker Compose

```
Browser
  └── :80  →  Nginx (client container)
                ├── /         → React SPA (static files)
                └── /api/*    → http://server:5001  (reverse proxy)
                                  ├── MongoDB :27017
                                  └── Redis   :6379
```

Two isolated Docker networks keep MongoDB and Redis off the public network:
- `backend`: mongodb, redis, server
- `frontend`: server, client

### Production — AWS EKS

```
Internet
  └── AWS ALB (HTTPS :443, ACM cert)
        ├── /api/*  →  server-svc :5001  →  Server Pods (2–10 replicas, HPA)
        └── /*      →  client-svc :80    →  Client Pods (2–10 replicas, HPA)

Server Pods
  ├── MongoDB StatefulSet  (gp3 PVC, headless service)
  └── Redis StatefulSet    (gp3 PVC, headless service)

Secrets  ←  External Secrets Operator  ←  AWS Secrets Manager
Nodes    ←  Karpenter (demand-driven auto-scaling, bin-packing)
```

VPC layout: 3 availability zones, public subnets (ALB), private subnets (EKS nodes + databases).

## CI/CD Pipeline

```
git push
  │
  ├─ GitHub Actions: app-ci.yaml
  │    ├── [test]            npm ci → lint → test (server) / build (client)
  │    ├── [build-and-push]  Docker build → Trivy CVE scan → push to ECR
  │    │                     Image tag: {branch}-{short-sha}
  │    └── [update-gitops]   kustomize edit image → git commit [skip ci]
  │                          Overlay: main → staging, other → dev
  │
  └─ ArgoCD (watching Git)
       ├── dev      Auto-sync (prune + selfHeal), retry ×5
       ├── staging  Auto-sync, Slack alerts on events
       └── prod     Manual sync only — requires human approval
```

### Image Tagging Strategy

| Environment | Tag format       | Notes                         |
|-------------|------------------|-------------------------------|
| Dev         | `latest`         | Rebuilt on every push         |
| Staging     | `staging-abc1234`| Branch + short SHA, pinned    |
| Prod        | `1.0.0`          | Semantic version, never latest|

## Kubernetes Resources

### Per-Environment Replica Counts

| Workload | Dev | Staging | Prod |
|----------|-----|---------|------|
| Server   | 1   | 2       | 3    |
| Client   | 1   | 2       | 3    |
| HPA max  | 10  | 5       | 10   |

### Resource Limits

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Server    | 200m        | 1000m     | 256Mi          | 512Mi        |
| Client    | 50m         | 200m      | 64Mi           | 128Mi        |
| MongoDB   | 250m        | 1000m     | 512Mi          | 1Gi          |
| Redis     | 100m        | 500m      | 128Mi          | 384Mi        |

### Persistent Volume Sizes

| Volume          | Dev  | Staging | Prod  |
|-----------------|------|---------|-------|
| MongoDB data    | 5Gi  | 20Gi    | 50Gi  |
| MongoDB config  | 1Gi  | 1Gi     | 1Gi   |
| Redis data      | 5Gi  | 5Gi     | 5Gi   |

All volumes use the `gp3` StorageClass (AWS EBS CSI driver).

## Infrastructure as Code (Terraform)

### Modules

| Module | Provisions                                                     |
|--------|----------------------------------------------------------------|
| `vpc`  | Multi-AZ VPC, public/private subnets, NAT gateway, subnet tags |
| `eks`  | EKS cluster (K8s 1.29), managed node groups, IRSA, addons      |
| `iam`  | IRSA roles for ALB Controller, ExternalDNS, Karpenter          |

### State Backend

Remote state is stored in S3 with DynamoDB locking and SSE encryption:

```
s3://your-tfstate-bucket/eks-gitops/{env}/terraform.tfstate
```

### Terraform Pipelines

- **PR to `main`** on `terraform/**` → `terraform-plan.yaml` runs `plan` for all three environments in parallel and posts results as a PR comment.
- **Push to `main`** on `terraform/**` → `terraform-apply.yaml` auto-applies dev, then applies staging after a GitHub environment approval gate.

### Provisioning a New Environment

```bash
cd eks-gitops-platform/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform plan
terraform apply
```

## Secrets Management

Secrets are **never stored in Git**. The flow is:

```
AWS Secrets Manager  (project-management/{env})
        │   1-hour refresh
        ▼
External Secrets Operator
        │
        ▼
Kubernetes Secret  →  Pod environment variables
```

Run the interactive setup script to populate secrets for each environment:

```bash
./eks-gitops-platform/scripts/setup-secrets.sh
```

Keys stored per environment: `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`, `MONGO_DB`, `JWT_SECRET`, `REDIS_PASSWORD`.

## Observability

### Prometheus Alerts

| Alert                   | Condition                       | Severity |
|-------------------------|---------------------------------|----------|
| `APIHighErrorRate`      | 5xx rate > 5% for 2 min         | critical |
| `APIHighLatency`        | p95 latency > 2s for 5 min      | warning  |
| `APIPodDown`            | 0 server replicas for 1 min     | critical |
| `MongoDBDown`           | 0 ready MongoDB pods            | critical |
| `RedisDown`             | 0 ready Redis pods              | critical |
| `PersistentVolumeNearFull` | <15% free for 5 min          | warning  |
| `NodeCPUHighUsage`      | CPU > 85% for 5 min             | warning  |
| `NodeMemoryPressure`    | <15% memory free for 5 min     | critical |
| `PodCrashLooping`       | >3 restarts in 15 min           | critical |

Slack notifications are sent to `#devops-alerts` for staging and production events. Dev alerts are silent.

### Grafana

Grafana is deployed via ArgoCD using the `kube-prometheus-stack` Helm chart. Access it after bootstrapping with:

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

## Bootstrapping the Platform

### Prerequisites

- AWS CLI configured with sufficient IAM permissions
- `kubectl`, `terraform`, `helm`, `argocd` CLIs installed
- EKS cluster provisioned via Terraform (see above)

### Steps

```bash
# 1. Provision infrastructure
cd eks-gitops-platform/terraform/environments/dev
terraform apply

# 2. Populate secrets in AWS Secrets Manager
./eks-gitops-platform/scripts/setup-secrets.sh

# 3. Install ArgoCD and deploy all platform apps
./eks-gitops-platform/scripts/bootstrap.sh eks-gitops-dev us-east-1
```

The bootstrap script:
1. Updates your kubeconfig for the EKS cluster
2. Installs ArgoCD from the stable manifest
3. Applies all ArgoCD AppProjects and Applications
4. Prints the initial admin password and port-forward instructions

ArgoCD then takes over and syncs all workloads from Git automatically.

### Teardown

```bash
./eks-gitops-platform/scripts/teardown.sh dev
```

Destroys all AWS resources for the given environment after an interactive confirmation prompt.

## Getting Started (Local)

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Or: Node.js 20+ and MongoDB 7+ for local development without Docker

### Docker (recommended)

```bash
git clone <repo-url>
cd project-management-mern
cp .env.example .env
# Edit .env — generate JWT_SECRET with: openssl rand -base64 64
docker compose up --build
```

Open [http://localhost](http://localhost).

### Local Development

**Server:**
```bash
cd server
cp ../.env.example .env   # set MONGO_URI, JWT_SECRET, etc.
npm install
npm run dev               # live reload on port 5001
```

**Client:**
```bash
cd client
cp .env.example .env      # VITE_API_URL=http://localhost:5001/api
npm install
npm run dev               # Vite dev server on port 5173
```

## Environment Variables

Root `.env` (Docker Compose / server):

| Variable              | Description                                | Default              |
|-----------------------|--------------------------------------------|----------------------|
| `MONGO_ROOT_USER`     | MongoDB admin username                     | `admin`              |
| `MONGO_ROOT_PASSWORD` | MongoDB admin password                     | —                    |
| `MONGO_DB`            | Database name                              | `project_management` |
| `MONGO_PORT`          | MongoDB port                               | `27017`              |
| `REDIS_PASSWORD`      | Redis password                             | —                    |
| `REDIS_PORT`          | Redis port                                 | `6379`               |
| `JWT_SECRET`          | JWT signing secret (**required**)          | —                    |
| `CLIENT_PORT`         | Nginx container port                       | `80`                 |

Client `client/.env`:

| Variable       | Description          | Default                     |
|----------------|----------------------|-----------------------------|
| `VITE_API_URL` | Backend API base URL | `http://localhost:5001/api` |

## API Reference

### Auth
| Method | Endpoint             | Description         | Auth |
|--------|----------------------|---------------------|------|
| POST   | `/api/auth/register` | Register a new user | No   |
| POST   | `/api/auth/login`    | Login and get JWT   | No   |
| GET    | `/api/auth/me`       | Get current user    | Yes  |
| PUT    | `/api/auth/profile`  | Update profile      | Yes  |

### Projects
| Method | Endpoint                  | Description                     | Auth |
|--------|---------------------------|---------------------------------|------|
| GET    | `/api/projects`           | List user's projects            | Yes  |
| POST   | `/api/projects`           | Create a project                | Yes  |
| GET    | `/api/projects/:id`       | Get project details             | Yes  |
| PUT    | `/api/projects/:id`       | Update a project                | Yes  |
| DELETE | `/api/projects/:id`       | Delete project (cascades tasks) | Yes  |
| GET    | `/api/projects/:id/tasks` | Get tasks for a project         | Yes  |

### Tasks
| Method | Endpoint                | Description             | Auth |
|--------|-------------------------|-------------------------|------|
| GET    | `/api/tasks`            | List all user's tasks   | Yes  |
| POST   | `/api/tasks`            | Create a task           | Yes  |
| GET    | `/api/tasks/:id`        | Get task details        | Yes  |
| PUT    | `/api/tasks/:id`        | Update a task           | Yes  |
| PATCH  | `/api/tasks/:id/status` | Update task status only | Yes  |
| DELETE | `/api/tasks/:id`        | Delete a task           | Yes  |

### Users
| Method | Endpoint      | Description    | Auth |
|--------|---------------|----------------|------|
| GET    | `/api/users`  | List all users | Yes  |
| GET    | `/api/health` | Health check   | No   |

## Data Models

**User** — `name`, `email`, `password` (bcrypt hashed), `role` (admin/manager/member), `avatar`

**Project** — `title`, `description`, `status` (active/completed/on-hold), `priority` (low/medium/high/critical), `owner`, `members[]`, `deadline`

**Task** — `title`, `description`, `status` (todo/in-progress/review/done), `priority`, `project`, `assignee`, `dueDate`

## Scripts

| Location | Command         | Description                     |
|----------|-----------------|---------------------------------|
| `client` | `npm run dev`   | Start Vite dev server           |
| `client` | `npm run build` | TypeScript compile + Vite build |
| `client` | `npm run lint`  | Run ESLint                      |
| `server` | `npm run dev`   | Start server with live reload   |
| `server` | `npm run build` | Compile TypeScript              |
| `server` | `npm start`     | Run compiled server             |

## Security Highlights

- **Non-root containers** — all images run as unprivileged users
- **Zero secrets in Git** — AWS Secrets Manager + External Secrets Operator
- **Trivy CVE scanning** — critical/high vulnerabilities fail the CI build
- **IRSA** — fine-grained IAM roles per Kubernetes service account (ALB Controller, ExternalDNS, Karpenter)
- **Pod Disruption Budgets** — ensures ≥2 server replicas during node drains
- **Nginx security headers** — X-Frame-Options, X-Content-Type-Options, XSS protection, Referrer-Policy
- **Manual production gate** — ArgoCD requires human approval before syncing prod

## License

MIT
