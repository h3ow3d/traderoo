# Traderoo

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane proof of concept.

Current status: Chunk 0 (platform and repository bootstrap).

## Safety

Traderoo MVP is paper-only.

Required defaults in this repository:

- `APP_NAME=traderoo`
- `EXECUTION_MODE=PAPER_ONLY`
- `REVIEW_PROVIDER=mock`
- `ENVIRONMENT=local` (local overlay)
- Namespace: `traderoo-poc`
- k3d cluster name: `traderoo`

No live broker integration or real-money execution exists in Chunk 0.

## Chunk 0 scope

This chunk includes:

- repository skeleton folders
- local k3d cluster definition
- Argo CD install guide
- separate platform bootstrap and application ownership layout
- platform-services Helm wrapper chart skeleton for AppProjects
- Kustomize base and local overlay placeholder manifests
- Argo CD Application manifest
- Makefile operator commands

This chunk does not include:

- application code
- FastAPI
- Postgres
- market data ingestion
- OpenAI integration
- trading logic
- broker integration

## Prerequisites

Install locally:

- Docker
- k3d
- kubectl
- kustomize (or `kubectl` with kustomize support)
- argocd CLI (required for `make argocd-sync` and `make argocd-get`)

## Quick start

```bash
make cluster-create
make cluster-status

make argocd-install
make argocd-status
make argocd-password

# In another terminal
make argocd-port-forward
```

Argo CD UI: https://localhost:8081

Apply local manifests directly:

```bash
make validate-k8s-local
kubectl get configmap traderoo-config -n traderoo-poc -o yaml
```

Apply Argo CD application after replacing the repository URL placeholder:

```bash
make argocd-apply-app
```

Path ownership model:

- Platform bootstrap: `platform/bootstrap/argocd/`
- Platform services chart: `platform/charts/platform-services/`
- Traderoo application Argo CD spec: `applications/traderoo/argocd/application.yaml`
- Traderoo manifests: `applications/traderoo/k8s/`

Validate the platform chart locally:

```bash
make validate-platform-services
```

Optional Argo CD CLI commands:

```bash
make argocd-sync
make argocd-get
```

Delete app/cluster:

```bash
make argocd-delete-app
make cluster-delete
```
