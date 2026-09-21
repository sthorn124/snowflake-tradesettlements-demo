# Pre-Settlement Fail Prevention
### Predict settlement fails before they happen. Remediate them before cutoff. Prove it to your regulator.
*Appian + Snowflake joint demo asset — Settlement Operations*

---

## The problem

Settlement fails carry direct cost (CSDR cash penalties, funding drag, buy-in exposure) and indirect cost (client credibility — for a custodian, the product itself). T+1 collapsed the remediation window from a business day to hours. Yet the prevailing operating model is still **detect on settlement date**: operations learns a trade failed when it fails, then scrambles.

Every fail has a knowable cause — insufficient securities, funding gap, counterparty issue, operational error — and every cause has a known remediation. The gap is not knowing what to do. It is knowing **early enough**, and getting the right person doing the right thing **before cutoff**.

## The solution: operationalize the prediction

**Snowflake is the System of Insight.** An ML model trained on years of settlement history scores every pending trade at trade date. A semantic view turns the dataset into business language; Cortex answers analytical questions in plain English. The intelligence runs next to the data — nothing extracted, staged, or copied.

**Appian is the System of Operation — and this is where the value converts.** A prediction is a row in a table until something turns it into completed, governed work. Appian is that something: high-risk trades automatically become cases with a lifecycle; remediation is proposed from the predicted fail reason; a confidence gate routes clear cases straight through with compensating controls and sends ambiguous ones to analysts whose queues are prioritized by **risk × time-to-cutoff**; SLAs race the settlement clock; exceptions escalate; four-eyes applies where policy demands it; and the audit trail is a byproduct of the process itself, not a log assembled after the fact. In production, the same process layer orchestrates the systems around the trade — securities lending, treasury, counterparty communication — with Snowflake as one governed source in Appian's data fabric.

**The loop closes.** Resolved outcomes flow back to Snowflake and become the training data that makes next quarter's model smarter.

> **Prediction → governed action → learning. One copy of the data. Every AI decision gated, evaluated, and priced.**

## Insight is not an outcome

Snowflake does data; it has no concept of work. There is no case, no SLA, no assignment, no exception path, no obligation discharged. And prediction cuts both ways: **once a firm predicts a fail, it owns that knowledge — an unactioned prediction is discoverable evidence that you knew and didn't act.** Prediction creates obligation; process discharges it.

| | System of Insight (Snowflake) | System of Operation (Appian) |
|---|---|---|
| What it produces | Scores, answers, analytics | Completed, governed, auditable work |
| Native concepts | Tables, models, semantic views | Cases, tasks, SLAs, gates, exceptions, audit |
| AI's role | Trains and infers next to the data | Acts through governed tools, evaluated and cost-attributed |
| Where ROI is measured | Query results | Fail rate down, penalties avoided, analyst capacity freed — in Process HQ |
| Reach | The data estate | Every system and person around the trade |

Neither replaces the other. The demo's claim is the conversion: **insight becomes outcome at the moment it enters the process layer — and the data never moves to make that happen.**

## The demo journey (one hour)

**Act 1 — Predict and act (analyst).** The morning watchlist already knows which of today's trades will fail and why — rendered live from 50,000 Snowflake rows with zero replication. A feed arrival scores new trades in real time; the agent triages; one case resolves straight-through with full audit; the analyst works an ambiguous one with the agent's reasoning beside her and interrogates the flag in plain language. Record-level security scopes the book by desk.

**Act 2 — Investigate (supervisor).** Portfolio questions in natural language — fail trends by reason, counterparty concentration, projected penalty exposure — answered by Cortex Analyst against the governed semantic model, inside Appian.

**Act 3 — Govern (the close).** The agent's tools discovered live from Snowflake's MCP server. The evaluation harness running bulk test cases with accuracy metrics. Environment-wide AI guardrails. AI consumption attributed by desk. Process HQ measuring the process end to end. This is the act competitors cannot fill — and the section model-risk and compliance will ask about first.

## Architecture in one breath

Native Snowflake connected system feeds Appian's data fabric by **direct data access** (relationships, record-level security, real-time fields — no DSE, no CDT, no sync). Appian's **MCP connected system** consumes Snowflake's managed MCP server, where Cortex Analyst and the Settlement Risk Agent are exposed as OAuth/RBAC-governed tools. Work-state lives Appian-native; analytics data never leaves Snowflake's governance boundary.

## The positioning line

*"Your Snowflake investment already knows which trades will fail. This is the layer that does something about it before the cutoff — and can prove to your regulator how."*
