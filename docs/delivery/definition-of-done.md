# Traderoo Definition of Done

## 1. Purpose

This document defines what “done” means for a Traderoo delivery chunk.

Traderoo is being built incrementally. Each chunk must leave the project in a working, safe, documented, and validated state before the next chunk begins.

The goal is to prevent the project from becoming a large, partially working prototype.

---

## 2. Universal definition of done

A Traderoo chunk is done only when all of the following are true:

```text id="a1kx89"
The requested scope is implemented.
The implementation is small and focused.
The chunk does not implement future chunks early.
Tests pass.
Validation commands are documented.
Expected outputs are documented.
Relevant docs are updated.
Safety guardrails are preserved.
Execution mode remains PAPER_ONLY.
No live broker integration exists.
No real-money trading path exists.
```

---

## 3. Scope completion

A chunk must implement the specific capability described in:

```text id="cxuwmd"
docs/delivery/chunk-plan.md
```

A chunk must not add future functionality unless explicitly approved.

Examples:

```text id="rj7kgy"
Chunk 3 may ingest prices.
Chunk 3 must not create observations.
Chunk 5 may create candidate trades.
Chunk 5 must not review or execute them.
Chunk 6 may review candidates.
Chunk 6 must not run the risk gate.
Chunk 8 may create paper trades.
Chunk 8 must not add broker integration.
```

---

## 4. Safety completion

Every chunk must preserve the MVP safety constraints.

Traderoo must remain:

```text id="e876i7"
PAPER_ONLY
```

A chunk is not done if it introduces:

```text id="1xhmux"
real broker integration
real broker credentials
live order placement
live order cancellation
real-money execution
leverage
CFDs
spread betting
options trading
autonomous live execution
AI execution authority
AI bypass of risk gate
```

If any of those appear, the chunk fails the definition of done.

---

## 5. Tests

Each implementation chunk should include relevant automated tests.

Tests should cover:

```text id="01k3ud"
happy path
important failure path
safety guardrail
idempotency, where relevant
state transition, where relevant
```

Examples:

```text id="kq8b4y"
Ingestion tests should check duplicate-safe inserts.
Feature tests should check calculations.
Candidate tests should check rule matching and duplicate prevention.
Review tests should check schema validity.
Risk gate tests should check blocking rules.
Paper execution tests should check no live execution path exists.
Watcher tests should check state transitions.
Outcome tests should check benchmark comparison.
```

A chunk is not done if tests are missing for critical domain logic.

---

## 6. Validation commands

Each chunk must include exact validation commands.

Validation commands should include, where relevant:

```text id="a9mdq4"
make targets
python worker commands
curl commands
kubectl commands
pytest commands
UI validation steps
```

Validation commands must be copy-pasteable.

Example:

```bash id="i3sn8n"
make test
python -m app.workers.ingest_prices
curl http://localhost:8000/api/assets/QQQ/latest
```

A chunk is not done if the user cannot validate it from documented commands.

---

## 7. Expected outputs

Each chunk must document expected outputs.

Expected outputs may include:

```text id="z1cd5s"
HTTP response body
database rows
Kubernetes resources
UI page behaviour
worker log messages
system events
test results
```

Example:

```text id="37xe5l"
Expected:
- /health returns {"status":"ok"}
- traderoo-poc namespace exists
- traderoo-config ConfigMap exists
- EXECUTION_MODE is PAPER_ONLY
```

A chunk is not done if commands are provided without expected results.

---

## 8. Documentation updates

Relevant documentation must be updated with each chunk.

Possible docs include:

```text id="jlzzj9"
docs/hld.md
docs/delivery/chunk-plan.md
docs/delivery/validation-matrix.md
docs/product/subsystem-map.md
docs/product/mvp-scope.md
docs/safety/paper-only-guardrails.md
docs/safety/ai-boundaries.md
docs/c4/*
README.md
```

Docs do not need to be over-updated for every small code change, but they must remain accurate.

A chunk is not done if the code and documentation contradict each other.

---

## 9. System events

From Chunk 2 onward, important lifecycle changes should create system events.

Examples:

```text id="alef8f"
MarketDataIngested
FeaturesGenerated
ObservationCreated
CandidateCreated
TriangleReviewCompleted
RiskGatePassed
RiskGateBlocked
PaperTradeApproved
PaperTradeRejected
PaperTradeOpened
WatcherStateCreated
WatcherAlertCreated
OutcomeEvaluated
```

A chunk is not done if it introduces a major lifecycle transition without a corresponding system event, unless the event model has not yet been introduced.

---

## 10. Traceability

Domain artefacts must link to the artefacts that caused them.

Target traceability chain:

```text id="fy7yfg"
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

Each chunk should preserve or improve traceability.

A chunk is not done if it creates orphaned lifecycle records without a clear link to their source.

---

## 11. Configuration

Configuration must be explicit and safe.

Required MVP defaults:

```text id="bj9v8e"
APP_NAME=traderoo
ENVIRONMENT=local
EXECUTION_MODE=PAPER_ONLY
REVIEW_PROVIDER=mock
DEFAULT_BENCHMARK=SPY
MAX_SINGLE_POSITION_WEIGHT=0.05
MAX_TOTAL_OPEN_POSITION_WEIGHT=0.30
```

A chunk is not done if it:

```text id="24hffc"
defaults to live trading
requires broker credentials
logs secrets
hardcodes unsafe values
silently ignores invalid execution mode
```

---

## 12. Kubernetes validation

For chunks that touch Kubernetes manifests, validation must include:

```text id="h0uhco"
kubectl apply or kustomize build validation
resource existence checks
pod/job status checks
logs where relevant
Argo CD sync status where relevant
```

Example:

```bash id="8e7jgc"
kubectl apply -k applications/traderoo/k8s/overlays/poc
kubectl get pods -n traderoo-poc
kubectl get configmap traderoo-config -n traderoo-poc -o yaml
```

A chunk is not done if Kubernetes manifests are added but not validated.

---

## 13. UI validation

For chunks that add or change UI, validation must include simple manual checks.

Examples:

```text id="8xcoud"
Open dashboard.
Open asset page.
Open candidates page.
Open candidate detail page.
Open positions page.
Open alerts page.
Confirm expected records appear.
Confirm paper-only wording is visible.
```

UI does not need to be polished in early chunks, but it must be usable enough to validate the lifecycle.

A chunk is not done if the UI hides important decision state.

---

## 14. API validation

For chunks that add API endpoints, validation should include:

```text id="gsjmep"
endpoint path
example curl command
expected status code
expected response shape
```

Example:

```bash id="5c69bg"
curl http://localhost:8000/api/assets
```

Expected:

```text id="brzvv8"
HTTP 200.
Response contains seeded assets.
```

A chunk is not done if endpoints are added without validation.

---

## 15. Worker validation

For chunks that add worker commands, validation should include:

```text id="3jg0j1"
worker command
expected logs
expected database changes
expected system event
idempotency behaviour, where relevant
```

Example:

```bash id="g203iz"
python -m app.workers.ingest_prices
```

Expected:

```text id="f6fi7w"
price_bars are inserted.
MarketDataIngested event is recorded.
Re-running does not create duplicate price bars.
```

A chunk is not done if a worker exists but cannot be run and verified directly.

---

## 16. Error handling

Each chunk should handle expected errors safely.

Examples:

```text id="y6ctt2"
missing market data should not crash the whole system
invalid AI output should fail closed
blocked candidates should not execute
stale data should block risk approval
invalid execution mode should block execution
```

A chunk is not done if common failure modes produce unsafe state.

---

## 17. Idempotency

Repeated worker runs should not create uncontrolled duplicate records.

Important idempotency checks:

```text id="vrab4w"
re-running seed should not duplicate assets
re-running ingestion should not duplicate price bars
re-running observers should not create noisy duplicate observations
re-running candidate generation should not duplicate pending candidates
re-running review should not create conflicting active reviews
re-running risk gate should not create conflicting risk decisions
```

A chunk is not done if normal repeated runs corrupt system state.

---

## 18. Copilot response requirements

When Copilot completes a chunk, it should provide:

```text id="pa3ng8"
files changed
summary of implementation
how to run locally
how to run in Kubernetes, where applicable
tests added
validation commands
expected outputs
known limitations
what remains for the next chunk
confirmation that PAPER_ONLY guardrails remain intact
```

A Copilot-generated chunk should be rejected if it does not include this information.

---

## 19. Pre-merge checklist

Before accepting a chunk, check:

```text id="sbvbjw"
Does this match the requested chunk?
Did it avoid future scope?
Do tests pass?
Do validation commands work?
Are expected outputs documented?
Are docs still accurate?
Is execution still PAPER_ONLY?
Are safety guardrails intact?
Are lifecycle artefacts traceable?
Are system events created where needed?
Can I explain what changed?
```

---

## 20. Done means boring and repeatable

A chunk is done when it is boring, repeatable, and validated.

The desired state is:

```text id="qf2b26"
I can run the commands.
I can see the expected result.
I can inspect the UI or API.
I can trust that no unsafe capability was added.
I know exactly what the next chunk is.
```

The definition of done is intentionally strict because Traderoo deals with trading decisions, even though the MVP is paper-only.
