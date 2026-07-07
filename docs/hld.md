# Traderoo High-Level Design

## 1. Purpose

Traderoo is a local Kubernetes-hosted AI trading control plane.

The purpose of Traderoo is to prove a safe, auditable, paper-only trading decision lifecycle:

```text
Data → Features → Observations → Candidates → Review → Risk Gate
→ Paper Trade → Watcher → Alert → Outcome Evaluation → Dashboard
```

Traderoo is not intended to prove guaranteed profitability in the MVP. The MVP exists to prove that a system can:

* ingest market data
* identify observations
* generate candidate paper trades
* review candidates against a structured trade-quality framework
* apply deterministic risk controls
* simulate paper trades
* monitor open positions
* evaluate outcomes
* present the full lifecycle through a visual interface

The project is designed to run on a powerful home desktop using a local Kubernetes cluster.

---

## 2. System name

The project is called:

```text
Traderoo
```

Repository name:

```text
traderoo
```

Preferred local Kubernetes namespace:

```text
traderoo-poc
```

Preferred local Kubernetes cluster name:

```text
traderoo
```

---

## 3. MVP scope

### In scope

The MVP includes:

* local Kubernetes deployment using k3d
* GitOps deployment using Argo CD
* paper-only trading lifecycle
* small asset watchlist
* price data ingestion
* feature generation
* observation generation
* candidate trade generation
* mock triangle review provider
* later optional OpenAI review provider
* deterministic risk gate
* manual approval for paper trades
* simulated paper trade ledger
* position watchers
* alerts
* outcome evaluation
* dashboard and repeatable asset detail pages

### Out of scope

The MVP explicitly excludes:

* live broker integration
* real-money order placement
* leverage
* CFDs
* spread betting
* options trading
* automatic real-money execution
* unattended live trading
* claims of predictable or guaranteed profit
* production-grade market data
* production-grade secret management
* service mesh
* complex event streaming
* high-frequency trading
* intraday trading

The only permitted execution mode in the MVP is:

```text
PAPER_ONLY
```

---

## 4. Key design principles

### 4.1 Paper-only by default

Traderoo must not place real trades during the MVP.

All execution logic must use a simulated paper ledger.

No real broker credentials should be stored, referenced, or required.

### 4.2 Modular monolith first

Traderoo should start as a modular monolith rather than a distributed microservice system.

Subsystems should be cleanly separated in code, but deployed as one backend application initially.

This reduces complexity while allowing later extraction of services if needed.

### 4.3 AI reviews, but does not execute

OpenAI or any other large model may analyse candidate trades, but must not execute trades.

AI output is advisory and must pass through deterministic validation and risk gating.

### 4.4 Deterministic risk gate

The risk gate is separate from the AI review layer.

The risk gate is responsible for enforcing hard safety constraints.

It can approve, reduce, block, or require human review.

### 4.5 Full lifecycle memory

Traderoo must remember:

* what data was ingested
* what features were calculated
* what observations were created
* what candidates were proposed
* what reviews were performed
* what risk decisions were made
* what paper trades were opened
* what watchers observed
* what alerts were emitted
* what outcomes occurred

This creates auditability and enables later feedback.

### 4.6 Human-visible decision trail

The UI should make the full decision chain visible.

For any asset or paper trade, a user should be able to answer:

```text
What did the system observe?
Why was a trade proposed?
What did the triangle review conclude?
What did the risk gate allow or block?
What paper trade was opened?
What happened after entry?
Did the decision work?
```

---

## 5. Trading decision model

Traderoo uses a three-part trade-quality framework.

The project refers to this as the trade triangle:

```text
Signal / Edge
Safety / Risk
Situation / Context
```

### 5.1 Signal / Edge

This answers:

```text
Why should this trade work?
```

Examples:

* trend strength
* relative strength
* momentum
* mean reversion
* macro regime support
* event-driven setup

In the MVP, the first signal model is simple:

```text
Positive trend + positive relative strength + acceptable volatility
```

### 5.2 Safety / Risk

This answers:

```text
Can the system survive being wrong?
```

Risk checks include:

* maximum single position weight
* maximum total open exposure
* no duplicate open position for the same asset
* data freshness
* current drawdown
* volatility state
* paper-only execution mode

### 5.3 Situation / Context

This answers:

```text
Is this trade appropriate now, in this portfolio and market context?
```

In the early MVP, context will be limited.

Later context may include:

* macro regime
* news events
* earnings calendar
* central bank decisions
* sector concentration
* past similar decision outcomes
* current portfolio state

---

## 6. High-level architecture

Traderoo consists of the following logical subsystems:

```text
Data Ingestion
Feature Builder
General Observer
Candidate Generator
Triangle Review
Risk Gate
Paper Execution
Position Watchers
Outcome Evaluator
Dashboard / API
System Memory
```

High-level flow:

```text
External data sources
    ↓
Data ingestion
    ↓
Raw and normalised storage
    ↓
Feature builder
    ↓
General observers
    ↓
Candidate generator
    ↓
Triangle review
    ↓
Deterministic risk gate
    ↓
Manual approval
    ↓
Paper execution
    ↓
Position watchers
    ↓
Alerts
    ↓
Outcome evaluator
    ↓
Dashboard and feedback memory
```

---

## 7. Subsystem overview

## 7.1 Data ingestion

### Purpose

The data ingestion subsystem brings external market data into Traderoo.

### MVP input

* daily OHLCV market data
* small watchlist of assets

### MVP source

* `yfinance` for proof-of-concept data only

### Responsibilities

* read active assets from the database
* fetch historical daily price bars
* store price bars
* avoid duplicate rows
* record ingestion events
* preserve source metadata

### Must not do

* generate trade signals
* create observations
* create candidates
* place trades

---

## 7.2 Feature builder

### Purpose

The feature builder converts raw price data into useful market features.

### MVP features

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

### Responsibilities

* calculate repeatable features
* store feature snapshots
* record feature generation events

### Must not do

* create trades
* call AI models
* perform risk approval

---

## 7.3 General observer

### Purpose

The observer subsystem identifies interesting market conditions.

Observers emit observations, not trades.

### MVP observers

* Trend Observer
* Volatility Observer
* Relative Strength Observer
* Drawdown Observer

### Example observations

```text
positive_trend
negative_trend
elevated_volatility
positive_relative_strength
deep_drawdown
```

### Responsibilities

* read latest features
* create timestamped observations
* assign observation type and strength
* explain observations in simple language

### Must not do

* create paper trades
* approve candidates
* call a broker
* bypass risk controls

---

## 7.4 Candidate generator

### Purpose

The candidate generator converts observations into candidate paper trades.

### MVP candidate rule

Create a BUY candidate when:

```text
latest positive_trend observation exists
latest positive_relative_strength observation exists
volatility is not elevated
no open paper position already exists for the same asset
```

### Candidate fields

A candidate should include:

* candidate ID
* asset
* action
* strategy version
* time horizon
* proposed target weight
* thesis
* source observations
* status

### Must not do

* execute trades
* call a broker
* override the risk gate

---

## 7.5 Triangle review

### Purpose

The triangle review subsystem evaluates candidate trades against:

```text
Signal / Edge
Safety / Risk
Situation / Context
```

### MVP provider

The MVP starts with:

```text
MockReviewProvider
```

Later, Traderoo may add:

```text
OpenAIReviewProvider
```

### Review result

A review should produce structured output:

* edge score
* risk score
* context score
* confidence
* verdict
* position size multiplier
* edge summary
* risk summary
* context summary
* blocking risks
* watcher rules
* review horizon

### Valid verdicts

```text
ALLOW
ALLOW_REDUCED_SIZE
HUMAN_REVIEW
BLOCK
```

### Must not do

* create orders
* execute trades
* modify strategy logic live
* bypass deterministic risk controls

---

## 7.6 Deterministic risk gate

### Purpose

The risk gate is the final rule-based approval layer before paper execution.

### MVP rules

The MVP risk gate must enforce:

```text
execution_mode must always be PAPER_ONLY
max_single_position_weight = 0.05
max_total_open_position_weight = 0.30
block if same asset already has an open position
block if latest data is stale
reduce size if triangle verdict is ALLOW_REDUCED_SIZE
require human review if review says HUMAN_REVIEW
block if review says BLOCK
```

### Risk decision results

```text
PASS
PASS_WITH_REDUCED_SIZE
HUMAN_REVIEW_REQUIRED
BLOCK
```

### Must not do

* call OpenAI
* generate new candidates
* place live trades
* accept unvalidated AI output

---

## 7.7 Paper execution

### Purpose

The paper execution subsystem simulates trades.

### Responsibilities

* create paper orders
* create simulated fills
* open paper positions
* link positions to candidates, reviews, and risk decisions
* update portfolio state

### MVP execution mode

```text
PAPER_ONLY
```

### Must not do

* call a real broker
* place real orders
* use leverage
* use CFDs or spread betting
* require broker credentials

---

## 7.8 Position watchers

### Purpose

Position watchers monitor open paper positions after entry.

They check whether the original thesis remains intact.

### MVP checks

For each open paper position, calculate:

* return since entry
* drawdown since entry
* price still above 200-day moving average
* relative strength still positive
* volatility state
* review date due

### Watcher states

```text
NORMAL
CAUTION
THESIS_WEAKENING
THESIS_INVALIDATED
```

### Alert examples

* drawdown since entry exceeds threshold
* price closes below 200-day moving average
* relative strength turns negative
* review date is due

### Must not do

* execute trades
* close positions automatically
* modify the original thesis
* bypass human review

---

## 7.9 Outcome evaluator

### Purpose

The outcome evaluator determines whether paper trade decisions worked.

### MVP horizons

Evaluate outcomes after:

```text
1 trading day
5 trading days
20 trading days
60 trading days
```

### Metrics

* asset return
* benchmark return
* excess return
* maximum adverse excursion
* maximum favourable excursion
* outcome label

### Outcome labels

```text
PENDING
WORKED
FAILED
MIXED
```

### Must not do

* rewrite historical decisions
* modify strategy thresholds live
* place new trades

---

## 7.10 Dashboard and API

### Purpose

The dashboard is the operator interface for Traderoo.

It should allow the user to:

* inspect the system state
* review candidates
* approve or reject paper trades
* inspect asset pages
* monitor open positions
* view alerts
* review performance

### MVP pages

```text
Overview
Candidates
Candidate Detail
Positions
Asset Detail
Alerts
Performance
```

### Asset detail page

Each tracked asset should have a repeatable page showing:

* latest price
* latest features
* observations timeline
* candidate history
* triangle reviews
* risk decisions
* open and closed positions
* watcher states
* alerts
* outcome history

---

## 8. System memory

Traderoo requires structured memory.

The main database should store:

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

The most important design goal is traceability.

Every major lifecycle transition should create a system event.

Example events:

```text
MarketDataIngested
FeaturesGenerated
ObservationCreated
CandidateCreated
TriangleReviewCompleted
RiskGatePassed
RiskGateBlocked
PaperTradeApproved
PaperTradeOpened
WatcherStateCreated
WatcherAlertCreated
OutcomeEvaluated
```

---

## 9. Deployment model

Traderoo runs locally on Kubernetes.

### Local runtime

```text
k3d
```

### GitOps controller

```text
Argo CD
```

### Application namespace

```text
traderoo-poc
```

### Platform bootstrap location

```text
platform/
```

### Kubernetes manifests

```text
deploy/k8s/
```

### Argo CD application manifest

```text
deploy/argocd/traderoo-application.yaml
```

The deployment model is:

```text
GitHub repository
    ↓
Argo CD sync
    ↓
local k3d cluster
    ↓
Traderoo workloads
```

Argo CD deploys manifests. It does not build application images.

Application image build and registry publishing will be handled later.

---

## 10. Repository structure

Traderoo uses the following top-level structure:

```text
traderoo/
├── app/
├── deploy/
├── platform/
├── docs/
├── scripts/
├── tests/
├── .gitignore
├── Makefile
└── README.md
```

### `app/`

Application code.

### `deploy/`

Kubernetes manifests and Argo CD application definitions.

### `platform/`

Local platform bootstrap configuration such as k3d cluster config and Argo CD setup notes.

### `docs/`

Architecture, setup, ADRs, product notes, delivery plans, and safety guardrails.

### `scripts/`

Helper scripts.

### `tests/`

Automated tests.

---

## 11. MVP delivery chunks

Traderoo will be built incrementally.

```text
Chunk 0: local Kubernetes + Argo CD + repository bootstrap
Chunk 1: runnable FastAPI skeleton
Chunk 2: Postgres and core schema
Chunk 3: market data ingestion
Chunk 4: features and observations
Chunk 5: candidate generation
Chunk 6: mock triangle review
Chunk 7: deterministic risk gate
Chunk 8: manual approval and paper execution
Chunk 9: watchers and alerts
Chunk 10: outcome evaluation and performance dashboard
Chunk 11: optional OpenAI review provider
Chunk 12: Kubernetes polish
```

Each chunk must include:

* files changed
* how to run locally
* how to run in Kubernetes, where applicable
* validation commands
* expected outputs
* known limitations
* what remains out of scope

---

## 12. MVP acceptance journey

The MVP is successful when this journey works end to end:

```text
1. Traderoo ingests latest prices for a watchlist.
2. Feature builder calculates trend, volatility, drawdown, and relative strength.
3. Observers emit observations.
4. Candidate generator creates candidate paper trades.
5. Triangle review evaluates candidates against Signal/Safety/Situation.
6. Risk gate approves, reduces, blocks, or requires human review.
7. User approves a paper trade in the UI.
8. Paper execution opens a simulated position.
9. Watchers monitor the position.
10. Alerts are emitted when watcher rules are breached.
11. Outcome evaluator scores the decision after defined horizons.
12. Asset page shows the full chain from observation to outcome.
```

---

## 13. Safety constraints

Traderoo must follow these safety constraints during the MVP:

```text
Execution mode is always PAPER_ONLY.
No real broker adapter.
No real broker credentials.
No real orders.
No leverage.
No CFDs.
No spread betting.
No options.
No autonomous live execution.
No OpenAI execution authority.
No AI bypass of risk gate.
```

Any future change that introduces real broker integration must require a new ADR.

---

## 14. Initial technology choices

### Platform

```text
k3d
Kubernetes
Argo CD
Kustomize
```

### Backend

```text
Python
FastAPI
SQLAlchemy or SQLModel
Postgres
```

### Data

```text
yfinance for POC market data
Postgres for structured memory
```

### UI

```text
Server-rendered HTML templates for the initial UI
No React/Vue/Svelte in the first UI iteration
```

### AI review

```text
MockReviewProvider first
OpenAIReviewProvider later
Structured JSON output required
```

---

## 15. Future considerations

Potential future enhancements include:

* OpenAI structured review provider
* richer market/news RAG
* local model watchers
* pgvector semantic memory
* GitHub Actions image build
* GHCR image publishing
* dashboard charts
* broker adapter interface
* live trading research mode
* strategy version promotion workflow
* backtesting subsystem
* better market data provider
* authentication for the dashboard
* notifications via email, Slack, or Telegram

These are not required for the initial MVP.
