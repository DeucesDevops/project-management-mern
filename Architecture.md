# Architecture: Docker + Kubernetes Production Deployment

## Overview

This MERN stack app (React 19 + Vite client, Express + TypeScript server, MongoDB Atlas) is containerized and deployed to a VPS running kubeadm Kubernetes. The server already has all production prerequisites built in: SIGTERM graceful shutdown, `/api/health` health check, Prometheus metrics at `/api/metrics`, Pino JSON logging, Helmet security headers, and configurable CORS. No source changes are required — only infrastructure files need to be created.

**Target stack:**
- Kubernetes: kubeadm (full K8s) on a VPS
- Database: MongoDB Atlas (external, no in-cluster DB)
- Image registry: Docker Hub
- CI/CD: GitHub Actions
- TLS: nginx-ingress + cert-manager + Let's Encrypt

---

## Infrastructure Files (17 total)

```
project-management-mern/
├── docker-compose.yml                    # Local integration testing
├── server/
│   ├── Dockerfile                        # Multi-stage: builder + runner
│   └── .dockerignore
├── client/
│   ├── Dockerfile                        # Multi-stage: builder + nginx runner
│   ├── nginx.conf                        # SPA routing, gzip, caching
│   └── .dockerignore
├── k8s/
│   ├── namespace.yaml
│   ├── server/
│   │   ├── configmap.yaml               # Non-secret env vars
│   │   ├── secret.yaml                  # Template only — no real values
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── client/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── ingress/
│       ├── clusterissuer.yaml           # Let's Encrypt ACME issuer
│       └── ingress.yaml                 # TLS + routing rules
└── .github/workflows/deploy.yml         # CI/CD pipeline
```

---

## Docker

### `server/Dockerfile` — Multi-stage build
- **Stage `builder`**: `node:22-alpine` — install all deps (`npm ci`), compile TypeScript to `dist/` via `npm run build`
- **Stage `runner`**: `node:22-alpine` — install production deps only (`npm ci --omit=dev`), copy `dist/` from builder, run as non-root `node` user, expose 5001
- `HEALTHCHECK` pings `GET /api/health` with curl every 30s

### `client/Dockerfile` — Multi-stage build
- **Stage `builder`**: `node:22-alpine` — declare `ARG VITE_API_URL` forwarded to `ENV` (Vite bakes env vars into the JS bundle at build time), `npm ci`, `npm run build` → `dist/`
- **Stage `runner`**: `nginx:stable-alpine` — copy `dist/` to `/usr/share/nginx/html`, copy custom `nginx.conf`, expose 80

### `client/nginx.conf`
- `try_files $uri $uri/ /index.html` — React Router SPA fallback
- `index.html` served with `Cache-Control: no-store` — prevents stale HTML after deploys
- Vite fingerprinted assets (`*.js`, `*.css`) cached `1y` with `immutable`
- Gzip compression for text, JS, and JSON
- `GET /healthz` returns 200 — used by Kubernetes liveness probes
- `server_tokens off` — hides nginx version

### `docker-compose.yml` — Local testing only
- `server` service: builds from `./server`, port `5001:5001`, reads secrets from `server/.env` via `env_file`
- `client` service: builds from `./client` with `VITE_API_URL=http://localhost:5001/api`, port `5173:80`, waits for server healthcheck
- No MongoDB service — Atlas is always used

---

## Kubernetes Manifests

### Namespace
All resources live in the `project-management` namespace.

### Server
| Manifest | Purpose |
|---|---|
| `configmap.yaml` | Non-secret config: `PORT=5001`, `NODE_ENV=production`, `LOG_LEVEL=info`, `CORS_ORIGIN` |
| `secret.yaml` | **Template only** — real secret created with `kubectl create secret generic` (never committed) |
| `deployment.yaml` | 2 replicas, RollingUpdate (`maxSurge: 1`, `maxUnavailable: 0`), health probes, resource limits |
| `service.yaml` | ClusterIP on port 5001 |
| `hpa.yaml` | min 2 / max 5 replicas, scale at 70% CPU |

**Deployment details:**
- `envFrom` maps both `server-config` ConfigMap and `server-secret` Secret as environment variables
- Resources: requests `100m CPU / 128Mi RAM`, limits `500m CPU / 512Mi RAM`
- Liveness probe: `GET /api/health` port 5001, `initialDelay: 30s` (Atlas connection pool warmup)
- Readiness probe: `GET /api/health` port 5001, `initialDelay: 10s`
- `terminationGracePeriodSeconds: 30` — matches the server's 10s forced shutdown timeout with buffer
- `preStop` sleep 5s — drains in-flight connections before SIGTERM is sent
- Pod anti-affinity — spreads replicas across nodes

**HPA scaling behavior:**
- Scale-down: 5-min stabilization window, max 1 pod/min (prevents flapping)
- Scale-up: 1-min window, max 2 pods/min (fast response to traffic spikes)

### Client
| Manifest | Purpose |
|---|---|
| `deployment.yaml` | 2 replicas, RollingUpdate, nginx liveness on `/healthz`, no env vars (baked at build time) |
| `service.yaml` | ClusterIP on port 80 |

- Resources: requests `50m CPU / 64Mi RAM`, limits `200m CPU / 128Mi RAM`

### Ingress
| Manifest | Purpose |
|---|---|
| `clusterissuer.yaml` | Let's Encrypt prod ACME ClusterIssuer with HTTP01 + nginx solver |
| `ingress.yaml` | TLS termination, HTTP→HTTPS redirect, routing rules |

**Routing:**
- `yourdomain.com` → client service port 80
- `api.yourdomain.com` → server service port 5001

**Ingress annotations:** SSL redirect, proxy body size 10m, proxy timeouts 60s, real client IP forwarding.

---

## CI/CD Pipeline (GitHub Actions)

Three jobs triggered on every push to `main`:

1. **`build-push-server`** — Build server Docker image, push to Docker Hub tagged `sha-<short-sha>` and `latest`, using GHA layer cache
2. **`build-push-client`** — Same for client; passes `VITE_API_URL` GitHub secret as `--build-arg` (never appears in logs)
3. **`deploy`** (runs after both build jobs succeed):
   - Decodes `KUBECONFIG` secret to configure `kubectl`
   - `kubectl set image` on both deployments using the immutable SHA tag
   - `kubectl rollout status --timeout=120s` blocks until rollout succeeds or fails

### GitHub Secrets Required

| Secret | Value |
|---|---|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token (not password) |
| `VITE_API_URL` | `https://api.yourdomain.com/api` |
| `KUBECONFIG` | Base64-encoded kubeconfig from the VPS (see below) |

**Generating `KUBECONFIG` secret (run on the VPS):**
```bash
# Ensure the server: field uses the public IP, not 127.0.0.1
cat ~/.kube/config | base64 -w 0
```
Paste the output as the `KUBECONFIG` secret value in GitHub.

---

## One-Time VPS Setup

Run these once on the VPS before the first deployment.

```bash
# 1. Initialize the cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<VPS_PUBLIC_IP>
mkdir -p $HOME/.kube && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 2. Install CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
# Allow pods on the control-plane node (single-node VPS)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# 3. Install metrics-server (required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Patch for single-node VPS without valid kubelet certs
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 4. Install nginx-ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# 5. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

# 6. DNS: point both A records at the VPS public IP
#    yourdomain.com     A  <VPS_PUBLIC_IP>
#    api.yourdomain.com A  <VPS_PUBLIC_IP>

# 7. MongoDB Atlas: add VPS public IP to Network Access whitelist
#    Atlas dashboard → Security → Network Access → + Add IP Address
```

---

## First Deployment (`kubectl apply` Order)

```bash
# 1. Namespace first — everything else depends on it
kubectl apply -f k8s/namespace.yaml

# 2. ClusterIssuer (cluster-scoped, no namespace)
kubectl apply -f k8s/ingress/clusterissuer.yaml

# 3. Create real secret imperatively — NEVER commit actual values to git
kubectl create secret generic server-secret \
  --namespace project-management \
  --from-literal=MONGO_URI='mongodb+srv://user:pass@cluster.mongodb.net/dbname?retryWrites=true&w=majority' \
  --from-literal=JWT_SECRET='your-minimum-32-character-random-secret'

# 4. Apply server resources
kubectl apply -f k8s/server/configmap.yaml
kubectl apply -f k8s/server/deployment.yaml
kubectl apply -f k8s/server/service.yaml

# 5. Apply client resources
kubectl apply -f k8s/client/deployment.yaml
kubectl apply -f k8s/client/service.yaml

# 6. Apply HPA (metrics-server must be running)
kubectl apply -f k8s/server/hpa.yaml

# 7. Apply Ingress last — triggers ACME certificate request
kubectl apply -f k8s/ingress/ingress.yaml
```

**To update the secret later:**
```bash
kubectl create secret generic server-secret \
  --namespace project-management \
  --from-literal=MONGO_URI='...' \
  --from-literal=JWT_SECRET='...' \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Verification

```bash
# All pods running
kubectl get pods -n project-management

# Deployments rolled out
kubectl rollout status deployment/project-management-server -n project-management
kubectl rollout status deployment/project-management-client -n project-management

# TLS certificate issued (READY=True, allow 2-5 min after ingress apply)
kubectl get certificate -n project-management

# API health check — expect {"status":"ok","db":"connected"}
curl -s https://api.yourdomain.com/api/health | python3 -m json.tool

# HTTP → HTTPS redirect
curl -sI http://yourdomain.com | grep -i location
# Expected: Location: https://yourdomain.com/

# SPA routing — must return 200, not 404
curl -sI https://yourdomain.com/projects

# HPA is active with metrics
kubectl get hpa -n project-management

# View structured JSON logs (Pino in production mode)
kubectl logs -n project-management -l app=project-management-server --tail=50 -f
```

---

## Rollback

```bash
# Roll back to previous revision
kubectl rollout undo deployment/project-management-server -n project-management
kubectl rollout undo deployment/project-management-client -n project-management

# Roll back to a specific revision
kubectl rollout history deployment/project-management-server -n project-management
kubectl rollout undo deployment/project-management-server --to-revision=2 -n project-management
```

---

## Key Notes

- **No source changes needed** — the server already handles SIGTERM, health checks, and JSON logging correctly for Kubernetes
- **`VITE_API_URL` is build-time only** — changing the API domain requires rebuilding the client image (update the GitHub secret and push to `main`)
- **`/api/metrics` is publicly exposed** — block it at ingress level with a `server-snippet` annotation if needed:
  ```yaml
  nginx.ingress.kubernetes.io/server-snippet: |
    location /api/metrics { deny all; return 403; }
  ```
- **`k8s/server/secret.yaml` is a template only** — never commit real secrets; always use `kubectl create secret generic`
- **Pino logging**: `NODE_ENV=production` in the ConfigMap disables `pino-pretty` and emits raw JSON — correct for log aggregation tools (Loki, Datadog, etc.)
