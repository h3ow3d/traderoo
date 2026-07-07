# ADR 0001: Use local Kubernetes with k3d

## Status

Accepted

## Context

Traderoo is a proof of concept for an AI trading control plane.

The system is intended to run locally on a powerful desktop machine and eventually include multiple runtime components:

* backend API
* web dashboard
* database
* ingestion workers
* observer workers
* review workers
* watcher workers
* outcome evaluation jobs

The project needs a local environment that is close enough to Kubernetes production patterns to support GitOps, scheduled jobs, persistent storage, and later service decomposition.

The local platform should be easy to create, destroy, and recreate.

## Decision

Use `k3d` to run a local Kubernetes cluster.

The cluster will be named:

```text
traderoo
```

The initial local cluster shape will be:

```text
1 server node
2 agent nodes
```

The cluster will expose local ingress-style ports:

```text
8080 -> 80
8443 -> 443
```

Traefik will be disabled initially so ingress/controller choices can be made explicitly later.

The cluster specification will live at:

```text
platform/k3d/cluster.yaml
```

The Makefile will include commands for:

```text
make cluster-create
make cluster-delete
make cluster-status
```

## Consequences

### Positive

* Traderoo can be tested locally in a real Kubernetes environment.
* The cluster is disposable and reproducible.
* Argo CD can be installed into the local cluster.
* Kubernetes manifests can be validated early.
* Scheduled worker jobs can be modelled using Kubernetes CronJobs.
* The project can evolve toward production-like deployment patterns without needing cloud infrastructure.

### Negative

* Running Kubernetes locally adds complexity compared with Docker Compose.
* Local persistent volumes are not production-grade.
* The user must install Docker, k3d, kubectl, and related tooling.
* Some behaviour may differ from managed Kubernetes distributions.

## Alternatives considered

### Docker Compose

Docker Compose would be simpler for the earliest prototype.

Rejected because Traderoo is intended to validate a Kubernetes-hosted control plane, GitOps deployment, scheduled workers, and future service boundaries.

### minikube

Minikube is a common local Kubernetes option.

Rejected in favour of k3d because k3d is lightweight, fast to recreate, and well-suited for local disposable clusters.

### Cloud Kubernetes

A cloud Kubernetes cluster would be closer to a production environment.

Rejected for the POC because it adds cost, external exposure, secret-management concerns, and unnecessary operational overhead.

## Decision outcome

Traderoo will use a local k3d Kubernetes cluster as the default POC runtime.
