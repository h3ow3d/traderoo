# Traderoo Subsystem Map

## 1. Purpose

This document maps the major Traderoo subsystems, their responsibilities, their inputs and outputs, and their boundaries.

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane.

The MVP decision lifecycle is:

```text id="2kwrc2"
Data → Features → Observations → Candidates → Review → Risk Gate
→ Paper Trade → Watcher → Alert → Outcome Evaluation → Dashboard
```

Each subsystem should be independently understandable and testable.

---

## 2. Subsystem summary

```text id="288ab9"
Data Ingestion
  ↓
Feature Builder
  ↓
General Observer
  ↓
Candidate Generator
  ↓
Triangle Review
  ↓
Risk Gate
  ↓
Manual Approval
  ↓
Paper Execution
  ↓
Position Watchers
  ↓
Alerts
  ↓
Outcome Evaluator
  ↓
Dashboard / API
```

Supporting subsystems:

```text id="1knx8p"
System Memory
System Events
Configuration
Platform Deployment
```

---

# 3. Data Ingestion

## Purpose

Bring external market data into Traderoo.

The ingestion subsystem creates the factual base for the rest of the system.

## MVP source

```text id="pt9uvi"
yfinance
```

This is POC-grade only.

## Inputs

```text id="7e3xab"
active assets
configured date range
market data provider
ingestion settings
```

## Outputs

```text id="vn31wi"
price_bars
system_events
ingestion metadata
```

## Tables touched

```text id="q4ftc1"
assets
price_bars
system_events
```

## Responsibilities

* read active assets from the database
* fetch daily OHLCV data
* store price bars
* avoid duplicate rows
* preserve source name
* record `ingested_at`
* record ingestion system events
* fail safely if a provider is unavailable

## Must not do

* create features
* create observations
* create candidates
* review trades
* create paper orders
* execute trades
* call OpenAI

## MVP worker

```text id="2iuuq2"
python -m app.workers.ingest_prices
```

## Acceptance criteria

* price data can be ingested for the watchlist
* repeated ingestion does not create duplicates
* latest price data is visible through the API/UI
* ingestion event is recorded

---

# 4. Feature Builder

## Purpose

Convert stored price bars into repeatable market features.

## Inputs

```text id="snnand"
price_bars
benchmark asset
feature configuration
```

## Outputs

```text id="u8dvmn"
feature_snapshots
system_events
```

## Tables touched

```text id="dr2ux1"
assets
price_bars
feature_snapshots
system_events
```

## MVP features

```text id="ud8j01"
daily_return
return_20d
return_50d
volatility_20d
moving_average_50d
moving_average_200d
price_above_200dma
ma50_above_ma200
drawdown_from_252d_high
relative_strength_50d_vs_benchmark
```

## Responsibilities

* calculate features from stored price bars
* use only data available up to the feature date
* store feature snapshots
* record feature generation events
* handle insufficient price history gracefully

## Must not do

* create candidates
* review trades
* make risk decisions
* execute trades
* mutate historical price bars
* call OpenAI

## MVP worker

```text id="4js9e8"
python -m app.workers.build_features
```

## Acceptance criteria

* feature snapshots are generated after price ingestion
* features are visible on the asset page
* calculations are tested with sample data

---

# 5. General Observer

## Purpose

Spot notable market conditions.

Observers create observations, not trades.

## Inputs

```text id="juvefr"
latest feature snapshots
observer configuration
asset metadata
```

## Outputs

```text id="3caagh"
observations
system_events
```

## Tables touched

```text id="l7431x"
assets
feature_snapshots
observations
system_events
```

## MVP observers

```text id="7olm4t"
Trend Observer
Volatility Observer
Relative Strength Observer
Drawdown Observer
```

## MVP observation types

```text id="3vc1cs"
positive_trend
negative_trend
elevated_volatility
positive_relative_strength
deep_drawdown
```

## Responsibilities

* inspect latest feature snapshots
* emit observations when conditions are met
* assign observation type
* assign observation strength
* create readable observation summary
* record observation events

## Must not do

* create paper orders
* approve candidates
* bypass risk controls
* call a broker
* mutate feature values
* execute trades

## MVP worker

```text id="by1hx8"
python -m app.workers.run_observers
```

## Acceptance criteria

* observations are generated from feature snapshots
* observation timeline appears on asset pages
* duplicate/noisy observations are controlled

---

# 6. Candidate Generator

## Purpose

Convert observations into candidate paper trades.

A candidate is a proposed idea that requires review and risk gating.

## Inputs

```text id="x741o1"
latest observations
latest feature snapshots
open paper positions
strategy rules
```

## Outputs

```text id="o7zf3e"
candidates
candidate source links
system_events
```

## Tables touched

```text id="ycu0oy"
assets
observations
feature_snapshots
candidates
positions
system_events
```

## MVP candidate rule

Create a BUY candidate when:

```text id="5erpi3"
latest positive_trend observation exists
latest positive_relative_strength observation exists
volatility is not elevated
no open paper position already exists for the same asset
```

## Candidate fields

```text id="l4zt51"
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

## Candidate statuses

```text id="9dcwh3"
PENDING_REVIEW
REVIEWED
RISK_ASSESSED
APPROVED_FOR_PAPER
REJECTED
EXECUTED_PAPER
BLOCKED
```

## Responsibilities

* find valid observation combinations
* create candidate trades
* prevent duplicate pending candidates
* attach source observations
* define thesis
* set candidate status
* record candidate creation event

## Must not do

* execute trades
* bypass review
* bypass risk gate
* call a broker
* approve its own candidates
* call OpenAI directly

## MVP worker

```text id="5gmapy"
python -m app.workers.generate_candidates
```

## Acceptance criteria

* valid observations create candidates
* duplicate pending candidates are not repeatedly created
* candidate detail page shows thesis and source observations

---

# 7. Triangle Review

## Purpose

Review candidate trades against the trade triangle:

```text id="6ctll5"
Signal / Edge
Safety / Risk
Situation / Context
```

The review layer is analytical. It is not an execution layer.

## Inputs

```text id="tmoq1n"
candidate
source observations
latest features
portfolio state
prior similar outcomes, when available
review provider configuration
```

## Outputs

```text id="f13mif"
triangle_reviews
system_events
```

## Tables touched

```text id="19ntnv"
candidates
observations
feature_snapshots
positions
outcomes
triangle_reviews
system_events
```

## Providers

MVP:

```text id="c4jfjm"
MockReviewProvider
```

Later optional:

```text id="7a4qtf"
OpenAIReviewProvider
```

## Review fields

```text id="ant31u"
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

## Valid verdicts

```text id="ojb0wz"
ALLOW
ALLOW_REDUCED_SIZE
HUMAN_REVIEW
BLOCK
```

## Responsibilities

* build review evidence pack
* produce structured review result
* validate review result schema
* persist review
* update candidate status
* record review event

## Must not do

* execute trades
* create paper orders
* bypass the risk gate
* modify strategy logic live
* call broker/execution code
* approve candidates directly

## MVP worker

```text id="m1i075"
python -m app.workers.review_candidates
```

## Acceptance criteria

* pending candidates can be reviewed
* structured review result is stored
* candidate status becomes `REVIEWED`
* review appears on candidate detail page

---

# 8. Deterministic Risk Gate

## Purpose

Apply hard rule-based controls before paper execution.

The risk gate is the final non-AI safety layer.

## Inputs

```text id="djxf26"
reviewed candidate
triangle review
latest features
open positions
portfolio state
risk configuration
```

## Outputs

```text id="tbxx90"
risk_decisions
system_events
candidate status update
```

## Tables touched

```text id="d65z0h"
candidates
triangle_reviews
feature_snapshots
positions
risk_decisions
system_events
```

## MVP risk rules

```text id="qgojgi"
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

```text id="afnq1q"
PASS
PASS_WITH_REDUCED_SIZE
HUMAN_REVIEW_REQUIRED
BLOCK
```

## Responsibilities

* enforce deterministic safety rules
* calculate approved target weight
* block unsafe candidates
* require manual approval where needed
* persist risk decision
* record risk event

## Must not do

* call OpenAI
* generate new candidates
* create orders
* call a broker
* alter the triangle review
* permit live execution

## MVP worker

```text id="egpbrb"
python -m app.workers.run_risk_gate
```

## Acceptance criteria

* reviewed candidates receive risk decisions
* blocked candidates cannot progress
* reduced-size candidates receive reduced target weight
* execution mode remains `PAPER_ONLY`

---

# 9. Manual Approval

## Purpose

Allow the user to approve or reject candidates after review and risk gating.

Manual approval is required before paper execution.

## Inputs

```text id="on2zda"
candidate
triangle review
risk decision
user action
```

## Outputs

```text id="2c3udd"
candidate status update
paper execution request
system_events
```

## Tables touched

```text id="f1w7x1"
candidates
triangle_reviews
risk_decisions
system_events
```

## Responsibilities

* show candidate evidence to the user
* allow approve/reject actions
* block approval of invalid candidates
* record approval/rejection event
* pass approved candidate to paper execution

## Must not do

* bypass risk gate
* approve blocked candidates
* call a real broker
* create live orders
* auto-approve candidates

## UI location

```text id="2pw2yd"
Candidate Detail page
```

## Acceptance criteria

* user can approve risk-approved paper candidates
* user can reject candidates
* blocked candidates cannot be approved
* approval/rejection is recorded

---

# 10. Paper Execution

## Purpose

Simulate trade execution.

Paper execution creates simulated paper orders, fills, and positions.

## Inputs

```text id="qjdxmz"
approved candidate
risk decision
latest price
portfolio state
execution configuration
```

## Outputs

```text id="5xbyxs"
paper_orders
paper_fills
positions
system_events
```

## Tables touched

```text id="9lolnh"
candidates
risk_decisions
price_bars
paper_orders
paper_fills
positions
system_events
```

## Responsibilities

* create paper order
* create simulated fill using latest available close price
* open paper position
* link position to candidate, review, risk decision, and observations
* record paper execution event

## Must not do

* place real orders
* call a real broker
* use real broker credentials
* use leverage
* use CFDs
* use spread betting
* auto-close positions

## MVP execution mode

```text id="pvo0f2"
PAPER_ONLY
```

## Acceptance criteria

* approved candidate creates paper order, fill, and position
* paper position appears in UI
* no real broker adapter exists
* tests prove blocked candidates cannot execute

---

# 11. Position Watchers

## Purpose

Monitor open paper positions after entry.

Watchers check whether the original thesis remains intact.

## Inputs

```text id="2ifzlx"
open positions
latest price data
latest feature snapshots
triangle review watcher rules
risk configuration
```

## Outputs

```text id="ip8yav"
watcher_states
alerts
system_events
```

## Tables touched

```text id="vyh2cr"
positions
price_bars
feature_snapshots
triangle_reviews
watcher_states
alerts
system_events
```

## MVP watcher checks

```text id="74nxpa"
return_since_entry
drawdown_since_entry
price_above_200dma
relative_strength_positive
volatility_state
review_due
```

## Watcher states

```text id="i1i5x0"
NORMAL
CAUTION
THESIS_WEAKENING
THESIS_INVALIDATED
```

## Responsibilities

* inspect open paper positions
* compare current state to original thesis and watcher rules
* create watcher state snapshots
* create alerts when thresholds are breached
* record watcher events

## Must not do

* close positions automatically
* execute trades
* call a broker
* modify the original candidate thesis
* override user decisions

## MVP worker

```text id="5hvr31"
python -m app.workers.run_watchers
```

## Acceptance criteria

* each open position receives watcher state
* watcher states appear on position and asset pages
* alerts are created when watcher rules are breached

---

# 12. Alerts

## Purpose

Surface conditions that require attention.

Alerts are generated by watchers and potentially by later system checks.

## Inputs

```text id="cmz8z2"
watcher state
risk thresholds
data freshness checks
system checks
```

## Outputs

```text id="aubpkb"
alerts
system_events
```

## Tables touched

```text id="h55p27"
alerts
watcher_states
positions
assets
system_events
```

## MVP alert types

```text id="rq6p8t"
DRAWDOWN_WARNING
THESIS_WEAKENING
THESIS_INVALIDATED
REVIEW_DUE
DATA_STALE
```

## Responsibilities

* persist alert
* assign severity
* link alert to asset/position where relevant
* display active alerts in UI
* allow later acknowledgement workflow

## Must not do

* execute trades
* close positions
* call OpenAI
* call broker APIs

## UI location

```text id="5lp9et"
Alerts page
Overview dashboard
Asset detail page
Position detail/page
```

## Acceptance criteria

* alerts are visible in UI
* alerts are linked to relevant asset/position
* alerts are created when watcher rules are breached

---

# 13. Outcome Evaluator

## Purpose

Evaluate whether paper trade decisions worked.

Outcomes provide feedback memory.

## Inputs

```text id="c3ip2k"
positions
entry price
future price bars
benchmark price bars
candidate thesis
strategy version
```

## Outputs

```text id="eel79f"
outcomes
system_events
performance summaries
```

## Tables touched

```text id="j24t8x"
positions
price_bars
candidates
outcomes
system_events
```

## MVP evaluation horizons

```text id="bvc8k9"
1d
5d
20d
60d
```

## Metrics

```text id="1i41oc"
asset_return
benchmark_return
excess_return
max_adverse_excursion
max_favourable_excursion
outcome_label
```

## Outcome labels

```text id="l006li"
PENDING
WORKED
FAILED
MIXED
```

## Responsibilities

* evaluate paper positions after defined horizons
* compare asset return to benchmark return
* calculate adverse/favourable excursion
* label outcomes
* record outcome events
* power performance dashboard

## Must not do

* modify historical candidate decisions
* change strategy logic live
* create new trades
* execute trades
* call OpenAI for approval

## MVP worker

```text id="ap112m"
python -m app.workers.evaluate_outcomes
```

## Acceptance criteria

* outcomes are created when enough future data exists
* performance page shows summary
* asset page shows outcome history

---

# 14. Dashboard / API

## Purpose

Provide the visual operator interface and API access for Traderoo.

## Inputs

```text id="o4s2bl"
system memory
assets
features
observations
candidates
reviews
risk decisions
positions
watcher states
alerts
outcomes
```

## Outputs

```text id="4fs8i5"
HTML pages
JSON API responses
manual approval/rejection actions
```

## Tables touched

Potentially all system memory tables.

## MVP pages

```text id="z66dp5"
Overview
Candidates
Candidate Detail
Positions
Asset Detail
Alerts
Performance
```

## Responsibilities

* show current system state
* show candidate pipeline
* show asset-level lifecycle
* show open positions
* show watcher states
* show alerts
* show outcomes and performance
* allow manual paper approval/rejection

## Must not do

* make hidden trading decisions
* bypass backend validation
* directly mutate database outside controlled handlers
* expose real trading controls
* imply profit guarantees

## Acceptance criteria

* user can inspect the full lifecycle
* user can approve or reject eligible paper candidates
* asset page shows observation-to-outcome traceability

---

# 15. System Memory

## Purpose

Persist the full lifecycle of Traderoo decisions.

System memory enables traceability, feedback, and dashboard views.

## Core tables

```text id="ef8t5j"
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

## Responsibilities

* preserve system state
* preserve lifecycle history
* support traceability
* support dashboard queries
* support outcome evaluation
* support future feedback loops

## Must not do

* store live broker credentials
* store secrets in plain text
* rewrite historical decision artefacts without an explicit migration or correction event

## Acceptance criteria

* every major lifecycle transition is persisted
* every major lifecycle transition records a system event
* asset page can reconstruct a decision chain

---

# 16. System Events

## Purpose

Create a chronological audit trail of the Traderoo system.

## Event examples

```text id="x8ebdl"
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

## Responsibilities

* record what happened
* record when it happened
* link to relevant entity
* support dashboard timelines
* support debugging

## Must not do

* replace domain tables
* contain secrets
* be used as the only source of truth for financial state

## Acceptance criteria

* system events appear on dashboard
* lifecycle events are visible and queryable

---

# 17. Configuration

## Purpose

Control system behaviour through explicit configuration.

## MVP configuration values

```text id="ll77o6"
APP_NAME
ENVIRONMENT
EXECUTION_MODE
REVIEW_PROVIDER
DEFAULT_BENCHMARK
MAX_SINGLE_POSITION_WEIGHT
MAX_TOTAL_OPEN_POSITION_WEIGHT
DATA_STALE_AFTER_DAYS
```

## Required safety defaults

```text id="8mrqk3"
EXECUTION_MODE=PAPER_ONLY
REVIEW_PROVIDER=mock
MAX_SINGLE_POSITION_WEIGHT=0.05
MAX_TOTAL_OPEN_POSITION_WEIGHT=0.30
```

## Must not do

* default to live trading
* require real broker credentials
* expose secrets in logs
* allow AI to override safety settings

---

# 18. Platform Deployment

## Purpose

Run Traderoo locally in Kubernetes.

## Components

```text id="fp1sf4"
k3d
Kubernetes
Argo CD
Kustomize
Postgres, from Chunk 2 onward
Traderoo app workloads, from Chunk 1 onward
```

## Responsibilities

* provide local runtime
* deploy desired state from Git
* enable repeatable validation
* support worker jobs and app deployment

## Must not do

* expose Traderoo publicly
* require cloud infrastructure for MVP
* require production-grade Kubernetes operations

---

# 19. MVP subsystem dependency order

```text id="mzc451"
Platform Deployment
  ↓
Dashboard / API skeleton
  ↓
System Memory
  ↓
Data Ingestion
  ↓
Feature Builder
  ↓
General Observer
  ↓
Candidate Generator
  ↓
Triangle Review
  ↓
Risk Gate
  ↓
Manual Approval
  ↓
Paper Execution
  ↓
Position Watchers
  ↓
Alerts
  ↓
Outcome Evaluator
  ↓
Performance Dashboard
```

---

# 20. Boundary rules

These rules apply across all subsystems.

## Paper-only rule

No subsystem may place real trades during the MVP.

## AI boundary rule

AI may review, summarise, and analyse.

AI may not execute, approve directly, or bypass deterministic controls.

## Risk gate rule

All candidate trades must pass through the deterministic risk gate before paper execution.

## Traceability rule

Every major lifecycle artefact must be linked to the prior artefact.

Example:

```text id="jdam5k"
position
  → paper fill
  → paper order
  → risk decision
  → triangle review
  → candidate
  → observations
  → features
  → price data
```

## Documentation rule

Any new subsystem or major behaviour should update the relevant docs.

## Chunk rule

Do not implement future chunk behaviour early unless explicitly approved.
