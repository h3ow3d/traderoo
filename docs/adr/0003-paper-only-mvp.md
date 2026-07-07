# ADR 0003: Traderoo MVP is paper-only

## Status

Accepted

## Context

Traderoo is intended to become an AI-assisted trading control plane.

The long-term concept includes:

* market data ingestion
* pattern observation
* candidate trade generation
* large-model review
* deterministic risk gating
* simulated paper execution
* position watchers
* alerts
* outcome evaluation
* performance dashboards

Because the system concerns financial decisions, the MVP must avoid unsafe automation and avoid creating a false impression of guaranteed or predictable profit.

The first proof of concept should validate the decision lifecycle, not make real trades.

## Decision

The Traderoo MVP will be paper-only.

The system must not place live trades.

The initial execution mode will be:

```text
PAPER_ONLY
```

Out of scope for the MVP:

```text
live broker integration
real-money execution
leverage
CFDs
spread betting
options trading
short selling
fully autonomous execution
```

The paper-only system may:

```text
ingest market data
create observations
generate candidate trades
review candidates
apply a risk gate
allow manual approval of simulated trades
open paper positions
monitor paper positions
create alerts
evaluate outcomes
show performance
```

The risk gate must remain deterministic and separate from AI review.

The OpenAI or large-model review layer may analyse candidates, but it must not execute trades.

## Consequences

### Positive

* The MVP can be built and tested safely.
* The system can validate its decision lifecycle without financial exposure.
* Bugs in ingestion, candidate generation, review, risk, execution, or watchers cannot lose money.
* The dashboard can show traceability from observation to outcome.
* The project can focus on evidence, auditability, and feedback before broker integration.

### Negative

* Paper trading does not prove live profitability.
* Simulated fills may not reflect real slippage, spread, fees, liquidity, or market impact.
* The system will need additional work before any live trading could be considered.
* Some broker integration design choices are deferred.

## Guardrails

The MVP must enforce:

```text
EXECUTION_MODE=PAPER_ONLY
```

The system must not include live broker credentials.

The system must not include live order-placement code.

Any future live execution feature must require a separate ADR.

Any future broker integration must include:

```text
manual approval
strict risk limits
kill switch
audit trail
small position sizing
explicit live-mode configuration
```

## Alternatives considered

### Build live broker integration immediately

Rejected because the decision lifecycle, risk gate, watchers, and feedback loop need to be proven first.

### Build only a backtester

Rejected because Traderoo is not just a backtesting project. The MVP should validate the operational loop: observe, propose, review, approve, simulate, monitor, and evaluate.

### Build a recommendation-only dashboard

Rejected because the system needs a paper trade ledger and outcome memory to learn whether its decisions worked.

## Decision outcome

Traderoo’s MVP will be a paper-only AI trading control plane. Live trading is explicitly out of scope until a later ADR accepts the additional risk and design requirements.
