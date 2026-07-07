# Traderoo Delivery Validation Matrix

## 1. Purpose

This document defines how each Traderoo delivery chunk should be validated.

Traderoo will be built incrementally. Each chunk must leave the project in a working, testable state before the next chunk begins.

The goal is to avoid building a large, partially working prototype.

---

## 2. Validation principles

## 2.1 Validate every chunk

Every chunk must include:

* clear acceptance criteria
* validation commands
* expected outputs
* tests where applicable
* documentation updates where applicable

## 2.2 Do not continue on broken foundations

Do not start the next chunk until the current chunk passes validation.

## 2.3 Keep future functionality out

A chunk should not implement future chunk functionality early unless explicitly approved.

## 2.4 Maintain paper-only guardrails

Every chunk must preserve:

```text id="cqqe7l"
EXECUTION_MODE=PAPER_ONLY
```

No chunk may introduce live trading, broker credentials, real orders, leverage, CFDs, spread betting, or options.

## 2.5 Prefer repeatable commands

Validation should be repeatable through:

```text id="dxb67b"
make targets
python worker commands
kubectl commands
curl commands
pytest
```

---

# 3. Chunk validation matrix

## Chunk 0 — Platform and repository bootstrap

| Area                 | Validation                                                         |
| -------------------- | ------------------------------------------------------------------ |
| Repository structure | Required folders and docs exist                                    |
| k3d cluster          | Cluster can be created from `platform/k3d/cluster.yaml`            |
| Platform chart       | `platform-services` Helm chart lints and templates                 |
| Kubernetes manifests | Kustomize local overlay applies successfully                       |
| Argo CD              | Argo CD installs and UI is reachable                               |
| GitOps               | Argo CD Application can sync placeholder manifests                 |
| Platform boundary    | ADR 0006 defines platform services vs application ownership        |
| Safety               | No app code, database, trading logic, or OpenAI integration exists |

### Commands

```bash id="0qyu8x"
make cluster-create
kubectl get nodes

make argocd-install
kubectl get pods -n argocd

helm lint platform/charts/platform-services
helm template platform-services platform/charts/platform-services --dry-run=client > /tmp/platform-services.yaml
grep -E "kind: AppProject|name: platform|name: applications" /tmp/platform-services.yaml

make validate-k8s-local
kubectl get ns traderoo-poc
kubectl get configmap traderoo-config -n traderoo-poc -o yaml

test -f docs/adr/0006-separate-platform-services-from-application-gitops.md
```

### Expected result

```text id="wv2uum"
Local k3d cluster exists.
Argo CD is running.
Platform chart renders AppProjects for platform and applications.
traderoo-poc namespace exists.
traderoo-config ConfigMap exists.
EXECUTION_MODE is PAPER_ONLY.
Platform/application ownership boundary is documented in ADR 0006.
```

---

## Chunk 1 — Runnable FastAPI skeleton

| Area                  | Validation                              |
| --------------------- | --------------------------------------- |
| Local app             | FastAPI starts locally                  |
| Health endpoint       | `/health` returns ok                    |
| Placeholder dashboard | `/` returns a basic Traderoo page       |
| Tests                 | health endpoint test passes             |
| Kubernetes            | app can run in cluster                  |
| Safety                | no database/trading/OpenAI logic exists |

### Commands

```bash id="5eqmsr"
make install
make test
make run
curl http://localhost:8000/health
```

Kubernetes:

```bash id="900s7b"
make docker-build
make k8s-apply
make k8s-port-forward
curl http://localhost:8000/health
```

### Expected result

```json id="onvzmm"
{"status":"ok"}
```

---

## Chunk 2 — Postgres and core schema

| Area      | Validation                               |
| --------- | ---------------------------------------- |
| Postgres  | database runs locally/in Kubernetes      |
| Schema    | core tables are created                  |
| Seed data | seed assets are inserted                 |
| API       | `/api/assets` returns seeded assets      |
| Dashboard | shows asset count and recent events      |
| Tests     | model and API tests pass                 |
| Safety    | no ingestion/trading/OpenAI logic exists |

### Commands

```bash id="ew3krm"
python -m app.workers.init_db
python -m app.workers.seed_data
curl http://localhost:8000/api/assets
```

Kubernetes:

```bash id="5kup74"
make k8s-init-db
make k8s-seed
kubectl logs -n traderoo-poc job/init-db
kubectl logs -n traderoo-poc job/seed-data
```

### Expected result

Seeded assets include:

```text id="1kqvl4"
SPY
QQQ
IWM
GLD
TLT
VUSA.L
VWRL.L
```

---

## Chunk 3 — Market data ingestion

| Area        | Validation                               |
| ----------- | ---------------------------------------- |
| Ingestion   | yfinance data can be fetched             |
| Persistence | daily OHLCV bars are stored              |
| Idempotency | repeated runs do not duplicate rows      |
| API         | latest price endpoint works              |
| Dashboard   | latest prices are visible                |
| Tests       | duplicate-safe insertion is tested       |
| Safety      | no signals/candidates/trades are created |

### Commands

```bash id="rbr7t2"
python -m app.workers.ingest_prices
curl http://localhost:8000/api/assets/QQQ/latest
```

Kubernetes:

```bash id="vhc9rk"
make k8s-run-ingest
kubectl logs -n traderoo-poc job/ingest-prices
```

### Expected result

```text id="gth0o7"
price_bars contains records.
Latest price endpoint returns stored data.
Re-running ingestion does not create duplicates.
```

---

## Chunk 4 — Feature generation and observations

| Area         | Validation                                                |
| ------------ | --------------------------------------------------------- |
| Features     | feature snapshots are generated                           |
| Observations | observations are emitted from features                    |
| API          | latest features and observations endpoints work           |
| UI           | asset page shows features and timeline                    |
| Tests        | feature calculations are tested                           |
| Safety       | no candidate trades are created yet unless Chunk 5 exists |

### Commands

```bash id="obho73"
python -m app.workers.build_features
python -m app.workers.run_observers

curl http://localhost:8000/api/assets/QQQ/features/latest
curl http://localhost:8000/api/assets/QQQ/observations
```

Kubernetes:

```bash id="tkc1r8"
make k8s-run-features
make k8s-run-observers
```

### Expected result

```text id="2ja3gd"
feature_snapshots contains latest features.
observations contains market-condition observations.
Asset page shows features and observation timeline.
```

---

## Chunk 5 — Candidate generation

| Area            | Validation                                              |
| --------------- | ------------------------------------------------------- |
| Candidate rules | valid observations create candidates                    |
| Deduplication   | duplicate pending candidates are not repeatedly created |
| API             | candidate endpoints work                                |
| UI              | candidate list and detail pages work                    |
| Tests           | candidate rule tests pass                               |
| Safety          | candidates do not execute or approve themselves         |

### Commands

```bash id="ufp0by"
python -m app.workers.generate_candidates
curl http://localhost:8000/api/candidates
```

Kubernetes:

```bash id="doe62w"
make k8s-run-candidates
```

### Expected result

```text id="ahie54"
Eligible assets may produce PENDING_REVIEW candidates.
No paper order, fill, or position is created.
```

---

## Chunk 6 — Mock triangle review

| Area             | Validation                                    |
| ---------------- | --------------------------------------------- |
| Review provider  | MockReviewProvider returns structured review  |
| Schema           | review output is valid                        |
| Persistence      | triangle review is stored                     |
| Candidate status | candidate becomes REVIEWED                    |
| UI               | candidate detail page shows Edge/Risk/Context |
| Tests            | mock provider tests pass                      |
| Safety           | review does not execute trades                |

### Commands

```bash id="r4ymbi"
python -m app.workers.review_candidates
curl http://localhost:8000/api/candidates/{candidate_id}/review
```

Kubernetes:

```bash id="0zeqmm"
make k8s-run-reviews
```

### Expected result

Review contains:

```text id="21ndb8"
edge_score
risk_score
context_score
verdict
watcher_rules
```

No order or position is created.

---

## Chunk 7 — Deterministic risk gate

| Area            | Validation                                 |
| --------------- | ------------------------------------------ |
| Risk rules      | reviewed candidates receive risk decisions |
| Blocking        | unsafe candidates are blocked              |
| Position sizing | reduced-size decisions are sized correctly |
| API             | risk decision endpoint works               |
| UI              | risk card appears                          |
| Tests           | key risk rules tested                      |
| Safety          | execution mode remains PAPER_ONLY          |

### Commands

```bash id="2ziak5"
python -m app.workers.run_risk_gate
curl http://localhost:8000/api/candidates/{candidate_id}/risk-decision
```

Kubernetes:

```bash id="t12jrd"
make k8s-run-risk
```

### Expected result

Risk decision is one of:

```text id="rdyf21"
PASS
PASS_WITH_REDUCED_SIZE
HUMAN_REVIEW_REQUIRED
BLOCK
```

No paper trade is created yet.

---

## Chunk 8 — Manual approval and paper execution

| Area            | Validation                                            |
| --------------- | ----------------------------------------------------- |
| Manual approval | eligible candidates can be approved                   |
| Rejection       | candidates can be rejected                            |
| Paper execution | paper order, fill, and position are created           |
| Traceability    | position links back to candidate/review/risk decision |
| UI              | positions page and asset page show position           |
| Tests           | blocked candidates cannot execute                     |
| Safety          | no real broker adapter exists                         |

### Commands

```bash id="npkv6w"
curl -X POST http://localhost:8000/api/candidates/{candidate_id}/approve-paper
curl http://localhost:8000/api/positions
```

Manual UI validation:

```text id="e9ur8n"
Open Candidates page.
Open eligible candidate.
Click Approve Paper Trade.
Open Positions page.
Confirm open paper position exists.
```

### Expected result

Created records:

```text id="jjo9pt"
paper_order
paper_fill
position
system_event
```

Execution mode remains:

```text id="xazohv"
PAPER_ONLY
```

---

## Chunk 9 — Position watchers and alerts

| Area           | Validation                                           |
| -------------- | ---------------------------------------------------- |
| Watcher states | open positions receive watcher state                 |
| Alerts         | alerts are created when rules are breached           |
| API            | watcher state and alerts endpoints work              |
| UI             | positions, asset, and alerts pages show watcher data |
| Tests          | watcher transitions tested                           |
| Safety         | watchers do not execute trades                       |

### Commands

```bash id="bb0kzk"
python -m app.workers.run_watchers
curl http://localhost:8000/api/alerts
curl http://localhost:8000/api/positions/{position_id}/watcher-states
```

Kubernetes:

```bash id="uodc3n"
make k8s-run-watchers
```

### Expected result

Watcher state is one of:

```text id="8gd069"
NORMAL
CAUTION
THESIS_WEAKENING
THESIS_INVALIDATED
```

Alerts appear when thresholds are breached.

---

## Chunk 10 — Outcome evaluation and performance dashboard

| Area     | Validation                                        |
| -------- | ------------------------------------------------- |
| Outcomes | positions are evaluated after horizons            |
| Metrics  | returns and benchmark comparison calculated       |
| API      | outcomes and performance endpoints work           |
| UI       | performance page and asset outcome section work   |
| Tests    | synthetic data tests pass                         |
| Safety   | outcomes do not modify strategy or execute trades |

### Commands

```bash id="bxk8bt"
python -m app.workers.evaluate_outcomes
curl http://localhost:8000/api/outcomes
curl http://localhost:8000/api/performance/summary
```

Kubernetes:

```bash id="g5a41b"
make k8s-run-outcomes
```

### Expected result

Outcome labels are one of:

```text id="przwtp"
PENDING
WORKED
FAILED
MIXED
```

Performance page shows summary.

---

## Chunk 11 — Optional OpenAI review provider

| Area              | Validation                                              |
| ----------------- | ------------------------------------------------------- |
| Provider switch   | mock and OpenAI providers selectable by env var         |
| Evidence pack     | review input contains candidate, observations, features |
| Schema validation | OpenAI output must match schema                         |
| Failure behaviour | invalid output fails closed                             |
| Tests             | fake client tests pass                                  |
| Safety            | OpenAI cannot execute or bypass risk gate               |

### Commands

Mock mode:

```bash id="r8atfg"
REVIEW_PROVIDER=mock python -m app.workers.review_candidates
```

OpenAI mode:

```bash id="6ieplm"
REVIEW_PROVIDER=openai OPENAI_MODEL=<model> python -m app.workers.review_candidates
```

### Expected result

```text id="kdpxzn"
Mock provider still works.
OpenAI provider validates structured output.
Invalid output does not permit execution.
```

---

## Chunk 12 — Kubernetes polish

| Area      | Validation                          |
| --------- | ----------------------------------- |
| Manifests | all required workloads exist        |
| Jobs      | init, seed, and worker jobs can run |
| CronJobs  | scheduled worker definitions exist  |
| Makefile  | operational targets work            |
| README    | end-to-end run instructions exist   |
| GitOps    | Argo CD syncs desired state         |
| Safety    | no live trading config exists       |

### Commands

```bash id="f58fvr"
make k8s-init-db
make k8s-seed
make k8s-run-ingest
make k8s-run-features
make k8s-run-observers
make k8s-run-candidates
make k8s-run-reviews
make k8s-run-risk
make k8s-run-watchers
make k8s-run-outcomes
make k8s-port-forward
```

### Expected result

The full paper-only journey can be run on local Kubernetes.

---

# 4. Full end-to-end MVP validation

The MVP is valid when this journey works:

```text id="k3bats"
1. Traderoo runs on local k3d.
2. Argo CD syncs manifests from GitHub.
3. Postgres stores system memory.
4. Assets are seeded.
5. Daily prices are ingested.
6. Features are generated.
7. Observations are emitted.
8. Candidates are generated.
9. Triangle reviews are completed.
10. Risk decisions are applied.
11. User approves a paper trade.
12. Paper order, fill, and position are created.
13. Watchers monitor the position.
14. Alerts appear when rules are breached.
15. Outcomes are evaluated after defined horizons.
16. Dashboard shows the lifecycle.
17. Asset page shows traceability from observation to outcome.
```

---

# 5. Universal validation checklist

Before a chunk is accepted, confirm:

```text id="tcxnkg"
Tests pass.
New docs are updated.
Validation commands are documented.
Expected outputs are documented.
No future chunk was implemented early.
No live trading code was added.
No broker credentials were added.
Execution mode remains PAPER_ONLY.
Risk gate remains mandatory.
Manual approval remains required before paper execution.
```

---

# 6. Failure handling

If a chunk fails validation:

```text id="up47av"
Do not continue to the next chunk.
Record the failure.
Fix the current chunk.
Re-run validation.
Only proceed once validation passes.
```

---

# 7. Copilot validation instruction

When asking Copilot to validate a chunk, use this instruction:

```text id="1fbext"
Validate the current chunk against docs/delivery/validation-matrix.md.

Check:
- acceptance criteria
- tests
- expected commands
- safety guardrails
- out-of-scope violations

Do not implement the next chunk.
List any gaps before making changes.
```
