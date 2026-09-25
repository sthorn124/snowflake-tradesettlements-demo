# Closeout — 2026-09-24 — Ask completion: instructions verified, stability bar, the 46-second failure

**Scope.** `SO_caseDetail` v10→**v11** (one chip replaced, with evidence), `SO_askPanel` v3→v4→**v5** (diagnostic added for Task 2, then restored). Two throwaway read-only probes, both deleted and verified absent. **No Snowflake change beyond `DESCRIBE AGENT`.** No connected-system, security or identity change. Demo loaded and reset through the console path.

**Identity.** Dev MCP as `scott.thorn`. Persona reads via sail as `alex.analyst` and `sam.supervisor`. **21 live Cortex calls** this session.

---

## (a) Agent readback — PASSES, checked field by field

`instructions.response` is the authored text, **847 characters, exact match** to `snowflake/agent-instructions.sql`. Preservation verified programmatically rather than by eye:

| field | result |
|---|---|
| `tools` | identical |
| `tool_resources` | identical |
| `instructions.orchestration` | identical |
| `instructions.sample_questions` | identical |
| top-level keys | identical — `['instructions','tool_resources','tools']`, so no `models` block crept in |
| `instructions` keys | identical |

Also unchanged in the raw readback: `owner` FINSERVADMIN, the comment, `profile` null, `created_on` 1787759099.277, and **`versions: ["VERSION$1"]`** — `MODIFY LIVE VERSION` edited in place without minting a version. **Nothing but `instructions.response` moved.**

## (b) The 46-second failure

**1. It does not reproduce.** Chip 3 on the original specimen (`TRD026800`) ran twice at **25 s and 23 s**, both clean, then three more times on the hero at **19/19/23 s**. Five consecutive successes. **I could not capture the error detail because there was no error to capture** — a temporary diagnostic was built into the panel's failed branch (status, Snowflake `code`/`sqlState`/`message`, `numRows`, cell length) and never fired. That build is in git history for re-use if it recurs.

**2. No ceiling below 120 s exists on this path.** Quoted:

- **Appian integration `Timeout (sec)`** — *"the time… after which an integration should time out… This time pertains to the entire integration runtime (prepare + execute + transform). If left blank, the integration will run indefinitely."* Ours is 120. ([Integration Object 26.6](https://docs.appian.com/suite/help/26.6/Integration_Object.html#http-integration-definition))
- **The 90-second limit is real but does not apply here** — *"all nodes time out after 90 seconds"* is scoped to **autoscaled process models**. ([Autoscale Patterns 26.6](https://docs.appian.com/suite/help/26.6/autoscale-patterns-practices.html)) We call from an interface `saveInto`, not a process node.
- **65 s** applies to `a!queryRecordType` / `a!recordData`, not integrations.
- **Snowflake:** the agent's `query_timeout` is **299 s**; our statement `timeout` is **120 s**.

**Every ceiling sits above 46 s. The failure was not a timeout.**

**3. Most probable mechanism — stated as inference, not measurement.** Under the old instructions the agent ran long multi-step explorations. Our statement keeps only `type:"text"` elements; a reply whose `content` array carries none yields `ARRAY_AGG` over an empty set → **NULL → empty cell → the panel's failed branch**. The new instructions ("two to four sentences", "say so in one sentence and stop") make long exploratory runs rare, which is consistent with five clean runs and with latency dropping. **I cannot prove this without a recurrence.**

**Consequence for the demo:** low but non-zero. The panel degrades correctly — one calm amber line, the rest of the screen untouched — and a retry works. **Worth knowing: the panel renders "call errored" and "call succeeded but returned nothing" identically.** That is right for an audience and wrong for diagnosis; if it recurs, the first move is to re-add the diagnostic, not to guess.

**Nothing was changed.** No connected system, no timeout, no platform setting.

## (c) Latency — all 21 runs

| question | run 1 | run 2 | run 3 |
|---|---|---|---|
| Case Q1 · Diamond Trust fail rate | 33 s | 24 s | 35 s |
| Case Q2 · risk factors *(original)* | 34 s | 36 s | 20 s |
| Case Q2 · **replacement** | 26 s | 18 s | 24 s |
| Case Q3 · notional comparison | 19 s | 19 s | 23 s |
| Sup Q1 · top counterparties | 17 s | 21 s | 23 s |
| Sup Q2 · fail rate by asset class | 15 s | 19 s | 13 s |
| Sup Q3 · notional at risk | 12 s | 14 s | 12 s |
| *(chip 3 reproduction attempts)* | 25 s | 23 s | — |

**Range 12–36 s, against Part 1's 22–45 s.** Both the floor and the ceiling came down — the shorter-answer instruction made the agent do less work. The supervisor lookups are now genuinely quick (12–23 s); the comparative case questions remain the slow end (19–36 s).

## (d) The eighteen answers, and the bar

Facts were **stable on all six questions across all three runs**. Every failure below is a *style* failure, not a substance one.

**PASS — Sup Q2 · "What is the settlement fail rate by asset class?"** (15/19/13 s) — clean on all three.
> "Equity has the highest settlement fail rate at 13.91 percent, 2,611 of 18,776 trades, followed by fx_forward at 12.29 percent, 977 of 7,948, bonds at 12.24 percent, 2,043 of 16,697, and etf at 11.93 percent, 785 of 6,579."

**PASS — Sup Q3 · "What is the total notional at risk for High and Critical risk trades?"** (12/14/12 s) — clean on all three.
> "Total notional at risk for High and Critical risk trades is 25.62 billion across 12,464 trades, made up of 20.86 billion from 10,638 High risk trades and 4.77 billion from 1,826 Critical risk trades."

**FAIL (narration 1/3, duplication 1/3) — Case Q1 · Diamond Trust.**
> Run 1: *"I'll compare Diamond Trust's settlement fail rate against the rest of the book.\n\nI need to use the logical column name counterparty_name.\n\n"* then "Diamond Trust runs materially hotter than the book, with a 22.51 percent fail rate, 228 of 1,013 trades, versus 12.63 percent for the rest of the book, 6,188 of 48,987 trades."
> Run 2 (clean): "Diamond Trust runs a settlement fail rate of 22.51 percent, 228 of 1,013 trades, versus 12.63 percent for the rest of the book, 6,188 of 48,987 trades…"
> Run 3: clean prose, but **the entire paragraph is emitted twice.**

**FAIL (narration 3/3, chart reference, duplication) — Case Q2 · risk factors. REPLACED.**
> Run 2 contained: *"I need to actually generate the chart before citing it."* — a chart reference the instructions explicitly forbid, and the panel renders no chart.
> All three narrated. Facts were identical throughout: insufficient securities 34.93% (912 of 2,611), funding gap 29.87% (780), operational error 20.57% (537), counterparty default 14.63% (382).

**MARGINAL (narration 1/3) — Case Q3 · notional comparison.** The question that failed in Part 1b **passed 3/3 here** (19/19/23 s).
> Run 2 (clean): "This trade's 18.7M EUR notional is exceptionally large for an Equity trade, landing above the 99th percentile at 18,769 of 18,784 Equity trades at or below it (99.92 percent)… median of about 164,652 and an average of about 527,725."

**MARGINAL (narration 1/3) — Sup Q1 · top counterparties.**
> Run 1: *"There's a verified query matching this exactly. Let me run it.\n\nI need to use the logical column names from the model.\n\n"* — **verbatim the narration Scott reported.**
> Runs 2–3 clean: "Jade Capital tops the list at 27.23 percent, 281 of 1,032 trades, followed by Beacon Finance at 25.99 percent, 276 of 1,062, and Liberty Trust at 25.28 percent, 251 of 993."

### The replacement, and why only one

**Case Q2 → "What are the most common fail reasons for &lt;asset class&gt; trades?"** — three runs at 26/18/24 s, narration on **1 of 3** instead of 3 of 3, facts identical to the original.

Two reasons, and the second matters more than the first:

1. **Measured improvement.** Flatter, lookup-shaped phrasing narrates less. The two questions that passed cleanly (Sup Q2, Sup Q3) are the flattest of the six; the ones that narrate are comparative and analytical. That is a real correlation with question *shape*.
2. **THE OLD WORDING ASKED THE WRONG QUESTION.** "Risk factors" names `TOP_RISK_FACTORS`, which `CLAUDE.md` records as holding risk **drivers** (Counterparty Risk, Large Notional…), *not* fail reasons. The agent answered with **fail reasons** on every single run. The chip was asking for one thing and being answered with another, and nobody had noticed.

**I did not rewrite the other three.** Case Q1, Case Q3 and Sup Q1 narrate on 1 of 3 runs — **the same rate the rewritten alternative achieves**. Swapping their wording has no demonstrated benefit, and six cosmetic rewrites I cannot show improve anything would be motion, not progress.

**The residual is an instructions problem, not a wording problem**, and it is Snowflake-side and outside this session's scope. The evidence: explicit prohibitions ("never write phrases like 'let me'", "never refer to a chart") were violated on 5 of 21 runs *after* the instruction landed. Phrasing modulates compliance; it does not enforce it.

## (e) Arithmetic reconciliations

| answer | check | result |
|---|---|---|
| Case Q1 | 228 + 6,188 = **6,416** fails; 1,013 + 48,987 = **50,000** trades | exact baseline |
| Case Q2 | 912 + 780 + 537 + 382 = **2,611** | exactly the equity fail count |
| Sup Q2 | 2,611 + 977 + 2,043 + 785 = **6,416**; 18,776 + 7,948 + 16,697 + 6,579 = **50,000** | exact baseline |
| **Sup Q3** | reports **10,638 High / 1,826 Critical** against recorded baseline **10,637 / 1,824** | **+1 and +2 — exactly the packet's 3 seeded High/Critical stories** |

**Sup Q3 is the strongest evidence of the session.** The discrepancy is not an error: it is the loaded DEMO packet showing up in Cortex's own count. It proves the answer is computed live over the current book, not cached and not synced — which is the entire argument the demo exists to make.

## (f) The six questions as they now ship

**Supervisor — "Ask across the book":**
1. Which counterparties have the highest settlement fail rates?
2. What is the settlement fail rate by asset class?
3. What is the total notional at risk for High and Critical risk trades?

**Case detail — "Ask about this case"** (composed from the case's own fields; hero values shown):
4. How does **Diamond Trust**'s settlement fail rate compare with the rest of the book?
5. What are the most common fail reasons for **Equity** trades? *(replaced)*
6. How does this trade's **18.7M EUR** notional compare with typical **Equity** trades?

## (g) Environment restored, evidenced

Loaded: `OK run=DEMO trades=15 predictions=15 high_or_critical=3`; intake created 3 cases; hero `TRD9DEMO01` present.
Reset: `OK run=DEMO trades_deleted=15 predictions_deleted=15`, cases 93/94/95 deleted, `errDelete: false`.
After: **0 `TRD9` rows**, watchlist back to **10 open** fixture cases with live cutoffs, `Straight-through today —`, page renders clean as `alex.analyst`.
Both throwaway probes deleted and **verified absent** from the integration listing.

---

## Two defects found that were not in the brief

1. **THE AGENT WRITES RAW STORED ENUMS ONTO AN ANALYST SCREEN.** Sup Q2 renders **`fx_forward`**, **`etf`**, **`bond`** — the stored values, not the display labels. `CLAUDE.md`'s display-vocabulary canon is explicit that every enum reaching a screen goes through an `SO_*Display` rule, and this is the exact failure it exists to prevent ("Fx_forward" was the original offender). **It arrives through a door the canon never anticipated: agent prose.** The panel cannot map it without parsing answers, so the fix belongs in the agent instructions — "write asset classes as Equity, Bond, ETF, FX forward".
2. **SUP Q3 STATES A HOUSE TOTAL IN NO CURRENCY.** "25.62 billion" — summing notionals across a book that runs EUR/GBP/JPY/CHF. `CLAUDE.md` already ruled that a house value-at-risk **is not computable from the data alone** because nothing carries an FX rate, which is why `SO_fxToUsd` exists and why every screen figure renders "USD eq." with its basis. The Ask panel bypasses that ruling entirely. On stage this is a number a settlements audience may well challenge.

## Promotion candidates

**1 found; 1 carried.**

1. **STAGED (gate 1): an LLM instruction is a strong prior, not a constraint, and compliance must be measured per-run rather than assumed from a successful deployment.** Measured: explicit prohibitions ("never write phrases like 'let me'", "never refer to a chart") were verified present in the deployed specification character-for-character, and were still violated on **5 of 21 runs**. The trap is treating a verified deployment as a verified behaviour — the readback proves the text is there, not that it is obeyed. Working form: sample N runs per prompt and report a compliance *rate*; where a behaviour must be guaranteed, enforce it downstream of the model rather than by instructing it. *Trigger: the next build that depends on an LLM obeying a formatting or content prohibition.*
2. **Carried:** `sail load` replays cached interaction state; `--fresh` is required after a redeploy. Used repeatedly this session and it held every time.

**Promotion checkpoint: current through this entry.**

## TODO changes

Closed 3: chip 3's 46-second failure (investigated — no ceiling, does not reproduce, mechanism inferred); the hero-with-packet verification (done, 9 runs on `TRD9DEMO01`); the agent-instructions item (verified by readback). Added 3: residual narration on 5 of 21 runs needs an instructions strengthening; raw stored enums in agent prose; the uncurrencied house total in Sup Q3.

## BUILD_PLAN changes

Phase 6: Part 1c recorded — instructions verified by readback, stability bar run at 21 calls, one question replaced with evidence, environment restored.
