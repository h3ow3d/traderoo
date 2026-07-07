# Traderoo Delivery Chunk Plan

## 1. Purpose

This document defines the incremental delivery plan for Traderoo.

Traderoo will be built in small, validated chunks so that each subsystem can be implemented, tested, and reviewed before the next subsystem is added.

The goal is to avoid a large, partially working AI-generated prototype. Each chunk should produce a working, testable state.

---

## 2. Delivery principles

### 2.1 Small chunks

Each chunk should introduce one major capability only.

Avoid implementing future chunks early.

### 2.2 Validate before continuing

Do not move to the next chunk until the current chunk passes its acceptance criteria.

### 2.3 Paper-only throughout MVP

The MVP must remain paper-only.

The only permitted execution mode is:

```text
PAPER_ONLY
```

### 2.4 Modular monolith first

Traderoo should start as a modular monolith.

The codebase may have clear packages/modules, but it should not be prematurely split into microservices.

### 2.5 AI does not execute trades

OpenAI or local models may analyse, summarise, and review candidate trades.

They must not place orders, bypass risk controls, or modify strategy logic live.

### 2.6 Deterministic risk gate

All candidate trades must pass through a deterministic risk gate before paper execution.

### 2.7 Every chunk updates docs

Each chunk should update relevant docs, including setup notes, validation commands, or subsystem documentation where appropriate.

---

## 3. Chunk overview

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

---

# Chunk 0 — Platform and repository bootstrap

## Goal

Create the local Kubernetes, GitOps, repository, manifest, and documentation foundation for Traderoo.

This chunk should leave the project with an empty-but-working GitOps path.

## In scope

* repository structure
* k3d cluster spec
* Kubernetes manifest structure
* Kustomize base and local overlay
* Argo CD Application manifest
* platform/application ownership boundary documentation
* documentation skeleton
* Makefile targets for cluster and Argo CD operations
* placeholder namespace and ConfigMap
* local validation path

## Out of scope

* FastAPI application
* database
* market data ingestion
* OpenAI integration
* trading logic
* paper execution
* dashboard
* GitHub Actions
* container image build
* platform-services wrapper chart implementation
* Vault implementation
* External Secrets Operator implementation

## Expected files

```text
app/.gitkeep
applications/traderoo/argocd/application.yaml
applications/traderoo/k8s/base/namespace.yaml
applications/traderoo/k8s/base/configmap.yaml
applications/traderoo/k8s/base/kustomization.yaml
applications/traderoo/k8s/overlays/local/kustomization.yaml
applications/traderoo/k8s/overlays/local/configmap-patch.yaml
platform/k3d/cluster.yaml
platform/bootstrap/argocd/install.md
platform/bootstrap/argocd/root-platform-application.yaml
platform/bootstrap/argocd/root-applications-application.yaml
docs/hld.md
docs/adr/0001-local-kubernetes-with-k3d.md
docs/adr/0002-gitops-with-argocd.md
docs/adr/0003-paper-only-mvp.md
docs/adr/0004-project-structure.md
docs/delivery/chunk-plan.md
docs/setup/00-prerequisites.md
docs/setup/01-local-cluster.md
docs/setup/02-argocd.md
docs/setup/03-github-repo.md
docs/setup/04-validation.md
README.md
Makefile
.gitignore
```

## Acceptance criteria

* `make cluster-create` creates the k3d cluster.
* `kubectl get nodes` works.
* `make argocd-install` installs Argo CD.
* `make argocd-password` prints the initial admin password.
* `make argocd-port-forward` exposes Argo CD at `https://localhost:8081`.
* `make validate-k8s-local` applies the local Kustomize overlay directly.
* `kubectl get configmap traderoo-config -n traderoo-poc` works.
* Argo CD Application can be applied after replacing the placeholder repository URL.
* Argo CD syncs the placeholder namespace and ConfigMap.
* ADR `0006-separate-platform-services-from-application-gitops.md` documents platform versus application ownership boundaries.
* No application code exists yet.

## Validation commands

```bash
make cluster-create
kubectl get nodes

make argocd-install
kubectl get pods -n argocd

make validate-k8s-local
kubectl get ns traderoo-poc
kubectl get configmap traderoo-config -n traderoo-poc -o yaml
```

---

# Chunk 1 — Runnable FastAPI skeleton

## Goal

Create a minimal runnable application that can run locally and in Kubernetes.

## In scope

* FastAPI application
* `/health` endpoint
* placeholder dashboard page
* environment-based config
* Dockerfile
* basic Kubernetes deployment/service
* local run commands
* tests for health endpoint

## Out of scope

* database
* market data
* trading logic
* OpenAI
* dashboard functionality
* Postgres
* workers

## Expected capability

Traderoo should respond to:

```text
GET /health
```

with:

```json
{"status": "ok"}
```

The root page should show a simple placeholder Traderoo dashboard.

## Acceptance criteria

Local:

* `make install` works.
* `make run` starts the app.
* `curl http://localhost:8000/health` returns `{"status":"ok"}`.
* `make test` passes.

Kubernetes:

* app image can be built.
* manifests deploy the app into `traderoo-poc`.
* service can be port-forwarded.
* `/health` works through the port-forward.

## Validation commands

```bash
make install
make test
make run
curl http://localhost:8000/health
```

Kubernetes validation:

```bash
make docker-build
make k8s-apply
make k8s-port-forward
curl http://localhost:8000/health
```

---

# Chunk 2 — Postgres and core schema

## Goal

Add durable system memory.

Traderoo should be able to persist assets, events, and the initial trading lifecycle tables.

## In scope

* Postgres deployment for local Kubernetes
* database connection configuration
* SQLAlchemy or SQLModel setup
* initial database models
* init-db worker/command
* seed-data worker/command
* basic API endpoints for assets and system events
* dashboard display of asset count and recent events

## Core tables

```text
assets
price_bars
feature_snapshots
observations
candidates
triangle_reviews
risk_decisions
paper_orders
paper_fills
positions
watcher_states
alerts
outcomes
system_events
```

## Seed assets

```text
SPY
QQQ
IWM
GLD
TLT
VUSA.L
VWRL.L
```

## Out of scope

* market data ingestion
* feature calculations
* observations
* candidates
* OpenAI
* paper execution

## Acceptance criteria

* Postgres runs locally/in Kubernetes.
* database init command creates tables.
* seed command inserts assets.
* `GET /api/assets` returns seeded assets.
* dashboard shows seeded asset count.
* tests pass.

## Validation commands

```bash
python -m app.workers.init_db
python -m app.workers.seed_data
curl http://localhost:8000/api/assets
```

Kubernetes validation:

```bash
make k8s-init-db
make k8s-seed
kubectl logs -n traderoo-poc job/init-db
kubectl logs -n traderoo-poc job/seed-data
```

---

# Chunk 3 — Market data ingestion

## Goal

Ingest daily OHLCV market data for the watchlist.

## In scope

* `yfinance` dependency
* ingestion service
* price bar persistence
* duplicate-safe inserts
* ingestion system events
* ingestion worker command
* asset latest-price endpoint
* asset price-history endpoint
* dashboard latest prices
* Kubernetes ingestion CronJob or Job

## MVP source

```text
yfinance
```

This is POC-grade only.

## Required metadata

Every ingested price bar should include:

```text
asset
source
price date
open
high
low
close
volume
ingested_at
```

## Out of scope

* feature generation
* observations
* candidates
* OpenAI
* broker integration

## Acceptance criteria

* ingestion worker populates `price_bars`.
* re-running ingestion does not create duplicate price bars.
* dashboard shows latest prices.
* `GET /api/assets/{symbol}/latest` returns latest stored price data.
* tests verify duplicate-safe insertion.

## Validation commands

```bash
python -m app.workers.ingest_prices
curl http://localhost:8000/api/assets/QQQ/latest
```

Kubernetes validation:

```bash
make k8s-run-ingest
kubectl logs -n traderoo-poc job/ingest-prices
```

---

# Chunk 4 — Feature generation and observations

## Goal

Convert stored prices into features and observations.

## In scope

Feature builder:

* daily return
* 20-day return
* 50-day return
* 20-day volatility
* 50-day moving average
* 200-day moving average
* price above 200-day moving average
* 50-day moving average above 200-day moving average
* drawdown from 252-day high
* 50-day relative strength versus benchmark

Observers:

* Trend Observer
* Volatility Observer
* Relative Strength Observer
* Drawdown Observer

Observation types:

```text
positive_trend
negative_trend
elevated_volatility
positive_relative_strength
deep_drawdown
```

## Out of scope

* candidate trades
* AI review
* paper execution
* risk gate

## Acceptance criteria

* feature builder creates feature snapshots after ingestion.
* observers create observations from latest features.
* asset page shows latest features.
* asset page shows observation timeline.
* tests validate feature calculations on sample data.

## Validation commands

```bash
python -m app.workers.build_features
python -m app.workers.run_observers

curl http://localhost:8000/api/assets/QQQ/features/latest
curl http://localhost:8000/api/assets/QQQ/observations
```

Kubernetes validation:

```bash
make k8s-run-features
make k8s-run-observers
```

---

# Chunk 5 — Candidate generation

## Goal

Convert observations into candidate paper trades.

## In scope

* candidate generator service
* candidate lifecycle
* candidate API endpoints
* candidates page
* candidate detail page
* system events for candidate creation

## MVP candidate rule

Create a BUY candidate when:

```text
latest positive_trend observation exists
latest positive_relative_strength observation exists
volatility is not elevated
no open paper position already exists for the same asset
```

## Candidate fields

```text
candidate_id
asset_id
action
strategy_version
time_horizon
proposed_target_weight
thesis
source_observation_ids
status
created_at
```

## Candidate status values

```text
PENDING_REVIEW
REVIEWED
RISK_ASSESSED
APPROVED_FOR_PAPER
REJECTED
EXECUTED_PAPER
BLOCKED
```

## Out of scope

* OpenAI
* triangle review
* risk gate
* paper execution

## Acceptance criteria

* candidate generator creates candidates when rules match.
* duplicate pending candidates are not repeatedly created.
* candidates page shows pending candidates.
* candidate detail page shows thesis, source observations, and latest features.
* tests validate candidate rules.

## Validation commands

```bash
python -m app.workers.generate_candidates
curl http://localhost:8000/api/candidates
```

Kubernetes validation:

```bash
make k8s-run-candidates
```

---

# Chunk 6 — Mock triangle review

## Goal

Review candidate trades against the trade triangle using a deterministic mock provider.

## In scope

* `ReviewProvider` interface
* `MockReviewProvider`
* triangle review persistence
* review worker
* review API
* review card on candidate detail page
* tests for mock review output

## Trade triangle

```text
Signal / Edge
Safety / Risk
Situation / Context
```

## Review fields

```text
candidate_id
edge_score
risk_score
context_score
confidence
verdict
position_size_multiplier
edge_summary
risk_summary
context_summary
blocking_risks
watcher_rules
review_horizon_days
created_at
```

## Valid review verdicts

```text
ALLOW
ALLOW_REDUCED_SIZE
HUMAN_REVIEW
BLOCK
```

## Out of scope

* OpenAI
* risk gate
* paper execution
* live trading

## Acceptance criteria

* pending candidates can be reviewed.
* review result is stored.
* candidate status becomes `REVIEWED`.
* candidate detail page shows Edge/Risk/Context scores and verdict.
* tests pass.

## Validation commands

```bash
python -m app.workers.review_candidates
curl http://localhost:8000/api/candidates/{candidate_id}/review
```

Kubernetes validation:

```bash
make k8s-run-reviews
```

---

# Chunk 7 — Deterministic risk gate

## Goal

Add the final rule-based control layer before paper execution.

## In scope

* risk policy engine
* position sizing
* risk decision persistence
* risk worker
* risk API
* risk card on candidate detail page
* tests for risk gate rules

## MVP risk rules

```text
execution_mode must always be PAPER_ONLY
max_single_position_weight = 0.05
max_total_open_position_weight = 0.30
block if same asset already has an open position
block if latest data is stale
reduce size if triangle verdict is ALLOW_REDUCED_SIZE
require human review if triangle review says HUMAN_REVIEW
block if triangle verdict is BLOCK
```

## Risk decision results

```text
PASS
PASS_WITH_REDUCED_SIZE
HUMAN_REVIEW_REQUIRED
BLOCK
```

## Out of scope

* paper order creation
* manual approval
* live broker integration
* OpenAI

## Acceptance criteria

* reviewed candidates receive risk decisions.
* blocked candidates cannot progress.
* reduced-size candidates get reduced approved target weight.
* risk card appears in UI.
* tests verify key risk rules.
* execution mode remains paper-only.

## Validation commands

```bash
python -m app.workers.run_risk_gate
curl http://localhost:8000/api/candidates/{candidate_id}/risk-decision
```

Kubernetes validation:

```bash
make k8s-run-risk
```

---

# Chunk 8 — Manual approval and paper execution

## Goal

Allow a user to approve risk-approved candidates and open simulated paper positions.

## In scope

* candidate approval action
* candidate rejection action
* paper execution service
* paper order creation
* simulated paper fill creation
* paper position creation
* positions API
* positions page
* open position section on asset page
* tests for approval and paper execution

## Paper execution behaviour

When approved:

```text
create paper_order
create paper_fill using latest close price
create open position
link position to candidate, triangle review, and risk decision
record system event
```

## Out of scope

* real broker integration
* live execution
* automatic approval
* automatic position closing

## Acceptance criteria

* user can approve a risk-approved candidate in the UI.
* approval creates paper order, paper fill, and open position.
* blocked candidates cannot be approved.
* positions page shows the new open paper position.
* asset page shows the open paper position.
* tests pass.
* no live broker adapter exists.

## Validation commands

Manual UI validation:

```text
Open Candidates page.
Open reviewed and risk-approved candidate.
Click Approve Paper Trade.
Open Positions page.
Confirm open paper position exists.
```

API validation:

```bash
curl -X POST http://localhost:8000/api/candidates/{candidate_id}/approve-paper
curl http://localhost:8000/api/positions
```

---

# Chunk 9 — Position watchers and alerts

## Goal

Monitor open paper positions and emit alerts when thesis or risk conditions change.

## In scope

* watcher service
* watcher state persistence
* alert persistence
* watcher worker
* watcher API
* alerts API
* alerts page
* watcher section on asset page
* watcher status on positions page
* tests for watcher state transitions

## Watcher checks

For each open position:

```text
return_since_entry
drawdown_since_entry
price_above_200dma
relative_strength_positive
volatility_state
review_due
```

## Watcher states

```text
NORMAL
CAUTION
THESIS_WEAKENING
THESIS_INVALIDATED
```

## Alert triggers

```text
drawdown since entry <= -3%
price closes below 200DMA
relative strength turns negative
review date due
```

## Out of scope

* automatic trade closure
* live notifications
* broker interaction
* local model watcher

## Acceptance criteria

* running watchers creates watcher states for open positions.
* alerts are created when rules are breached.
* positions page shows watcher status.
* asset page shows watcher analysis.
* alerts page shows active alerts.
* tests pass.

## Validation commands

```bash
python -m app.workers.run_watchers
curl http://localhost:8000/api/alerts
curl http://localhost:8000/api/positions/{position_id}/watcher-states
```

Kubernetes validation:

```bash
make k8s-run-watchers
```

---

# Chunk 10 — Outcome evaluation and performance dashboard

## Goal

Evaluate whether paper trade decisions worked and expose performance views.

## In scope

* outcome evaluator
* outcome persistence
* performance summary API
* performance page
* outcome section on asset page
* strategy summary table
* tests with synthetic price data

## Evaluation horizons

```text
1d
5d
20d
60d
```

## Outcome metrics

```text
asset_return
benchmark_return
excess_return
max_adverse_excursion
max_favourable_excursion
outcome_label
```

## Outcome labels

```text
PENDING
WORKED
FAILED
MIXED
```

## Out of scope

* automatic strategy modification
* live trading
* machine learning retraining
* strategy promotion automation

## Acceptance criteria

* outcomes are created when enough future price data exists.
* performance page shows high-level summary.
* asset page shows outcome history.
* tests pass.

## Validation commands

```bash
python -m app.workers.evaluate_outcomes
curl http://localhost:8000/api/outcomes
curl http://localhost:8000/api/performance/summary
```

Kubernetes validation:

```bash
make k8s-run-outcomes
```

---

# Chunk 11 — Optional OpenAI review provider

## Goal

Add an optional OpenAI-backed triangle review provider behind the same provider interface.

## In scope

* `OpenAIReviewProvider`
* provider selection via environment variable
* evidence pack builder
* structured JSON schema validation
* failure-safe handling of invalid model output
* tests with fake OpenAI client
* documentation for configuration

## Provider selection

```text
REVIEW_PROVIDER=mock
REVIEW_PROVIDER=openai
```

## Required environment variables

```text
OPENAI_API_KEY
OPENAI_MODEL
```

## Evidence pack contents

```text
candidate
source observations
latest features
current portfolio state
prior similar decisions/outcomes if available
```

## Safety requirements

OpenAI must:

```text
analyse only
return structured JSON only
not place trades
not bypass risk gate
not modify strategy live
not call broker/execution code
```

## Out of scope

* OpenAI function calling for execution
* live trading
* autonomous trade approval
* RAG/news ingestion
* local model watchers

## Acceptance criteria

* mock provider still works.
* OpenAI provider can be selected by env var.
* output is validated against schema.
* invalid model output is rejected safely.
* review failure does not permit paper execution.
* tests pass with fake client.

## Validation commands

Mock mode:

```bash
REVIEW_PROVIDER=mock python -m app.workers.review_candidates
```

OpenAI mode:

```bash
REVIEW_PROVIDER=openai OPENAI_MODEL=<model> python -m app.workers.review_candidates
```

---

# Chunk 12 — Kubernetes polish

## Goal

Make the full POC easy to run on the local Kubernetes cluster.

## In scope

* Kubernetes manifests for all app components
* Postgres manifests
* backend deployment
* services
* ConfigMaps
* Secret templates
* init and seed Jobs
* CronJobs for workers
* Makefile targets for all common operations
* README end-to-end run instructions
* final validation journey

## Required Makefile targets

```text
cluster-create
cluster-delete
cluster-status
argocd-install
argocd-password
argocd-port-forward
argocd-apply-app
argocd-sync
argocd-get
k8s-init-db
k8s-seed
k8s-run-ingest
k8s-run-features
k8s-run-observers
k8s-run-candidates
k8s-run-reviews
k8s-run-risk
k8s-run-watchers
k8s-run-outcomes
k8s-port-forward
k8s-delete
```

## Out of scope

* production hardening
* live broker integration
* public exposure
* authentication
* service mesh
* advanced observability stack

## Acceptance criteria

The full paper-only journey can be run on local Kubernetes:

```text
1. init database
2. seed assets
3. ingest prices
4. build features
5. create observations
6. create candidates
7. review candidates
8. risk gate candidates
9. approve paper trade
10. create paper position
11. run watchers
12. evaluate outcomes
13. view dashboard and asset page
```

---

## 4. Full MVP acceptance journey

Traderoo MVP is complete when this workflow works end to end:

```text
1. Traderoo runs on local k3d.
2. Argo CD syncs Traderoo manifests from GitHub.
3. Postgres stores system memory.
4. Assets are seeded.
5. Daily prices are ingested.
6. Features are generated.
7. Observations are emitted.
8. Candidate trades are generated.
9. Triangle reviews are completed.
10. Risk decisions are applied.
11. User approves a paper trade.
12. Paper order, fill, and position are created.
13. Watchers monitor the position.
14. Alerts appear when rules are breached.
15. Outcomes are evaluated after defined horizons.
16. Dashboard shows the full lifecycle.
17. Asset page shows observation-to-outcome traceability.
```

---

## 5. Standard Copilot instruction for each chunk

When asking Copilot to implement a chunk, use this pattern:

```text
Implement only the requested chunk.

Before coding:
- Read docs/hld.md.
- Read docs/delivery/chunk-plan.md.
- Read relevant ADRs.
- Confirm what is in scope and out of scope.

During coding:
- Keep implementation simple.
- Do not implement future chunks.
- Do not add live trading.
- Keep execution mode PAPER_ONLY.
- Add tests for the new capability.
- Update docs only where relevant.

After coding:
- List files changed.
- Provide validation commands.
- Provide expected outputs.
- State known limitations.
- State what remains for the next chunk.
```

---

## 6. Standard definition of done

A chunk is done only when:

```text
Required files exist.
Code runs locally where applicable.
Kubernetes manifests validate where applicable.
Tests pass.
Docs are updated where applicable.
Validation commands are documented.
No future chunk functionality was added early.
No safety guardrail was weakened.
Execution remains PAPER_ONLY.
```

---

## 7. Safety reminder

Traderoo is a paper-only trading control plane POC.

During the MVP, the system must not:

```text
place real trades
connect to a real broker for order execution
store real broker credentials
use leverage
use CFDs
use spread betting
trade options
execute autonomously with real money
allow AI to bypass deterministic controls
```

Any future change that introduces live broker connectivity requires a new ADR.
