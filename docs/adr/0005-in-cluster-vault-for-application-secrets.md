# ADR 0005: Use In-Cluster Vault for Traderoo Application Secrets

## Status

Accepted

## Date

2026-07-07

## Context

Traderoo will eventually require runtime secrets.

Likely future secrets include:

```text id="rgk87p"
OpenAI API key
application session secret
database credentials
internal service credentials
future notification provider tokens
```

Traderoo must not commit plaintext secrets to Git.

Traderoo must also preserve the MVP safety boundary:

```text id="mmvg3u"
No broker credentials.
No live trading credentials.
No real-money execution credentials.
No real broker API keys.
```

The project runs locally on a k3d Kubernetes cluster and is managed through GitOps using Argo CD.

This creates a design question:

```text id="dlxe0f"
Where should runtime application secrets live?
```

Kubernetes Secrets are convenient, but committed plaintext Kubernetes Secret manifests are not acceptable.

Environment variables are convenient, but storing real secret values in Git, docs, scripts, Makefiles, or manifests is not acceptable.

Traderoo therefore needs an explicit secrets-management decision before application implementation begins.

---

## Decision

Traderoo will use an **in-cluster Vault** as the intended runtime secret store for application secrets.

Vault will run inside the local Kubernetes cluster in a dedicated namespace:

```text id="4qyu9j"
vault
```

Traderoo application workloads will run in:

```text id="mn7uaa"
traderoo-poc
```

Vault will be used as the source of truth for runtime application secrets once secrets are required.

The MVP must not store real application secrets in Git.

The MVP must not store broker credentials at all.

---

## Important qualification

“In-cluster Vault” does not mean Vault solves its own bootstrap problem.

Vault running inside Kubernetes still requires:

```text id="aobduq"
initialisation
unseal process
root/recovery token handling
backup and recovery planning
operator access control
storage configuration
```

These are operational concerns and must be handled deliberately.

For the local Traderoo proof of concept, a simple manual bootstrap may be acceptable.

For anything beyond the local POC, Vault bootstrap, unseal, backup, and recovery require a stronger design.

---

## Scope of this ADR

This ADR decides the **intended secrets-management direction**.

This ADR does not implement Vault.

This ADR does not add:

```text id="5gozqr"
Vault Helm chart
Vault manifests
External Secrets Operator
Vault Agent Injector
Kubernetes Secret manifests with real values
application code
OpenAI integration
database credential wiring
broker integration
```

Implementation belongs in a later platform chunk.

---

## Secrets policy

Traderoo runtime secrets must not be committed to Git.

Forbidden in Git:

```text id="ugm7ae"
real API keys
real tokens
real passwords
real private keys
real database passwords
real OpenAI API keys
real webhook tokens
real broker credentials
real trading account IDs
```

Allowed in Git:

```text id="hd9c16"
placeholder values
example variable names
documentation examples with fake values
sealed references without secret material
ExternalSecret definitions without secret values
Vault policy templates without secret values
Kubernetes Secret templates containing only dummy/example values
```

Only fake values may appear in examples.

Examples of acceptable fake values:

```text id="v39hvh"
changeme
example
dummy
not-a-real-secret
replace-me
```

---

## Broker credential policy

Broker credentials are prohibited during the MVP.

Traderoo must not store, request, configure, or document real credentials for:

```text id="08d3yy"
Interactive Brokers
Trading 212
Alpaca live trading
Saxo
IG
Robinhood
any real broker
any spread betting provider
any CFD provider
any live trading venue
```

This applies even if Vault exists.

Vault is not permission to introduce live trading.

The MVP remains:

```text id="fmjowf"
PAPER_ONLY
```

---

## Intended future secret classes

The following secret classes may be introduced later if needed:

```text id="397e55"
secret/traderoo/openai/api-key
secret/traderoo/app/session-secret
secret/traderoo/postgres/app-password
secret/traderoo/notifications/webhook-token
```

The following secret classes are prohibited during the MVP:

```text id="m6x3nn"
secret/traderoo/broker/*
secret/traderoo/live-trading/*
secret/traderoo/real-account/*
secret/traderoo/margin/*
secret/traderoo/cfd/*
secret/traderoo/spread-betting/*
```

---

## Runtime access model

The intended runtime access model is:

```text id="euqtdf"
Traderoo workload
  → Kubernetes service account identity
  → Vault Kubernetes auth
  → Vault policy
  → permitted Traderoo secret path
```

Traderoo workloads should only receive access to the secrets they require.

Do not grant broad Vault access to application pods.

---

## Secret delivery options

Two future implementation options are acceptable.

## Option A: External Secrets Operator

External Secrets Operator may sync selected Vault secrets into Kubernetes Secrets.

Application pods then consume Kubernetes Secrets as environment variables or mounted files.

Advantages:

```text id="t4v5fq"
simple application integration
works with normal Kubernetes Secret consumption
easy to inspect Kubernetes wiring
```

Trade-offs:

```text id="v63473"
secret material exists as Kubernetes Secrets at runtime
requires ESO installation and configuration
```

## Option B: Vault Agent Injector

Vault Agent may inject secrets into pods as files or templates.

Advantages:

```text id="br3m68"
direct Vault integration
less reliance on long-lived Kubernetes Secret objects
supports secret renewal patterns
```

Trade-offs:

```text id="fnnxwt"
more moving parts
more pod annotation/configuration complexity
more operational debugging
```

## Current preference

For Traderoo’s local POC, the preferred first implementation is:

```text id="ztbzms"
Vault as source of truth
External Secrets Operator as the Kubernetes delivery mechanism
```

This preference may be revisited in a later ADR if Vault Agent Injector becomes more appropriate.

---

## Vault mode

Vault dev mode must not be used for persistent Traderoo secrets.

Dev mode is acceptable only for throwaway experiments that do not store meaningful secrets.

The intended persistent POC mode should use:

```text id="7nys4d"
Vault running in Kubernetes
persistent storage
documented init/unseal process
documented recovery notes
```

For the local POC, storage may be simple.

For any serious environment, storage, backup, unseal, and recovery must be treated as production-grade concerns.

---

## Argo CD and GitOps boundary

Argo CD may deploy Vault-related manifests later.

Argo CD must not store plaintext secret values in Git.

Argo CD may manage:

```text id="zhvqn8"
Vault namespace
Vault Helm release values without secrets
Vault policies without secrets
Vault auth configuration without sensitive token values
ExternalSecret resources without secret values
service accounts
RBAC
```

Argo CD must not manage:

```text id="5dpaov"
plaintext OpenAI API key
plaintext database password
plaintext private keys
plaintext broker credentials
```

---

## CI expectations

CI should help enforce the secrets policy.

CI should check for obvious secret leakage in executable/configuration paths.

CI should scan areas such as:

```text id="luuz5g"
app/
deploy/
platform/
scripts/
tests/
.github/workflows/
Makefile
```

CI should avoid treating safety documentation as a violation source because safety docs intentionally describe prohibited terms.

CI should fail on obvious committed secrets or broker credential patterns.

---

## Impact on delivery plan

This ADR adds a platform prerequisite before application code starts.

The immediate impact is documentation and CI policy only.

Future impact:

```text id="ivbse2"
A later platform chunk should install Vault.
A later platform chunk should configure Kubernetes auth.
A later platform chunk should choose and implement secret delivery.
OpenAI integration must use the documented secret path.
Postgres credentials must use the documented secret path once introduced.
```

---

## Consequences

## Positive consequences

```text id="7qcqmj"
Clear secret-management direction before app code exists.
Avoids committing plaintext secrets to Git.
Preserves GitOps without storing real secret values.
Creates a path for future OpenAI and database credentials.
Keeps broker credentials prohibited during the MVP.
Makes Copilot instructions clearer.
```

## Negative consequences

```text id="x8x6yp"
Adds platform complexity.
Introduces Vault bootstrap and unseal concerns.
Requires later operational documentation.
Requires careful local POC handling.
Does not remove the need for Kubernetes RBAC and namespace controls.
```

## Neutral consequences

```text id="6v6o2f"
Vault is not required for Chunk 0 placeholder manifests.
Vault is not required for Chunk 1 FastAPI skeleton if no secrets are needed.
Vault becomes important before real runtime secrets are introduced.
```

---

## Alternatives considered

## Plain Kubernetes Secrets committed to Git

Rejected.

This would risk committing plaintext secret material.

## Environment variables in Makefile or manifests

Rejected for real secrets.

Environment variables may reference secret names or fake values, but real secret values must not be committed.

## Local `.env` files only

Rejected as the primary strategy.

Local `.env` files are useful for development, but they do not provide a Kubernetes-native or GitOps-friendly runtime secrets model.

If `.env` files are used locally, they must be ignored by Git.

## External cloud secret manager

Deferred.

Traderoo currently targets a local k3d POC. External cloud secret managers may be reconsidered if the platform moves to AWS, Azure, or GCP.

## No secret-management decision yet

Rejected.

Leaving this undecided would encourage ad hoc secret handling once OpenAI, Postgres, or notification integrations are added.

---

## Related documents

```text id="v6ron5"
docs/safety/secrets-management.md
docs/safety/paper-only-guardrails.md
docs/safety/ai-boundaries.md
docs/delivery/ci-quality-gates.md
docs/delivery/definition-of-done.md
.github/copilot-instructions.md
```

---

## Summary

Traderoo will use in-cluster Vault as the intended runtime secret store for application secrets.

Vault does not permit live trading.

Vault does not remove the paper-only boundary.

The MVP rule remains:

```text id="dmkknc"
No plaintext secrets in Git.
No broker credentials.
No live trading credentials.
PAPER_ONLY.
```
