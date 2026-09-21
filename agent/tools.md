# SO Triage Agent — tool specification

Four tools. Three get built; one is deliberately NOT built and the reason matters (see `record_assessment`).

---

## 1. ~~get_case_context~~ — REMOVED — RECORD-TYPE TOOLS DO NOT TRAVERSE

**Removed from the agent 2026-08-31.** Replaced by the `caseContext` text input.

**The finding.** An Agent Studio record-data tool returns the backing record type's **OWN fields only**. It does not traverse relationships. The Record Fields panel on the tool is **display-only — it shows which fields come back, it is not a picker** and cannot be extended to related record types. Establishing this took two sessions: the tool was configured against `SO Settlement Case`, ran without error, and returned case fields with every related field simply absent — the same shape a row-security filter or an omitted `fields:` list produces, which is what made it slow to diagnose.

**How it surfaced.** Three live runs on 2026-08-31 produced assessments that all said some version of *"the case context returned no counterparty, notional, or fail-probability figures."* The agent's grounding rule fired correctly — it reported the gap and discounted confidence rather than inventing figures — so confidence landed at 0.1–0.7 and **the straight-through lane was never exercised**. The agent behaved correctly; the tool could not supply what the design assumed.

**The two ways out, and why this build chose the second.**

| option | cost |
|---|---|
| One record-type tool per record type (case, trade, prediction, counterparty) | Four tool calls per run minimum. Directly contradicts the tool-discipline instruction, multiplies latency on a path already measured at ~46s, and makes the trace unreadable. |
| **Process-side assembly into a single text input** ← chosen | One query, composed by `SO_caseContext` before the agent node. Deterministic field order and wording, no per-run query variance, and the query runs in the process's security context rather than the agent identity's — so row-level security stays where §12 puts it. |

**Replacement contract** — the agent now takes a single input:

- **`caseContext`** (Text). A labeled plain-text block assembled by `SO_caseContext(caseId)` and passed from `pv!caseContext`. Sections in fixed order: `CASE:`, `TRADE:`, `PREDICTION:`, `COUNTERPARTY:`. Every field null-safe; a missing counterparty renders `COUNTERPARTY: not found` rather than erroring, and the agent's grounding rule takes it from there.

**Grants note that still applies.** `SO_caseContext` runs in the process, so it reads under the process initiator's scope, not the agent's. Row-level security on `SO Trade` therefore governs what reaches the context — a caller outside SO Supervisors will silently get a thinner block, not an error (§5/§7: a filtered read and a broken relationship render identically).

## 2. propose_remediation

**Type** — expression rule tool.
**Backing object** — `SO_remediationForReason` `_a-0000f04a-c437-8000-9c47-011c48011c48_561387`.

**Input** — `failReason` (Text), one of the four canon values.

**Output** — a map with three keys:

| key | meaning |
|---|---|
| remediation | the remediation text — the ONLY source of remediation wording in the application |
| urgency | HIGH / CRITICAL / MEDIUM |
| stDisposition | the disposition code to stamp on a straight-through resolution, or null where straight-through is forbidden |

`stDisposition` was added to this rule on 2026-08-28 (this pass). It is null for `counterparty_default` — which is what makes "never straight-through a credit case" a property of the data rather than a rule the agent has to remember. Any input outside the canon four, including null, returns `Manual review` / `MEDIUM` / null and never errors.

**Grants** — the agent identity needs Viewer on the rule.

---

## 3. snowflake_analyst

**Type** — MCP tool, already live. No build required.
**Backing object** — connected system `SO Snowflake MCP`, tool `trade_settlement_analyst` (Cortex Analyst over the `TRADE_SETTLEMENT_ANALYTICS` semantic view).

**Input** — `message` (Text). Natural-language question.
**Output** — the analyst's answer text.

**Scope discipline** — this is the cheap lookup tool. Its sibling `settlement_risk_agent` is the expensive multi-step agent and is **deliberately NOT given to this agent**: a one-hop delegation is not needed for single-case triage, and its availability is what produced the Phase 1 three-call trace. Ask it counterparty- or market-level questions only, and only when the answer would change the remediation choice.

**Depends on** the network policy to Snowflake. While the demo runs on the 24h bypass, this tool is the first thing that breaks when the bypass lapses.

---

## 4. record_assessment — NOT BUILT (deliberate)

**What it would do** — write the agent's `remediation` and `confidence` back onto the case.

**Why it is not a tool.** The process model `SO_triageCase` already consumes the agent's structured output and writes those fields itself, on the branch that its own routing decided. Giving the agent a write tool would create a **second write path to the same two fields**, and §6's write-path census is explicit that audit coverage is defined by enumerating write paths — two paths to one field means either two audit stories or one silent one. It would also let a write happen before the confidence gate has decided anything, so a case could carry a remediation it was never routed for.

**Consequence for the build** — the agent is read-only. Every mutation of a case in this application goes through a process model's Write Records node, error-wired, with its event gated on write success. Keep it that way.
