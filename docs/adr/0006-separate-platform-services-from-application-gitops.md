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

### GitOps root model

Traderoo will use separate Argo CD roots for platform and applications.

Bootstrap flow:

```text
manually bootstrap Argo CD once
apply root platform Application once
apply root applications Application once
```

Steady-state ownership:

```text
platform root manages platform services
applications root manages application-owned Argo CD Application specs
```

### Platform services are shared cluster capabilities

The platform layer owns shared cluster capabilities and safety guardrails, including:

```text
Argo CD installation/bootstrap
root platform Application
platform-services Helm wrapper chart
Vault Application (later)
External Secrets Operator Application (later)
Argo CD AppProjects and deployment guardrails
Vault auth method and policy boundaries (later)
```

### Traderoo application is a consumer of platform services

The application layer owns Traderoo runtime delivery and namespaced resources, including:

```text
root applications Application
Traderoo Argo CD Application spec
deploy/k8s Traderoo manifests
Traderoo ServiceAccounts
Traderoo ConfigMaps
Traderoo ExternalSecret resources
Traderoo workloads
```

### Explicit non-ownership rule

The platform-services wrapper chart must not own the Traderoo application deployment.

Traderoo application deployment remains application-owned and independently versioned in Traderoo manifests.

Traderoo consumes Vault/ESO capabilities but does not install or manage Vault/ESO.

### Dependency direction

Dependency direction is one-way:

```text
platform root and platform services
	-> provide shared capabilities
	-> consumed by application root and Traderoo application specs
```

Application GitOps objects must not be rendered by the platform-services wrapper chart.

This avoids cyclical ownership between platform and application reconciliation.

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
* Separate platform and applications roots reduce ownership ambiguity.
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
