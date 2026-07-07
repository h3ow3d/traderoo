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
docs/safety/paper-only-guardrails.md
docs/safety/ai-boundaries.md
docs/c4/01-system-context.md
docs/c4/02-container-view.md
docs/c4/03-component-view.md
docs/adr/0001-local-kubernetes-with-k3d.md
docs/adr/0002-gitops-with-argocd.md
docs/adr/0003-paper-only-mvp.md
docs/adr/0004-project-structure.md
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
production secret management
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
```

Safety tests are mandatory for execution-related changes.

---

## Copilot behaviour

When asked to implement a chunk:

1. Read the relevant docs.
2. Restate the chunk scope briefly.
3. Identify out-of-scope items.
4. Implement the smallest working change.
5. Add tests.
6. Update docs only where needed.
7. Provide validation commands and expected outputs.
8. Do not continue to the next chunk.

When unsure, ask before widening scope.
