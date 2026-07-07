# Traderoo MVP Scope

## 1. Purpose

This document defines the scope of the Traderoo minimum viable product.

Traderoo is a local Kubernetes-hosted, paper-only AI trading control plane.

The MVP exists to prove the full trading decision lifecycle:

```text
Data → Features → Observations → Candidates → Review → Risk Gate
→ Paper Trade → Watcher → Alert → Outcome Evaluation → Dashboard
```

The MVP is not intended to prove profitability. It is intended to prove that Traderoo can safely observe assets, propose paper trades, review decisions, simulate execution, monitor positions, and evaluate outcomes.

---

## 2. MVP statement

The Traderoo MVP will provide a safe, auditable, paper-only system that can:

1. Ingest daily market data for a small watchlist.
2. Build simple technical features.
3. Generate observations from those features.
4. Create candidate paper trades.
5. Review candidates against the trade triangle:

   * Signal / Edge
   * Safety / Risk
   * Situation / Context
6. Apply deterministic risk rules.
7. Allow manual approval of paper trades.
8. Open simulated paper positions.
9. Monitor open positions.
10. Emit alerts when a thesis weakens.
11. Evaluate whether decisions worked.
12. Show the full lifecycle in a dashboard.

---

## 3. In scope

## 3.0 Chunk 1 runtime skeleton

The first runtime milestone includes a minimal FastAPI app in `traderoo-poc` with:

```text
GET /healthz
GET /readyz
GET /
```

This runtime does not include database persistence and must run with:

```text
APP_NAME=traderoo
APP_ENV=poc
EXECUTION_MODE=PAPER_ONLY
REVIEW_PROVIDER=mock
```

## 3.1 Local platform

The MVP includes a local Kubernetes platform:

```text
k3d
Kubernetes
Argo CD
Kustomize
```

The intended runtime is a powerful local desktop.

The cluster is for local development and POC validation only.

## 3.2 GitOps deployment

Traderoo will use Argo CD to sync Kubernetes manifests from GitHub.

The GitOps model is:

```text
GitHub repository
  → Argo CD sync
  → local k3d cluster
  → Traderoo workloads
```

Argo CD deploys manifests. It does not build application images.

## 3.3 Modular monolith

Traderoo will start as a modular monolith.

The project may contain separate modules for ingestion, features, observers, candidates, reviews, risk, paper execution, watchers, outcomes, and UI, but these should initially live in one application codebase.

## 3.4 Paper-only execution

The only execution mode in the MVP is:

```text
PAPER_ONLY
```

The system may create:

* paper orders
* simulated fills
* paper positions
* paper portfolio state
* paper performance records

The system must not submit real orders.

## 3.5 Small watchlist

The MVP will use a small watchlist of liquid assets.

Initial example assets:

```text
SPY
QQQ
IWM
GLD
TLT
VUSA.L
VWRL.L
```

The exact list can change, but the MVP should remain small.

## 3.6 POC-grade market data

The MVP may use `yfinance` for price data ingestion.

This is acceptable for proving the control loop.

It is not considered production-grade market data.

## 3.7 Feature generation

The MVP should calculate simple repeatable features:

```text
daily return
20-day return
50-day return
20-day volatility
50-day moving average
200-day moving average
price above 200-day moving average
50-day moving average above 200-day moving average
drawdown from 252-day high
50-day relative strength versus benchmark
```

## 3.8 Observations

The MVP should emit observations such as:

```text
positive_trend
negative_trend
elevated_volatility
positive_relative_strength
deep_drawdown
```

Observations describe market conditions. They do not execute trades.

## 3.9 Candidate paper trades

The MVP should generate candidate paper trades from observations.

Initial candidate rule:

```text
Create a BUY candidate when:
- latest positive_trend observation exists
- latest positive_relative_strength observation exists
- volatility is not elevated
- no open paper position already exists for the same asset
```

## 3.10 Mock triangle review

The MVP should start with a deterministic mock review provider.

The review should assess:

```text
Signal / Edge
Safety / Risk
Situation / Context
```

The mock provider exists so the system can be built and tested before OpenAI integration is added.

## 3.11 Optional OpenAI review provider

After the mock review provider works, an OpenAI review provider may be added.

OpenAI may analyse candidate trades and return structured review output.

OpenAI must not:

```text
execute trades
approve trades directly
bypass the risk gate
modify strategy logic live
call broker or execution code
```

## 3.12 Deterministic risk gate

The MVP must include a deterministic risk gate.

The risk gate should enforce:

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

## 3.13 Manual approval

Paper trades should require manual approval in the UI.

The user should be able to:

```text
approve paper trade
reject candidate
inspect candidate evidence
inspect triangle review
inspect risk decision
```

## 3.14 Paper execution

Approved candidates should create:

```text
paper order
paper fill
open paper position
system event
```

The paper position must link back to:

```text
candidate
triangle review
risk decision
source observations
```

## 3.15 Position watchers

The MVP should monitor open paper positions.

Watcher checks should include:

```text
return since entry
drawdown since entry
price above 200-day moving average
relative strength state
volatility state
review due
```

Watcher states:

```text
NORMAL
CAUTION
THESIS_WEAKENING
THESIS_INVALIDATED
```

## 3.16 Alerts

The MVP should create alerts for notable watcher events.

Example alert triggers:

```text
drawdown since entry <= -3%
price closes below 200-day moving average
relative strength turns negative
review date due
```

## 3.17 Outcome evaluation

The MVP should evaluate decisions after defined horizons:

```text
1 trading day
5 trading days
20 trading days
60 trading days
```

Outcome metrics:

```text
asset return
benchmark return
excess return
max adverse excursion
max favourable excursion
outcome label
```

Outcome labels:

```text
PENDING
WORKED
FAILED
MIXED
```

## 3.18 Dashboard

The MVP should include a simple visual interface.

Pages:

```text
Overview
Candidates
Candidate Detail
Positions
Asset Detail
Alerts
Performance
```

The dashboard may initially use server-rendered HTML templates.

A complex frontend framework is not required for the MVP.

---

## 4. Out of scope

The following are explicitly out of scope for the MVP.

## 4.1 Live broker integration

Traderoo MVP must not connect to a real broker for order execution.

No live broker adapter should exist in the MVP.

## 4.2 Real-money trading

Traderoo MVP must not place real trades.

No real-money execution is permitted.

## 4.3 Leverage

The MVP must not use leverage.

## 4.4 CFDs and spread betting

The MVP must not support:

```text
CFDs
spread betting
margin trading
leveraged derivative products
```

## 4.5 Options trading

Options trading is out of scope.

## 4.6 Autonomous live execution

The MVP must not support unattended real-money execution.

## 4.7 Profit guarantees

Traderoo must not claim to produce guaranteed profit or predictable returns.

The MVP is an engineering proof of concept, not a profit-generating system.

## 4.8 High-frequency or intraday trading

The MVP uses daily bars.

Intraday trading and high-frequency trading are out of scope.

## 4.9 Production-grade market data

The MVP may use POC-grade market data.

Premium or production-grade data providers are out of scope until the control loop is proven.

## 4.10 Full RAG/news system

A full RAG-based news and macro context system is out of scope for the first MVP.

The MVP may include simple context placeholders or later OpenAI candidate review, but full news ingestion, embedding, semantic search, and macro narrative tracking should be treated as later enhancements.

## 4.11 Local model watcher agents

Local models may be a future enhancement.

The MVP watcher should begin as deterministic rule-based logic.

## 4.12 Production security hardening

The MVP should be sensible and private, but production-grade security is out of scope.

Out of scope for MVP:

```text
public exposure
multi-user authentication
role-based access control
service mesh
Vault integration
external secrets operator
full observability stack
```

---

## 5. MVP user journeys

## 5.1 Observe an asset

The user can open an asset page and see:

```text
latest price
latest features
observations
candidate history
position state
watcher state
alerts
outcomes
```

## 5.2 Review a candidate

The user can open a candidate page and see:

```text
asset
action
thesis
source observations
latest features
triangle review
risk decision
approval state
```

## 5.3 Approve a paper trade

The user can approve a risk-approved candidate.

Traderoo then creates:

```text
paper order
paper fill
open paper position
system event
```

## 5.4 Monitor an open position

The user can see whether an open paper position is:

```text
normal
in caution
weakening
invalidated
```

## 5.5 Review performance

The user can see whether past paper decisions:

```text
worked
failed
were mixed
are still pending
```

---

## 6. MVP success criteria

The MVP is successful when the following end-to-end journey works:

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

## 7. Safety constraints

Traderoo MVP must always follow these constraints:

```text
Execution mode is PAPER_ONLY.
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

Any change that introduces real broker integration or real-money execution requires a new ADR.

---

## 8. Future scope

Potential future work includes:

```text
OpenAI structured review provider
news and macro RAG
local model position watchers
pgvector semantic memory
GitHub Actions image build
GHCR image publishing
authentication
notifications
better charting
broker adapter research
backtesting subsystem
strategy versioning
strategy promotion workflow
better market data providers
```

These are not required for the MVP unless explicitly pulled into a later chunk.
