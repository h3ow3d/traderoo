# ADR 0006: Separate platform services from application GitOps ownership

## Status

Accepted

## Date

2026-07-07

## Context

Traderoo is deployed to a local Kubernetes cluster using GitOps with Argo CD.

As Traderoo evolves, platform capabilities and application deployment responsibilities must remain clearly separated.

Without an explicit boundary, ownership can drift and create unsafe coupling between:

```text
cluster capabilities
application deployment
secret delivery plumbing
runtime application workloads
```

This boundary must be documented before any Vault or platform-services implementation chunk.

The boundary must also preserve Traderoo MVP safety constraints:

```text
PAPER_ONLY only
no broker credentials
no live trading credentials
no real secrets in Git
```

## Decision

Traderoo will separate platform services from application consumers as follows.

### Platform services are shared cluster capabilities

The platform layer owns shared cluster capabilities and safety guardrails, including:

```text
Argo CD installation/bootstrap
platform-services Helm wrapper chart
Vault installation
External Secrets Operator installation
Argo CD AppProjects and deployment guardrails
Vault auth method and policy boundaries
```

### Traderoo application is a consumer of platform services

The application layer owns Traderoo runtime delivery and namespaced resources, including:

```text
Traderoo Argo CD Application
deploy/k8s Traderoo manifests
Traderoo namespace resources within platform-approved boundaries
Traderoo ServiceAccounts
Traderoo ConfigMaps
Traderoo ExternalSecret resources that reference platform-provided Vault/ESO capability
Traderoo workloads
```

### Explicit non-ownership rule

The platform-services wrapper chart must not own the Traderoo application deployment.

Traderoo application deployment remains application-owned and independently versioned in Traderoo manifests.

## Safety constraints

This separation does not weaken MVP safety policy.

Mandatory constraints remain:

```text
PAPER_ONLY remains mandatory
Vault does not permit broker credentials or live trading
No real secrets are committed to Git
```

These constraints apply to both platform and application layers.

## Consequences

### Positive

* Ownership is explicit before Vault implementation work.
* Platform capabilities can be reused safely by multiple applications.
* Application deployment remains decoupled from platform bootstrap.
* AppProject and policy boundaries can enforce namespace and scope rules.
* Secret management can evolve without embedding secrets in Git.

### Negative

* Requires discipline to keep platform and application repositories/manifests distinct in responsibility.
* Requires additional documentation and review checks across future chunks.
* Adds initial conceptual overhead compared with an all-in-one deployment pattern.

## Out of scope of this ADR

This ADR does not implement:

```text
Vault manifests
Vault Helm chart values
External Secrets Operator manifests
platform-services Helm chart skeleton
Argo CD Application templates
application code
trading logic
```

This ADR is documentation-only boundary setting.

## Decision outcome

Traderoo will treat platform services as shared cluster capabilities and Traderoo runtime delivery as an application consumer concern, with explicit safety and ownership boundaries enforced through documentation, GitOps structure, and future platform guardrails.
