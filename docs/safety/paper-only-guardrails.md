# Traderoo Paper-Only Guardrails

## 1. Purpose

This document defines the paper-only safety guardrails for Traderoo.

Traderoo is a local Kubernetes-hosted AI trading control plane proof of concept.

The MVP is designed to prove a safe and auditable paper-trading lifecycle:

```text
Data → Features → Observations → Candidates → Review → Risk Gate
→ Paper Trade → Watcher → Alert → Outcome Evaluation → Dashboard
```

The MVP must not place real trades.

The purpose of these guardrails is to prevent accidental or premature introduction of live trading behaviour.

---

## 2. Core safety rule

The only permitted execution mode during the MVP is:

```text
PAPER_ONLY
```

This rule applies to:

* local development
* Kubernetes deployment
* tests
* worker jobs
* dashboard actions
* candidate approval
* paper execution
* future OpenAI review integration

No subsystem may place real orders during the MVP.

---

## 3. Explicitly prohibited during the MVP

Traderoo MVP must not include:

```text
real broker integration
real broker credentials
live order placement
live order cancellation
live portfolio modification
real-money execution
margin trading
leverage
CFDs
spread betting
options trading
crypto leverage
autonomous live execution
```

These are not implementation details. They are out of scope by design.

Any future introduction of live broker functionality requires a new ADR.

---

## 4. Execution mode requirements

Traderoo must default to:

```text
EXECUTION_MODE=PAPER_ONLY
```

The system must fail closed if execution mode is missing or invalid.

Valid MVP execution mode:

```text
PAPER_ONLY
```

Invalid MVP execution modes:

```text
LIVE
BROKER
REAL
REAL_MONEY
PRODUCTION_TRADING
MARGIN
CFD
SPREAD_BETTING
```

If any invalid execution mode is detected, the system must:

```text
block execution
record a system event
show an error in the UI
not create an order
not create a fill
not create a position
```

---

## 5. Paper execution boundary

The paper execution subsystem may create:

```text
paper_orders
paper_fills
paper_positions
portfolio_snapshots
system_events
```

The paper execution subsystem must not:

```text
call broker APIs
submit real orders
cancel real orders
read or write real broker positions
read or write real broker cash balances
use real broker credentials
send order instructions to external systems
```

Paper execution is an internal simulation only.

---

## 6. Broker adapter boundary

No real broker adapter should exist in the MVP.

The following interfaces or implementations are out of scope during the MVP:

```text
Interactive Brokers adapter
Trading 212 adapter
Alpaca live adapter
Saxo adapter
IG adapter
Robinhood adapter
any real broker execution adapter
```

A fake or paper adapter is allowed only if it cannot place real orders.

Acceptable MVP adapter:

```text
PaperExecutionAdapter
```

Unacceptable MVP adapters:

```text
LiveBrokerAdapter
RealBrokerAdapter
IBKRAdapter
Trading212Adapter
AlpacaLiveAdapter
```

If a future broker adapter interface is introduced, it must remain non-functional for live trading unless a new ADR explicitly approves live execution research.

---

## 7. OpenAI and AI model boundary

AI may review candidate trades.

AI may produce:

```text
edge score
risk score
context score
confidence score
structured review verdict
summaries
blocking risks
watcher rules
human review recommendation
```

AI must not:

```text
execute trades
approve trades directly
call execution code
call broker APIs
bypass the risk gate
modify strategy logic live
change risk limits
change execution mode
override human approval
```

OpenAI or local model output is advisory.

The deterministic risk gate remains mandatory.

---

## 8. Risk gate requirements

All candidate trades must pass through the deterministic risk gate before paper execution.

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

The risk gate must be implemented as deterministic application logic, not as an AI prompt.

---

## 9. Manual approval requirements

Paper trades must require manual approval in the MVP.

A candidate may only become a paper trade after:

```text
candidate exists
triangle review exists
risk decision exists
risk decision is not BLOCK
user explicitly approves paper execution
```

Blocked candidates must not be approvable.

Rejected candidates must not be executable.

The UI must clearly indicate that approval creates a simulated paper trade only.

---

## 10. Kubernetes and configuration guardrails

The Kubernetes configuration must set:

```text
EXECUTION_MODE=PAPER_ONLY
REVIEW_PROVIDER=mock
```

During the MVP, Kubernetes manifests must not contain:

```text
broker API keys
broker usernames
broker passwords
live trading credentials
exchange credentials
real account IDs
```

Secrets may be introduced later for OpenAI configuration, but they must not include broker credentials during the MVP.

---

## 11. Database guardrails

The database may store simulated trading artefacts:

```text
paper_orders
paper_fills
positions
portfolio_snapshots
outcomes
```

The database must not store:

```text
real broker credentials
real broker session tokens
real account numbers
real order identifiers
real fill identifiers
live trading API keys
```

If real broker research is ever added later, it must be isolated behind a future ADR and explicit safety design.

---

## 12. UI guardrails

The UI must clearly label simulated activity.

Use wording such as:

```text
Paper Trade
Paper Position
Simulated Fill
Paper Portfolio
Execution Mode: PAPER_ONLY
```

The UI must not use misleading wording such as:

```text
Live Trade
Real Order
Broker Position
Actual Fill
Real Account
```

unless a future ADR explicitly introduces live execution.

Candidate approval buttons should be labelled clearly:

```text
Approve Paper Trade
Reject Candidate
```

Do not use ambiguous labels such as:

```text
Buy
Trade Now
Execute
Place Order
```

during the MVP.

---

## 13. Testing requirements

Tests should verify that:

```text
execution mode defaults to PAPER_ONLY
invalid execution modes fail closed
blocked candidates cannot be approved
paper execution does not call broker code
paper execution creates only simulated orders/fills/positions
AI review cannot bypass the risk gate
risk gate enforces max position size
risk gate enforces max total exposure
risk gate blocks duplicate open positions
```

If a broker-like interface is ever introduced for testing, tests must prove it cannot reach an external broker.

---

## 14. System event requirements

Traderoo should record system events for safety-relevant actions.

Examples:

```text
ExecutionModeValidated
InvalidExecutionModeBlocked
CandidateBlockedByRiskGate
PaperTradeApproved
PaperTradeRejected
PaperTradeOpened
PaperExecutionFailedClosed
AIReviewRejectedBySchemaValidation
```

These events should be visible in the dashboard or system event log.

---

## 15. Failure behaviour

Traderoo should fail closed.

If the system is unsure whether an action is safe, it should block the action.

Examples:

```text
missing execution mode → block
unknown execution mode → block
missing risk decision → block
missing triangle review → block
stale data → block
invalid AI review output → block or require human review
candidate already rejected → block
candidate already executed → block
```

No ambiguous state should result in a paper trade.

---

## 16. Future live trading requirement

Live trading is outside the MVP.

Before any live trading functionality is added, Traderoo requires a new ADR covering:

```text
broker selection
account type
asset classes
execution limits
kill switch design
manual approval design
credential handling
audit logging
regulatory considerations
testing strategy
rollback plan
maximum capital at risk
```

Until that ADR exists and is accepted, live trading remains prohibited.

---

## 17. Copilot implementation instruction

When GitHub Copilot or any AI coding assistant works on Traderoo, it must follow these rules:

```text
Do not add live broker integration.
Do not add real-money execution.
Do not add leverage, CFDs, spread betting, or options.
Do not create code that can place real orders.
Do not create broker credential configuration.
Keep execution mode PAPER_ONLY.
Use paper orders, paper fills, and paper positions only.
Route all candidate trades through the deterministic risk gate.
Require manual approval before paper execution.
```

If a requested change appears to violate these rules, Copilot should stop and ask for clarification rather than implementing it.

---

## 18. Summary

Traderoo MVP is a paper-only control plane.

The system may observe, analyse, review, simulate, monitor, alert, and evaluate.

It must not place real trades.

The defining rule is:

```text
No real money. No real orders. No live broker. PAPER_ONLY.
```
