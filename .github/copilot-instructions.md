# Traderoo Copilot Instructions

## Project identity

This repository is **Traderoo**.

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane proof of concept.

The MVP proves this lifecycle:

```text
Data → Features → Observations → Candidates → Review → Risk Gate
→ Paper Trade → Watcher → Alert → Outcome Evaluation → Dashboard
```

Traderoo is not a live trading bot.

Traderoo is not intended to guarantee profit.

Traderoo must remain paper-only during the MVP.

---

## Required context documents

Before making significant changes, read these documents:

```text
docs/hld.md
docs/product/mvp-scope.md
docs/product/subsystem-map.md
docs/delivery/chunk-plan.md
docs/delivery/validation-matrix.md
docs/delivery/definition-of-done.md
docs/delivery/ci-quality-gates.md
docs/safety/paper-only-guardrails.md
docs/safety/ai-boundaries.md
docs/safety/secrets-management.md
docs/c4/01-system-context.md
docs/c4/02-container-view.md
docs/c4/03-component-view.md
docs/adr/0001-local-kubernetes-with-k3d.md
docs/adr/0002-gitops-with-argocd.md
docs/adr/0003-paper-only-mvp.md
docs/adr/0004-project-structure.md
docs/adr/0005-in-cluster-vault-for-application-secrets.md
docs/adr/0006-separate-platform-services-from-application-gitops.md
```

If implementation instructions conflict with these documents, ask for clarification before coding.

---

## Core safety rule

Traderoo MVP is paper-only.

The only permitted execution mode is:

```text
PAPER_ONLY
```

Do not add:

```text
real broker integration
real broker credentials
live order placement
live order cancellation
real-money execution
leverage
CFDs
spread betting
options trading
crypto leverage
autonomous live execution
```

Do not create code that can place real orders.

Do not create broker API configuration.

Do not add a live broker adapter.

Vault does not weaken this boundary.

Even if Vault exists, broker credentials remain prohibited during the MVP.

---

## Secrets management rule

Traderoo must not commit real secrets to Git.

Traderoo will use in-cluster Vault as the intended runtime secret store for application secrets.

Required secrets-management documents:

```text
docs/safety/secrets-management.md
docs/adr/0005-in-cluster-vault-for-application-secrets.md
```

Do not add:

```text
plaintext API keys
plaintext passwords
plaintext tokens
plaintext private keys
real OpenAI API keys
real database passwords
Vault root tokens
Vault unseal keys
broker credentials
live trading credentials
Kubernetes Secrets containing real values
.env files containing real values
```

Allowed:

```text
placeholder values
fake example values
environment variable names
Vault secret path references
ExternalSecret definitions without secret material
documentation examples with fake values
```

Acceptable fake values include:

```text
changeme
replace-me
dummy
example
not-a-real-secret
fake-token
```

Vault implementation is a future platform chunk.

Do not add Vault Helm charts, Vault manifests, External Secrets Operator, Vault Agent Injector, or real Kubernetes Secret wiring unless explicitly requested by the current chunk.

If a change requires a secret, add a configuration reference and documentation, not a real value.

---

## Platform/application ownership boundary

Traderoo separates platform services from application consumers.

Platform layer owns shared cluster capabilities:

```text
Argo CD installation/bootstrap
platform-services wrapper chart
Vault installation
External Secrets Operator installation
Argo CD AppProjects and deployment guardrails
Vault auth method and policy boundaries
```

Application layer owns Traderoo runtime delivery:

```text
Traderoo Argo CD Application
Traderoo Kubernetes manifests
Traderoo namespace resources within platform-approved boundaries
Traderoo ServiceAccounts
Traderoo ConfigMaps
Traderoo ExternalSecret resources referencing platform-provided Vault/ESO capability
Traderoo workloads
```

The platform-services wrapper chart must not own the Traderoo application deployment.

Vault does not permit broker credentials or live trading.

---

## AI boundary

AI may analyse.

AI may not execute.

OpenAI or local models may:

```text
review candidate paper trades
summarise evidence
score Signal / Edge
score Safety / Risk
score Situation / Context
suggest watcher rules
recommend human review
produce structured advisory output
```

AI must not:

```text
place trades
approve trades directly
bypass the deterministic risk gate
modify risk limits
modify execution mode
call execution code
call broker APIs
change strategy logic live
```

All AI output must be treated as advisory and schema-validated.

Invalid AI output must fail closed.

---

## Architecture style

Use a modular monolith first.

Do not split Traderoo into microservices during the MVP.

Prefer:

```text
one application codebase
one backend image
multiple worker commands
shared Postgres database
clear internal modules
server-rendered UI first
```

Avoid:

```text
premature microservices
Kafka/NATS/event streaming
service mesh
complex auth
over-complex production secret management before the agreed Vault platform chunk
frontend framework complexity
live broker integration
```

unless explicitly requested in a later chunk.

---

## Expected technology choices

Use:

```text
Python
FastAPI
Postgres
SQLAlchemy or SQLModel
Jinja/server-rendered HTML for the first UI
pytest
k3d
Kubernetes
Kustomize
Argo CD
```

Market data for the POC may use:

```text
yfinance
```

Treat yfinance as POC-grade only.

---

## Repository structure

The expected repository structure is:

```text
traderoo/
├── app/
├── deploy/
├── platform/
├── docs/
├── scripts/
├── tests/
├── .github/
├── .gitignore
├── Makefile
└── README.md
```

Do not invent a different top-level layout without a new ADR or explicit user approval.

---

## Delivery chunks

Traderoo must be implemented incrementally.

Current delivery plan:

```text
Chunk 0  — Platform and repository bootstrap
Chunk 1  — Runnable FastAPI skeleton
Chunk 2  — Postgres and core schema
Chunk 3  — Market data ingestion
Chunk 4  — Feature generation and observations
Chunk 5  — Candidate generation
Chunk 6  — Mock triangle review
Chunk 7  — Deterministic risk gate
Chunk 8  — Manual approval and paper execution
Chunk 9  — Position watchers and alerts
Chunk 10 — Outcome evaluation and performance dashboard
Chunk 11 — Optional OpenAI review provider
Chunk 12 — Kubernetes polish
```

Only implement the requested chunk.

Do not implement future chunks early.

---

## Definition of done

A change is not complete until it includes:

```text
implementation
tests where applicable
validation commands
expected outputs
documentation updates where relevant
confirmation that PAPER_ONLY guardrails remain intact
```

After completing a chunk, report:

```text
files changed
summary of implementation
how to run locally
how to run in Kubernetes, where applicable
tests added or updated
validation commands
expected outputs
known limitations
what remains for the next chunk
```

---

## CI and quality gate rule

Every implementation chunk must maintain or improve CI.

Before completing a chunk, check:

```text
.github/workflows/
docs/delivery/ci-quality-gates.md
docs/delivery/validation-matrix.md
docs/delivery/definition-of-done.md
```

GitHub Actions workflows must live under:

```text
.github/workflows/
```

Do not create root-level workflow files such as:

```text
ci.yml
```

unless they are documentation examples only.

For any code change, ensure CI covers the relevant validation.

Expected CI direction:

```text
pull_request checks must run before merge
push checks should run on main
tests must be runnable locally and in CI
quality checks must be deterministic
paper-only safety checks must remain present
Kubernetes manifests must be validated where relevant
secret-leakage checks must remain present
```

Do not remove, weaken, or bypass CI checks without explicit approval.

If a chunk adds Python code, update CI to run Python quality and tests.

If a chunk adds Kubernetes manifests, update CI to validate manifests.

If a chunk adds safety-sensitive execution logic, update CI to test PAPER_ONLY guardrails.

If a chunk changes secrets handling, update CI to preserve or improve secret-leakage checks.

For Kubernetes validation, CI should render manifests with Kustomize but must not assume access to the user’s local k3d cluster.

CI must not deploy to the user’s local machine.

CI must not require real OpenAI credentials, broker credentials, or Vault bootstrap material.

A chunk is not done if the CI workflow is broken, missing relevant checks, or no longer reflects the project structure.

---

## Domain lifecycle

The core lifecycle artefacts are:

```text
Asset
PriceBar
FeatureSnapshot
Observation
Candidate
TriangleReview
RiskDecision
PaperOrder
PaperFill
Position
WatcherState
Alert
Outcome
SystemEvent
```

Preserve traceability:

```text
Position
  → PaperFill
  → PaperOrder
  → RiskDecision
  → TriangleReview
  → Candidate
  → Observations
  → FeatureSnapshot
  → PriceBar
```

Every major lifecycle transition should create a `SystemEvent`.

---

## Risk gate rule

All candidate paper trades must pass through the deterministic risk gate before paper execution.

The risk gate is not AI.

The MVP risk gate must enforce:

```text
execution_mode must be PAPER_ONLY
max_single_position_weight = 0.05
max_total_open_position_weight = 0.30
block if same asset already has an open position
block if latest data is stale
reduce size if triangle verdict is ALLOW_REDUCED_SIZE
require human review if review says HUMAN_REVIEW
block if review says BLOCK
```

---

## Manual approval rule

Paper trades require manual approval.

A candidate may only become a paper trade after:

```text
candidate exists
triangle review exists
risk decision exists
risk decision is not BLOCK
user explicitly approves paper execution
```

Blocked candidates must not be executable.

Rejected candidates must not be executable.

---

## UI rules

The UI must clearly label simulated trading activity.

Use wording such as:

```text
Paper Trade
Paper Position
Simulated Fill
Paper Portfolio
Execution Mode: PAPER_ONLY
```

Avoid misleading MVP wording such as:

```text
Live Trade
Real Order
Broker Position
Actual Fill
Trade Now
Place Order
```

The approval button should say:

```text
Approve Paper Trade
```

not:

```text
Buy
Execute
Trade Now
```

---

## Coding style

Keep code simple, explicit, and testable.

Prefer clear services over clever abstractions.

Prefer deterministic logic for trading/risk behaviour.

Use typed models where practical.

Use explicit status enums.

Fail closed on ambiguous safety states.

Do not log secrets.

Do not hardcode credentials.

Do not silently ignore invalid configuration.

---

## Dependency rules

Keep dependencies minimal, intentional, and documented.

Do not add dependencies casually.

If a chunk adds a dependency, explain:

```text
why it is needed
where it is used
whether it is runtime, development, or test-only
how it is pinned
how it is covered by CI
```

Prefer boring, well-maintained libraries.

Do not add frontend frameworks during the MVP unless explicitly requested.

Do not add trading, broker, or exchange SDKs during the MVP.

---

## Kubernetes rules

Use the project deployment structure:

```text
platform/k3d/
deploy/argocd/
deploy/k8s/base/
deploy/k8s/overlays/local/
```

The default namespace is:

```text
traderoo-poc
```

The local cluster name is:

```text
traderoo
```

Kubernetes config must include:

```text
EXECUTION_MODE=PAPER_ONLY
REVIEW_PROVIDER=mock
```

Do not add broker secrets.

Do not add Kubernetes Secrets containing real values.

When running local Kubernetes commands, only use the local k3d cluster named:

```text
traderoo
```

and the namespace:

```text
traderoo-poc
```

unless explicitly instructed otherwise.

Before running destructive commands, explain the command and request approval.

Destructive commands include:

```text
kubectl delete
k3d cluster delete
helm uninstall
kubectl patch
kubectl replace --force
kubectl apply --prune
kubectl rollout restart
commands that modify secrets
commands that switch Kubernetes context
```

Never run Kubernetes commands against an unknown or non-local context without explicit confirmation.

---

## Testing expectations

Add or update tests for important logic.

Examples:

```text
health endpoint test
database model test
duplicate-safe ingestion test
feature calculation test
observer rule test
candidate generation test
review schema test
risk gate blocking test
paper execution safety test
watcher transition test
outcome calculation test
secret handling test
```

Safety tests are mandatory for execution-related changes.

Secret-handling tests are mandatory for changes that introduce or consume secrets.

---

## Branch and PR workflow

When using VS Code Copilot Agent mode for implementation work, follow this workflow unless instructed otherwise:

```text
1. Check current branch and working tree state.
2. Create a feature branch for the requested chunk.
3. Implement only the requested chunk.
4. Run local tests and validation commands.
5. Run local Kubernetes validation only when relevant.
6. Commit the change.
7. Push the branch.
8. Create a draft pull request with GitHub CLI.
9. Include validation evidence in the PR body.
10. Stop after creating the draft PR.
```

Branch names should be short and chunk-oriented, for example:

```text
chunk-0-bootstrap
chunk-1-fastapi-skeleton
platform-ci-quality-gates
docs-secrets-management
```

Do not merge automatically.

Do not mark a PR ready until validation has passed.

Do not bypass GitHub review or CI.

---

## Pull request evidence

Each PR should include:

```text
chunk or task implemented
files changed
validation commands run
expected outputs observed
tests added or updated
CI checks expected to pass
known limitations
confirmation that PAPER_ONLY guardrails remain intact
confirmation that no real secrets were committed
confirmation that no broker credentials were added
```

If the PR changes Kubernetes manifests, include Kustomize validation evidence.

If the PR changes Python code, include test and quality-check evidence.

If the PR changes secret handling, include secret-safety validation evidence.

---

## Copilot behaviour

When asked to implement a chunk:

1. Read the relevant docs.
2. Restate the chunk scope briefly.
3. Identify out-of-scope items.
4. Check the current branch and working tree.
5. Create or use the agreed feature branch.
6. Implement the smallest working change.
7. Add tests.
8. Update docs only where needed.
9. Update CI where needed.
10. Provide validation commands and expected outputs.
11. Create a draft PR if requested.
12. Do not continue to the next chunk.

When unsure, ask before widening scope.

---

## Stop conditions

Stop and ask for clarification if a requested change would:

```text
introduce live trading
introduce broker credentials
introduce real-money execution
weaken PAPER_ONLY guardrails
commit real secrets
add Vault implementation outside an approved platform chunk
weaken or remove CI checks
change the repository structure significantly
implement future chunks early
require destructive local Kubernetes commands
```

Do not work around these constraints silently.
