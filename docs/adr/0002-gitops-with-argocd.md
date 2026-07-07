# ADR 0002: Use Argo CD for GitOps deployment

## Status

Accepted

## Context

Traderoo will run on a local Kubernetes cluster but should still be deployed through a repeatable GitOps workflow.

The project will be developed incrementally in chunks. Each chunk should be committed to GitHub and deployed into the local cluster in a controlled way.

The deployment process should separate:

```text
GitHub repository
  -> desired Kubernetes state

Container registry
  -> application images

Argo CD
  -> synchronises manifests into Kubernetes
```

Argo CD should not build application images. It should only reconcile Kubernetes manifests from Git into the cluster.

## Decision

Use Argo CD as the GitOps controller for Traderoo.

Argo CD will be installed into the namespace:

```text
argocd
```

Traderoo application manifests will live under:

```text
applications/traderoo/k8s
```

Argo CD application manifests will live under:

```text
applications/traderoo/argocd
```

The initial Argo CD Application for the active environment will be named:

```text
traderoo-poc
```

It will sync the active POC overlay:

```text
applications/traderoo/k8s/overlays/poc
```

The initial sync policy may use:

```text
automated sync
prune
self-heal
```

The target application namespace will be:

```text
traderoo-poc
```

## Consequences

### Positive

* The local cluster can be reconciled from GitHub.
* Kubernetes state is visible and reviewable in Git.
* The deployment flow becomes repeatable from the start.
* The project can later add CI image builds without giving CI direct cluster credentials.
* Argo CD provides a useful UI for sync status, drift, and health.

### Negative

* Argo CD adds setup complexity before application code exists.
* Private repositories require repository credentials or deploy keys.
* Image build and manifest update flows must be handled separately.
* GitOps can feel heavyweight during early prototyping.

## Alternatives considered

### Manual `kubectl apply`

Manual `kubectl apply` would be faster initially.

Rejected because it does not validate the intended GitOps operating model.

### GitHub Actions deploy directly to cluster

GitHub Actions could deploy directly using kubeconfig credentials.

Rejected for the POC because it would require exposing cluster credentials to CI and would mix build and deployment responsibilities.

### Flux CD

Flux CD is another strong GitOps option.

Not chosen because Argo CD provides a highly visible UI and is familiar for local GitOps experimentation.

## Decision outcome

Traderoo will use Argo CD as the GitOps deployment controller from Chunk 0 onward.
