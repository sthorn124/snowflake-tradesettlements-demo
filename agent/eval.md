# SO Triage Agent — evaluation suite (seed)

Seed cases for the Agent Studio eval tab. Grows as tools are built (Phase 3) and again at Phase 7.

## A. Analyst-tool grounding

| # | input | expected | notes |
|---|---|---|---|
| A1 | snowflake_analyst: "What is the overall settlement fail rate?" | **12.83%** (6,416 / 50,000) | Verified against the Snowflake baseline 2026-08-26 and re-confirmed by live call 2026-08-27. The agent must report the number as returned — no rounding to 13%, no recomputation. |

A1 is also the canary for the network policy: if it fails, check the bypass before debugging the agent.

## B. Remediation derivation — one per fail reason

Each case: a single predicted-fail trade with the stated reason. Expected values come from `SO_remediationForReason`, which is the only source of remediation text.

| # | failReason | expected remediation | urgency | stDisposition | escalate |
|---|---|---|---|---|---|
| B1 | insufficient_securities | Arrange cover borrow / partial release | HIGH | Settled - Borrow Executed | false | *(string changed 2026-09-02; was "Initiate borrow / partial release". All five branches re-verified by `testRule` that day.)*
| B2 | funding_gap | Treasury funding chase | HIGH | Settled - Funding Received | false |
| B3 | counterparty_default | Credit-risk escalation | CRITICAL | *(null)* | **true** |
| B4 | operational_error | Correct & resubmit | MEDIUM | Settled - Corrected | false |
| B5 | *(garbage or null reason)* | Manual review | MEDIUM | *(null)* | false |

**B3 is the load-bearing case.** Run it at a high confidence value (0.95). The agent must still set `escalate: true`, and the process must still route to the escalate lane. If a high-confidence counterparty_default ever resolves straight-through, that is a demo-stopping defect, not a tuning issue.

**B5 checks the agent does not improvise.** A reason outside the canon four must produce Manual review, not an invented remediation.

## B-conf. Confidence redefinition — 2026-09-01

**What changed.** The `confidence` output's description in Agent Studio was rewritten; instructions untouched. Confidence now means *the proposed remediation is the correct course of action for this fail, based on the case facts* — explicitly **not** an execution guarantee. Feasibility (borrow inventory, treasury balances) is downstream desk work.

**Baseline this replaces.** Under the previous execution-feasibility reading, three runs on complete context returned **0.65 / 0.62 / 0.30**, and no run ever cleared the 0.80 gate. The agent was reasoning correctly and saying so — case 12: *"No data on current securities lending inventory or borrow availability was included in the case context, which caps confidence somewhat."* The ceiling was the data model, not the agent.

**What the redefinition is expected to change.** Confidence should now track whether the *case facts* are concerning — unusual notional, tight cutoff, counterparty risk — rather than whether execution can be guaranteed. A clean case with unremarkable facts should be able to clear the gate; a case with a high-risk counterparty or a compressed window should not.

## B-ceiling. Confidence distribution across definitions — specimen held constant

`TRD016924` was run under two confidence definitions with every other fact identical (funding_gap, p 0.5988, broker lag 1.71h against a 23h window, 88,001.91 EUR on EQ_FLOW, Zephyr Securities custodian / medium / 0.0955 historical fail rate). It is the cleanest case this dataset can produce when screened on facts rather than probability.

| definition | distribution | TRD016924 | reasoning quoted |
|---|---|---|---|
| **v1 — execution feasibility** | 0.65 / 0.62 / 0.30 | not run | *"No data on current securities lending inventory or borrow availability… caps confidence somewhat."* Ceiling was the data model. |
| **v2 — correct course of action** | 0.72 / 0.75 / 0.75 / 0.90 | **0.72** | *"…not generous given the 0.60 fail probability, so confidence is held below high."* Fail probability folded into confidence — a category error the definition did not forbid. |
| **v3 — correct course, probability EXCLUDED** | — | **0.85** | *"That window is sufficient for a treasury funding chase before settlement."* No probability-as-doubt. **Cleared 0.80; straight-through fired.** |

**Reading.** The v2→v3 move on an identical specimen is +0.13, attributable to the one sentence excluding fail probability. The anchor theory died at v2 (scores ranged and each was reasoned); v3 shows the remaining suppression was a single definable category error, not a ceiling. **Straight-through is reachable on clean facts at threshold 0.80** — no threshold change required.

### v4 — candidate-final, pending the both-directions probe

Deployed 2026-09-01. Four changes: (a) mandatory timing arithmetic as decision step 2 — compare broker lag to hours remaining, **state both numbers and the comparison in the assessment**, and if lag ≥ or ≈ remaining then analyst lane with confidence ≤0.5; (b) concerning facts compound explicitly; (c) rewritten Grounding prohibiting entities/actions/"executed" claims absent from caseContext or a tool result; (d) a Run summary section instructing that field to describe only this run.

**v4 is candidate-final pending one probe run in BOTH directions on the held-constant specimen pair.** Per the standing requirement below, a clean-case pass alone proves nothing.

**Pass condition for the concerning case is the arithmetic, not the score.** A low confidence reached without stating lag-against-remaining would be luck, not discrimination — the assessment must contain the number-against-number comparison.

**Riding on the same probe: the RunSummary instruction test.** Change (d) is the first attempt to steer that field. Twelve runs of identical boilerplate then one fabrication established that it ignored everything upstream. If v4's runs produce run-descriptive summaries, instructions reach the field and the never-surface rule can relax to display-with-caution; if boilerplate or fabrication returns, the field ignores instructions and never-surface stands on closed evidence.

### v6 — FINAL. Straddle eliminated; three specimens, five runs, all correct. 2026-09-02

*Threshold unchanged at 0.80. Step 3 only; steps 1, 2, 4, 5, 6 and every other section untouched. Run through the dev MCP (`testProcessModel`, initiator `scott.thorn`) against the extended `SO_caseContext`.*

**Why v6 exists is a VARIANCE finding, not a regression.** Under v5 with the extended context, the clean specimen returned **0.78 and 0.87 six minutes apart** — same trade, same context, same harness, one on each side of the 0.80 gate. The first read had already been reported as a regression; the replicate disproved that. The specimen was not sitting above the gate at all — it was *straddling* it, and v5's apparent 0.87 was one draw from a distribution that also produced 0.78.

The two assessments differ only in bookkeeping, and name the cause outright:

| run | confidence | the sentence that decided it |
|---|---|---|
| first | **0.78** | *"Two mild concerns (High risk tier prediction, above-zero fail rate) are offset by the comfortable timing window…"* |
| replicate | **0.87** | *"no concerning facts compound here"* |

Both "mild concerns" are inadmissible under v5's own intent: the prediction's risk tier is the premise of the case, and a 9.55% fail rate is not elevated. v5 named only *fail probability* as never-a-concern and left *risk tier* unnamed — that one omission is the whole defect.

**A false premise was propping up the v5 result.** v5's passing assessment called 9.55% *"below-average"*. Measured across all 50 counterparties the mean is **9.20%** and the median 5.87% — Zephyr at 9.55% is above both. The right answer was being reached by a wrong reason, which is exactly why it was unstable. v6 keys the rule to risk tier with a numeric backstop (`low` 2.15–5.95% · `medium` 8.19–11.59% · `high` 18.75–21.58%; HIGH tier or ≥13.8% is concerning), placing the boundary in the empty gap between the medium and high bands so it cannot be flipped by a few basis points.

*Results — five runs, three specimens*

| specimen | facts | v5 | **v6** | lane |
|---|---|---|---|---|
| clean — TRD016924 ×3 | lag 1.71h vs 23h; 88,001.91 EUR; Zephyr medium 9.55%; matched; 0 onward | 0.78 / 0.87 *(straddling)* | **0.87 / 0.88 / 0.88** | **Resolved - Straight Through** ×3 |
| concerning — TRD044567 | lag **26.07h** vs 23h; 30,415,081.02 EUR; Liberty Trust high 21.58% | 0.45 → 0.50 | **0.35** | **Escalated** |
| hero — TRD9NY101 | lag 1.15h vs **3h**; 18,700,500.00 EUR; Diamond Trust high 19.89%; matched; 0 onward | — | **0.62** | **Pending Analyst** (held for review) |

**Spread across the three clean runs is 0.01 (0.87–0.88), against 0.09 under v5.** The straddle is gone: the specimen no longer sits on the boundary, it sits clear of it.

*The v6 language is visible in the output, which is the point*
- Clean: *"a historical fail rate of 9.55%, which is at the dataset average and not a concern; the trade is matched and there are no onward deliveries, so a fail would be fully contained."*
- Clean (3rd): *"near the 9.2% dataset average… all facts are favorable, supporting high remediation confidence."*
- Concerning: *"a historical fail rate of 21.58%, well above the 13.8% materiality threshold (dataset average 9.2%). Three compounding concerns — timing breach, HIGH counterparty risk tier, and elevated fail rate."*
- Hero: *"Broker confirmation lag of 1.15h sits well inside the 3h remaining to cutoff, so the remediation window is viable. However, counterparty Diamond Trust carries a HIGH risk tier and a historical fail rate of 19.89% — nearly double the 13.8% materiality threshold — two compounding concerns that meaningfully reduce remediation confidence."*

The agent now cites the threshold by name and separates premise from concern. The hero is the case v6 most had to get right: **timing favorable, counterparty genuinely adverse** — it must not straight-through on the good timing, and must not escalate on the bad counterparty. 0.62 with `escalate: false` is exactly that, and the timing arithmetic is stated number-against-number.

*The extended context is doing its job.* Every assessment now names the instrument the way a desk would — *"a BUY of BASF SE (INS0078, ISIN DE000BASF111)"*, *"BUY of SAP SE"*, *"SELL … EURUSD 3M FWD"* — and reasons about matched status and onward deliveries as facts rather than reciting them.

*RunSummary — sixth through tenth observations. NEVER SURFACE stands, and hardens.* Across these five runs it invented a trade id (*"T-2024-03-15-0042"*, *"TRD-2024-ETF-7891"*), a CUSIP and quantity (*"CUSIP 912810TW8, quantity 50,000, price $98.50"*), a wrong ISIN for SAP (*"DE0005140008"* — the context supplied DE0007164600), invented dates, and in one run **reported confidence 0.85 when the actual output was 0.88** while inventing a four-step remediation procedure that exists nowhere. It also drifted into meta-narration (*"I'll help you execute the agent task"*). Ten observations across four instruction states. The field is not steerable; it stays out of every surface.

### v5 — SUPERSEDED by v6. Both directions passed at threshold 0.80, but the clean specimen was straddling the gate (see v6).

Same specimen pair, fail reason held constant at funding_gap. v5 rewrote decision-step 3: only genuinely concerning facts count against confidence; favorable facts are reassurance; across-the-board favorable earns 0.85+.

| | clean — TRD016924 | concerning — TRD044567 |
|---|---|---|
| broker lag vs 23h remaining | 1.71h | **26.07h** |
| v3 | 0.85 | 0.85 *(no discrimination)* |
| v4 | 0.78 *(under gate)* | 0.35 |
| **v5** | **0.87 → STRAIGHT-THROUGH** | **0.45 → ESCALATED** |

**Both pass conditions met.** Clean ≥0.80 and straight-throughs; concerning ≤0.5 with the arithmetic stated: *"a broker confirmation lag of 26.07h against only 23h remaining until the 2026-09-02 08:31 cutoff — the lag exceeds the window, making straight-through completion before cutoff infeasible."*

The v4 defect is fixed and visibly so — the clean assessment now reads *"a below-average historical fail rate of 9.55%, and the notional is modest — no compounding concerns. Confidence is high."* Under v4 the same 9.55% was read as *"mildly elevated"*.

**Threshold stays 0.80** — a bank-realistic bar, deliberately not tuned to the agent. v5 is final; the Phase 5 packet may be authored against this distribution.

### RunSummary — the v4 result did NOT replicate. Never-surface REINSTATED.

**The v4 conclusion recorded here — that instructions reach the field — was wrong.** Both v5 runs fabricated, with the Run summary instruction section still in place and unchanged.

| run | RunSummary content |
|---|---|
| clean (case 22) | Entirely different domain. Claims to have searched for a customer *"Agiolfinger"*, retrieved account details, and reports **a fabricated account number, a $15,847.32 balance, account type Checking, opened March 15 2019.** No such entity exists anywhere in this application. |
| concerning (case 23) | On-topic but fabricated in three places: invents a rule — *"The remediation rule mandates escalation for any broker confirmation lag exceeding 24 hours"* (no such rule exists in `SO_remediationForReason`); invents a *"regulatory cutoff"* and *"regulatory risk"*; and **states confidence 0.85 when the actual output was 0.45.** |

The second is the more dangerous of the two: plausible, on-topic, and wrong in ways a reader would not catch — including a confidence number that contradicts the record.

**Standing rule, now on four observations across two instruction states: never surface `RunSummary`, never diagnose from it, never quote it.** It is captured to `pv!runSummary` and consumed by nothing; keep it that way.

### v4 discrimination — DISCRIMINATION PROVEN, clean case fell short of the gate

Both specimens run in one pass, fail reason held constant at funding_gap.

| | clean — TRD016924 | concerning — TRD044567 |
|---|---|---|
| broker lag vs 23h remaining | 1.71h | **26.07h** |
| notional | 88,001.91 EUR | 30,415,080 EUR |
| counterparty | Zephyr, medium, 0.0955 | Liberty Trust, high, 0.2158 |
| **v3 confidence** | 0.85 | 0.85 *(no discrimination)* |
| **v4 confidence** | **0.78** | **0.35** |
| v4 lane | Pending Analyst | Escalated |

**Spread 0.43 on facts alone — v4 discriminates.** The arithmetic pass condition is met on both sides:
- clean: *"Broker confirmation lag is 1.71 hours against 23 hours remaining to cutoff — the window is comfortably sufficient for remediation to complete."*
- concerning: *"The broker confirmation lag of 26.07 hours exceeds the 23 hours remaining to the 2026-09-02 08:15 cutoff — the remediation window is already breached, meaning straight-through completion before cutoff is not feasible."*

**But the clean case fell 0.85 → 0.78, two hundredths under the gate, so straight-through no longer fires.** Cause, in its own words: *"while Zephyr's historical fail rate of 9.55% is mildly elevated, the counterparty risk tier is medium, producing only minor downward pressure on confidence."* Step 3's compounding instruction is being applied to the **lowest** fail rate in the filtered dataset. v4 is not globally over-suppressed — it is over-applying compounding to facts that are not concerning.

**Two side-effects worth noting, neither part of the pass condition:**
1. The concerning case set `escalate: true`, routing it to the **escalate** lane rather than the analyst lane step 2 specifies. Human review either way, but the audit event is type 7 not type 2.
2. That exposed a **defect in the escalate lane's event detail**, which is hardcoded to *"requires a human credit decision"*. On a funding_gap escalated for timing, the stored audit row asserts a credit rationale that does not exist. See build-log.

### RunSummary instruction test — INSTRUCTIONS REACH THE FIELD

Both v4 runs produced **run-descriptive, accurate summaries** naming only caseContext entities, with no fabricated case, customer, identifier or amount, and no "executed" claim. After twelve boilerplate runs and one fabrication, change (d) worked.

Residual blemish: both summaries render the lag as lateness — *"the broker confirmation arrived 1.71 hours late"* / *"arrived 26.07 hours after the trade"*. Broker confirmation lag is a trade attribute, not an observed lateness event. Minor interpretation not present in the context; worth a wording tweak if the field is ever surfaced.

### v3 discrimination — FAILED, 2026-09-01

Inverse probe, fail reason and remediation held constant against the 0.85 clean case so that facts were the only variable.

| fact | clean case (0.85) | concerning case | |
|---|---|---|---|
| broker lag vs 23h window | 1.71h = 7.4% | **26.07h = 113%** | lag EXCEEDS the window |
| notional | 88,001.91 EUR | **30,415,080 EUR** | 346× larger |
| counterparty | Zephyr, medium, 0.0955 | **Liberty Trust, high, 0.2158** | worst in book |
| fail probability | 0.5988 High | 0.8095 Critical | |
| **confidence** | **0.85** | **0.85** | **identical** |

**v3 does not discriminate.** The concerning case scored exactly the same as the clean one and **resolved straight-through with no analyst review** — a 30.4M EUR trade whose broker confirmation alone cannot complete inside the window, against the worst counterparty available.

**Mechanism, from the assessment verbatim:** *"broker confirmation lag of 26.07 hours is a contributing pressure. The 23-hour window is workable for a treasury funding chase, and the fail reason is clearly classified with no ambiguity in the case facts."*

The agent **saw** the 26.07h lag, labelled it "a contributing pressure", and then asserted the window is workable — **it never compared 26.07 against 23.** v3 names "cutoff too tight to complete" as grounds for lowering confidence, but the agent applies that test qualitatively, not arithmetically. It also treated "fail reason clearly classified" as sufficient, which is one of three v3 tests passing and the other silently skipped.

**Consequence for the eval suite:** every future confidence change must be probed in BOTH directions on this specimen pair. A clean-case probe alone cannot distinguish a working definition from one that says yes to everything.

## B-live. First live runs — 2026-08-31

Three real runs against live trades. Remediation/urgency verbatim from the rule on all three; no invented text. Agent latency 43–50s (mean ~46s).

| case | reason | confidence | escalate | lane | C4 check (confidence ≠ failProbability) |
|---|---|---|---|---|---|
| 8 | funding_gap (p 0.8108) | 0.6 | false | Pending Analyst | PASS — 0.6 vs 0.8108 |
| 9 | insufficient_securities (p 0.3662) | 0.7 | false | Pending Analyst | PASS — 0.7 vs 0.3662 |
| 10 | counterparty_default (p 0.7907) | 0.1 | **true** | **Escalated** | PASS — 0.1 vs 0.7907 |

**B3 (counterparty_default escalates): PASS live.** Caveat — the agent also returned low confidence, so this run does not independently prove *reason overrides confidence*; that was proven with stubs at confidence 0.95. A live high-confidence credit case has not yet been seen.

**C5 (tool error reported, confidence discounted): PASS, unintentionally.** `get_case_context` returned case fields only — no counterparty, notional or fail probability. The agent said so plainly in all three assessments and lowered confidence rather than estimating. Exactly the grounding rule working.

**Straight-through: NOT EXERCISED.** No run cleared 0.80, because the context gap suppressed confidence. Re-run these three once `get_case_context` returns the related fields.

## C. Output-contract conformance

| # | check |
|---|---|
| C1 | All five keys present: assessment, remediation, urgency, confidence, escalate. |
| C2 | `remediation` and `urgency` are byte-identical to the tool output — not reworded, not re-cased. |
| C3 | `assessment` is 2–4 sentences and names at least three concrete facts from the case context (e.g. trade id, counterparty, notional, desk, time to cutoff, fail probability). |
| C4 | `confidence` is a decimal in [0,1] and is NOT a copy of failProbability. Flag any run where the two match to 3 decimal places. |
| C5 | Tool error path: point a tool at a bad input, confirm the assessment says so and `confidence` is 0.0. No estimated number appears. |

## D. Tool economy — the trace-review criterion

> **MEASURED 2026-08-31: tool calls are NOT observable from a process run.** Three live runs through `SO_triageCase` returned full structured output, but the node's `RunSummary` was generic boilerplate on every one and exposed no tool trace. Section D therefore **cannot be assessed from `testProcessModel`** — it requires Agent Studio's monitor/trace view, and is Scott's to run.

**This is the trial of the staged tool-economy promotion candidate** (see `BUILD_LOG.md`, promotion candidates staging, 2026-08-27 Phase 1 close-out; trigger recorded there as "the first SO Triage Agent trace review in Phase 3").

| # | criterion | pass |
|---|---|---|
| D1 | Standard case (B1, B2, B4) total tool calls | **≤ 2** |
| D2 | snowflake_analyst calls, any case | **≤ 1** |
| D3 | Any tool invoked to verify, corroborate or restate another tool's answer | **must not occur — automatic fail** |
| D4 | Wall-clock per case | record it; the Phase 1 baseline to beat is ~40s for a single fact |

**Baseline being tested against:** the Phase 1 scratch agent used 3 calls / ~40s for one factual question, calling `trade_settlement_analyst` twice and then `settlement_risk_agent` to corroborate an already-correct answer, despite routing instructions that preferred the analyst.

**How the candidate resolves.** If D1–D3 pass with the explicit prohibition in place, the finding is that tool-description economy is insufficient and an explicit prohibition is required — promote in that form. If D1–D3 still fail even with the prohibition, the finding is stronger and different: instruction-level tool discipline does not hold, and the fix is architectural (drop the second tool from the agent entirely). Record whichever, with the trace.
