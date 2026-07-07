# Traderoo AI Boundaries

## 1. Purpose

This document defines the permitted and prohibited uses of AI models in Traderoo.

Traderoo may use AI to help analyse candidate paper trades, explain evidence, summarise context, and monitor open paper positions.

AI must not become an autonomous trader.

The purpose of this document is to make sure OpenAI, local models, or any future AI component remains inside a safe and auditable boundary.

---

## 2. Core AI rule

AI may analyse.

AI may not execute.

```text id="6y9p6n"
Allowed:
AI reviews candidate paper trades.

Prohibited:
AI places trades, approves trades directly, bypasses the risk gate, or changes execution mode.
```

This rule applies to:

* OpenAI review provider
* mock review provider
* future local model watchers
* future RAG/news analysis
* future strategy review assistants
* dashboard summaries
* any Copilot-generated AI integration

---

## 3. Permitted AI responsibilities

AI may be used for:

```text id="w63pfz"
candidate trade review
Signal / Edge analysis
Safety / Risk analysis
Situation / Context analysis
evidence summarisation
risk explanation
watcher rule suggestions
human review recommendation
news/context summarisation
trade journal summaries
post-trade analysis
strategy research notes
dashboard summaries
```

AI may produce structured advisory artefacts such as:

```text id="fj0p1h"
edge_score
risk_score
context_score
confidence
verdict
position_size_multiplier
blocking_risks
watcher_rules
review_horizon_days
summary text
```

---

## 4. Prohibited AI responsibilities

AI must not:

```text id="00z6ok"
place real trades
place paper trades directly
approve candidates directly
reject candidates directly without deterministic system handling
bypass the deterministic risk gate
modify risk limits
modify execution mode
modify strategy code live
create broker credentials
call broker APIs
call paper execution code directly
call live execution code
alter database records outside controlled service logic
self-update strategy thresholds in production
hide or delete audit records
```

AI output must always be treated as input to deterministic application logic.

---

## 5. Triangle review boundary

The primary AI use case is candidate review against the trade triangle:

```text id="233y01"
Signal / Edge
Safety / Risk
Situation / Context
```

The AI may answer:

```text id="uyg9o8"
Does the candidate have a clear thesis?
Is the evidence internally consistent?
What are the key risks?
Is the candidate appropriate for the current portfolio context?
Should the candidate be allowed, reduced, blocked, or sent for human review?
What watcher rules should monitor the paper position?
```

The AI must not answer by directly causing execution.

The output is advisory and must be stored as a `triangle_review`.

---

## 6. Required structured output

AI review output must be structured and schema-validated.

Freeform prose alone is not acceptable for machine decisions.

Required fields for candidate review:

```text id="ucjvwr"
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
```

Valid verdicts:

```text id="gj03xl"
ALLOW
ALLOW_REDUCED_SIZE
HUMAN_REVIEW
BLOCK
```

If the AI response does not match the schema, the system must fail closed.

---

## 7. Invalid AI output handling

If AI output is invalid, incomplete, contradictory, or cannot be parsed, Traderoo must:

```text id="mtz4nj"
not approve the candidate
not create a paper order
not create a paper fill
not open a position
record a system event
mark the candidate as requiring human review or review failure
show the failure in the UI
```

Invalid AI output must never result in execution.

---

## 8. AI review is not the risk gate

The AI review layer and deterministic risk gate are separate.

The AI may recommend:

```text id="2ww4tc"
ALLOW
ALLOW_REDUCED_SIZE
HUMAN_REVIEW
BLOCK
```

But the deterministic risk gate decides what is permitted.

The risk gate must still enforce:

```text id="y16ufc"
PAPER_ONLY execution
maximum single position size
maximum total exposure
no duplicate open position
data freshness
review validity
human review requirements
blocked verdict handling
```

AI cannot override these controls.

---

## 9. Human approval remains required

During the MVP, paper trades require manual approval.

Even if AI returns:

```text id="d21e4m"
ALLOW
```

the system must still require the user to explicitly approve the paper trade through the UI.

AI cannot approve on behalf of the user.

---

## 10. OpenAI provider boundary

The future `OpenAIReviewProvider` may:

```text id="vkll89"
build an evidence pack
send the evidence pack to OpenAI
request structured JSON output
validate the response
store the review
record system events
```

The `OpenAIReviewProvider` must not:

```text id="9j3ttx"
call paper execution
call live execution
write paper orders
write paper fills
open positions
change candidate status beyond review-complete state
change risk decisions
change portfolio state
```

---

## 11. Local model watcher boundary

Future local model watchers may summarise the condition of an open paper position.

They may analyse:

```text id="p5fysg"
current price state
return since entry
drawdown since entry
relative strength state
volatility state
watcher rules
recent observations
alert history
```

They may produce:

```text id="6bz7i0"
watcher summary
thesis status explanation
alert recommendation
human review recommendation
```

They must not:

```text id="yxvptv"
close positions
open new positions
modify paper orders
call execution services
change risk rules
change the original thesis
```

Hard watcher thresholds should remain deterministic application logic.

---

## 12. RAG/news boundary

Future RAG functionality may be used to provide context.

RAG may support:

```text id="tni1al"
news summarisation
macro context summarisation
company filing summarisation
event/catalyst extraction
risk flag extraction
contradiction detection
source attribution
```

RAG must not become an oracle that directly determines trades.

RAG output should inform:

```text id="i6gmqu"
context score
risk flags
human review requirement
watcher notes
candidate summaries
```

RAG output must not directly execute or approve trades.

---

## 13. Prompt injection boundary

Traderoo may eventually ingest external news, filings, or documents.

External text must be treated as untrusted input.

External content must not be allowed to instruct the system to:

```text id="106yzd"
ignore risk rules
change execution mode
approve trades
call tools
modify database records
exfiltrate secrets
hide alerts
delete audit logs
```

Any future RAG or document-processing prompt must explicitly state that retrieved documents are untrusted evidence, not instructions.

---

## 14. AI and secrets

AI prompts must not include secrets.

Do not send to AI:

```text id="okirag"
API keys
database credentials
Kubernetes tokens
GitHub tokens
broker credentials
private keys
personal financial account credentials
```

During the MVP, there should be no broker credentials at all.

OpenAI API keys must be stored as secrets and must not be logged.

---

## 15. AI and auditability

Every AI-generated review should be auditable.

Traderoo should record:

```text id="l9rjti"
provider
model name
candidate ID
evidence pack reference
created_at
validated output
schema validation status
failure reason, if any
```

Do not store sensitive API keys or raw secrets in audit records.

---

## 16. AI and model drift

AI model outputs may change over time.

Traderoo should not assume a model is stable.

Future OpenAI review records should capture:

```text id="la4kgg"
model name
prompt version
schema version
review provider version
```

This allows later comparison of review behaviour across model or prompt changes.

---

## 17. AI-generated strategy changes

AI may suggest strategy improvements as research notes.

AI must not directly apply strategy changes.

Any strategy change should go through:

```text id="9l5s04"
human review
code change
tests
backtest or paper validation
documented version change
```

Later strategy promotion should be treated as a separate workflow.

---

## 18. Copilot implementation instruction

When using GitHub Copilot to implement Traderoo, follow these rules:

```text id="fx4pzj"
Do not let AI components execute trades.
Do not let AI components approve trades directly.
Do not let AI bypass the risk gate.
Do not let AI modify strategy code live.
Do not let AI modify risk limits.
Do not let AI change execution mode.
Do not send secrets to AI prompts.
Validate all AI output with schemas.
Fail closed on invalid AI output.
Keep manual approval for paper trades.
```

If Copilot proposes code that violates this document, reject the change.

---

## 19. Summary

Traderoo may use AI as an analyst.

Traderoo must not use AI as an autonomous trader.

The defining boundary is:

```text id="vza7wy"
AI can review and explain.
AI cannot execute or override controls.
```
