# Traderoo Secrets Management

## 1. Purpose

This document defines the Traderoo secrets-management policy.

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane proof of concept.

Traderoo will eventually need runtime secrets, but the MVP must avoid unsafe or ad hoc secret handling.

The purpose of this document is to make the secrets boundary clear before application implementation begins.

---

## 2. Core rule

Do not commit real secrets to Git.

Do not introduce broker credentials during the MVP.

The defining rule is:

```text id="jypfz3"
No plaintext secrets in Git.
No broker credentials.
No live trading credentials.
PAPER_ONLY.
```

---

## 3. Current decision

Traderoo will use an in-cluster Vault as the intended runtime secret store for application secrets.

Vault will run in a dedicated namespace:

```text id="6l6iai"
vault
```

Traderoo will run in:

```text id="ochk2m"
traderoo-poc
```

Vault implementation is not part of the current documentation/bootstrap work.

Vault installation, configuration, auth, secret delivery, backup, and recovery belong to later platform work.

---

## 4. What counts as a secret?

A secret is any value that should not be public or committed to Git.

Examples:

```text id="t9vcpy"
API key
access token
refresh token
password
private key
signing key
webhook token
database password
session secret
encryption key
service account credential
```

In Traderoo, likely future secrets include:

```text id="85qdeq"
OpenAI API key
application session secret
Postgres application password
notification webhook token
```

---

## 5. Prohibited secrets during the MVP

The following must not exist anywhere in the MVP:

```text id="e7fzxq"
broker credentials
live trading API keys
real trading account IDs
margin account credentials
CFD provider credentials
spread betting credentials
options trading credentials
real order-routing credentials
```

This applies to:

```text id="9x9c1v"
Git
Vault
Kubernetes Secrets
local .env files
Makefiles
scripts
application config
CI variables
developer notes
```

Vault must not be used as a loophole to introduce live trading.

---

## 6. Git policy

The repository must not contain real secret values.

Forbidden in Git:

```text id="8t946g"
OPENAI_API_KEY with a real value
database passwords
webhook tokens
private keys
broker API keys
real account IDs
OAuth client secrets
cloud credentials
Vault root tokens
Vault unseal keys
```

Allowed in Git:

```text id="6hqig6"
placeholder values
fake example values
environment variable names
secret path names
ExternalSecret references without secret values
Vault policy templates without secret values
documentation examples with fake values
```

Acceptable fake/example values:

```text id="8s7e5a"
changeme
replace-me
dummy
example
not-a-real-secret
fake-token
```

---

## 7. Local development policy

Local development may use local-only files for non-sensitive fake values.

Any local secret file must be ignored by Git.

Examples that should be ignored:

```text id="ert460"
.env
.env.local
.envrc
*.pem
*.key
*.p12
*.pfx
vault-token
```

Local development must not require real broker credentials.

If OpenAI integration is introduced later, local development should support a documented secret injection path.

---

## 8. Kubernetes policy

Kubernetes manifests must not contain real secret values.

Allowed Kubernetes resources in Git:

```text id="vzhrj6"
Namespace
ConfigMap
ServiceAccount
Role
RoleBinding
Deployment
Job
CronJob
ExternalSecret without real secret material
Secret template with fake/example values only
```

Avoid committing real Kubernetes `Secret` manifests.

If a Kubernetes Secret manifest is required for testing, it must contain fake values only and be clearly marked as non-production/example.

---

## 9. Vault policy

Vault is the intended source of truth for runtime application secrets.

Expected future secret paths:

```text id="hmgwwe"
secret/traderoo/openai/api-key
secret/traderoo/app/session-secret
secret/traderoo/postgres/app-password
secret/traderoo/notifications/webhook-token
```

Forbidden MVP secret paths:

```text id="qicp7n"
secret/traderoo/broker/*
secret/traderoo/live-trading/*
secret/traderoo/real-account/*
secret/traderoo/margin/*
secret/traderoo/cfd/*
secret/traderoo/spread-betting/*
secret/traderoo/options/*
```

Vault access should be least privilege.

Traderoo workloads should only access the secret paths required for their function.

---

## 10. Vault bootstrap boundary

Vault running inside the cluster still requires bootstrap.

The following must be handled deliberately:

```text id="59wndj"
Vault initialisation
unseal keys
root token
recovery token
backup
restore
operator access
persistent storage
namespace isolation
```

Do not commit Vault root tokens, recovery tokens, or unseal keys.

Do not store Vault bootstrap material inside the same repository.

For the local POC, manual bootstrap may be acceptable.

For any serious environment, a stronger operational design is required.

---

## 11. Secret delivery pattern

The preferred future pattern is:

```text id="j6sg0p"
Vault
  → External Secrets Operator
  → Kubernetes Secret
  → Traderoo workload
```

This keeps Vault as the source of truth while allowing applications to consume normal Kubernetes Secrets.

A future ADR may choose Vault Agent Injector instead if direct injection becomes more appropriate.

Until that implementation exists, do not add real runtime secrets.

---

## 12. OpenAI secret policy

OpenAI integration is future scope.

When OpenAI support is introduced, the API key must not be committed to Git.

The OpenAI key should come from the documented secret-management path.

Allowed:

```text id="hw7x88"
OPENAI_API_KEY environment variable name
Vault secret reference
ExternalSecret definition referencing Vault
documentation with fake example values
```

Forbidden:

```text id="gzj4q7"
real OpenAI API key in Git
real OpenAI API key in README
real OpenAI API key in Kubernetes manifest
real OpenAI API key in Makefile
real OpenAI API key in test fixture
```

OpenAI must also follow:

```text id="1h8sum"
docs/safety/ai-boundaries.md
```

---

## 13. Database secret policy

Postgres credentials are future runtime secrets.

For early local development, a fake/simple local password may be acceptable only if clearly non-sensitive and local-only.

Before any meaningful runtime use, database credentials should be supplied through the documented secret-management path.

Do not commit real database credentials.

Do not reuse personal passwords.

Do not store database passwords in README command examples unless they are fake/example values.

---

## 14. Broker secret policy

Broker secrets are prohibited during the MVP.

Do not add configuration for:

```text id="ioi5hk"
BROKER_API_KEY
BROKER_SECRET
BROKER_TOKEN
IBKR_USERNAME
IBKR_PASSWORD
TRADING212_API_KEY
ALPACA_API_KEY
ALPACA_SECRET_KEY
IG_API_KEY
SAXO_TOKEN
LIVE_TRADING_ACCOUNT_ID
```

Do not add placeholders that imply live trading is part of the MVP.

If future broker research is ever considered, it requires a new ADR and must not be mixed into the paper-only MVP.

---

## 15. CI policy

CI should help prevent secret leakage.

CI should scan executable and configuration paths for obvious secret or broker patterns.

Suggested scan areas:

```text id="zv0hhl"
app/
deploy/
platform/
scripts/
tests/
.github/workflows/
Makefile
```

CI should not treat `docs/safety/` as a violation source because this document intentionally lists prohibited terms.

CI should fail if obvious committed secrets or broker credentials appear in executable/configuration areas.

Examples of suspicious patterns:

```text id="xsp102"
api_key = "..."
password = "..."
secret = "..."
token = "..."
broker credentials
live broker
real broker
live order
real order
```

CI scanning is not a complete secret-detection solution. It is a guardrail.

Developers must still avoid committing secrets.

---

## 16. Copilot rules

When GitHub Copilot works on Traderoo, it must follow these rules:

```text id="1myjs5"
Do not commit real secrets.
Do not create broker credential configuration.
Do not create live trading credential placeholders.
Do not add real API keys to tests or examples.
Do not add Vault root tokens.
Do not add Vault unseal keys.
Do not add Kubernetes Secrets with real values.
Use fake placeholder values only in examples.
Use Vault-backed secret flow for future runtime secrets.
```

If a change requires a secret, Copilot should add a configuration reference and documentation, not a real value.

---

## 17. Review checklist

Before accepting a PR, check:

```text id="5cyuiy"
Does the PR add any real secret value?
Does the PR add any broker credential field?
Does the PR add any live trading credential path?
Does the PR add a Kubernetes Secret with real data?
Does the PR add a .env file?
Does the PR log sensitive values?
Does the PR weaken CI secret scanning?
Does the PR preserve PAPER_ONLY?
```

If any answer is unsafe, reject or revise the PR.

---

## 18. Future implementation checklist

When Vault implementation begins, the platform chunk should define:

```text id="6qp3iz"
Vault namespace
Vault install method
persistent storage
init process
unseal process
recovery process
Kubernetes auth
Traderoo service account
Vault policies
secret path structure
External Secrets Operator or Vault Agent decision
local validation commands
backup and restore notes
```

Do not implement Vault casually or invisibly as part of unrelated application work.

---

## 19. Failure behaviour

If a required secret is missing at runtime, Traderoo should fail closed.

Examples:

```text id="ee69na"
missing OpenAI key → disable OpenAI provider or fail provider startup
missing database password → fail database connection
missing session secret → fail web startup if sessions require it
missing Vault access → fail the dependent workload
```

Missing secrets must not cause fallback to unsafe defaults.

Traderoo must never fall back from paper-only mode to live trading.

---

## 20. Summary

Traderoo secrets management is based on four rules:

```text id="41h9kq"
1. No plaintext secrets in Git.
2. Vault is the intended runtime secret store.
3. Broker credentials are prohibited during the MVP.
4. PAPER_ONLY remains mandatory.
```

Vault improves secret handling.

Vault does not weaken the trading safety boundary.
