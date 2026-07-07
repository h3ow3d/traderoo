# Traderoo

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane proof of concept.

Current status: Chunk 1 (minimal runtime skeleton).

## Safety

Traderoo MVP is paper-only.

Required defaults in this repository:

- `APP_NAME=traderoo`
- `APP_ENV=poc`
- `EXECUTION_MODE=PAPER_ONLY`
- `REVIEW_PROVIDER=mock`
- Namespace: `traderoo-poc`
- k3d cluster name: `traderoo`

No live broker integration or real-money execution exists in Chunk 0.

## Chunk 1 scope

This chunk includes:

- minimal FastAPI runtime under `app/`
- endpoints: `/healthz`, `/readyz`, `/`
- strict `EXECUTION_MODE=PAPER_ONLY` guardrail in configuration
- unit tests for runtime endpoints and configuration defaults
- Dockerfile for local image build (`traderoo:local`)
- application-owned Kubernetes `Deployment` and `Service`
- probes on `/healthz` and `/readyz`
- Makefile and CI updates for runtime validation

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

Run runtime locally:

```bash
make install
make test
make run
curl -fsS http://127.0.0.1:8000/healthz
curl -fsS http://127.0.0.1:8000/readyz
curl -fsS http://127.0.0.1:8000/
```

Render Kubernetes manifests locally:

```bash
make validate-k8s-local
make kustomize-traderoo-poc
```

Build and import runtime image before applying Traderoo app in-cluster:

```bash
make docker-build
make traderoo-image-import
```

Apply Argo CD application:

```bash
make platform-apply
make platform-status
make traderoo-apply
make traderoo-status
```

Path ownership model:

- Platform bootstrap: `platform/bootstrap/argocd/`
- Platform services chart: `platform/charts/platform-services/`
- Traderoo application Argo CD spec: `applications/traderoo/argocd/poc.yaml`
- Traderoo manifests: `applications/traderoo/k8s/`

Bootstrap order:

- Apply platform first.
- Wait for AppProjects (`platform` and `traderoo-poc`) and namespace (`traderoo-poc`).
- Then apply Traderoo Application.

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
