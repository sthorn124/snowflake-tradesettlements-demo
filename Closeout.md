# Closeout — 2026-09-24 — Ask panels wired live to Snowflake Cortex (Part 1, partial)

**Read (g) first.** The mechanism works end to end and both panels are live, but **Task 4 is one-third done** — 3 of 6 questions, run once each, not three times. That is the honest state.

**Scope.** `SO_askSnowflake` (new integration), `SO_askAnswerText` (new rule), `SO_askPanel` (new shared interface rule), `SO_supervisorCommand` v8→v9, `SO_analystWatchlist` v19→v20, `mockups/case_detail.html` superseded header. **Zero Snowflake objects created.** No process model, no security or identity change, no triage/intake/console/case-detail change.

**Identity.** Dev MCP as `scott.thorn`. Persona reads via sail as `sam.supervisor` and `alex.analyst`. Preflight: design surface present, drift re-reported (Dev MCP and sail both 26.6.95 vs the 26.6.90 pin, already logged), skills identical, P4-VERIFY re-dated (all three CSVs). **Environment verified at clean baseline this time** — zero `TRD9` rows.

---

## (a) Mechanism chosen, routes rejected, and the read-only argument

**CHOSEN: `SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(?, ?)` over the existing `/api/v2/statements` endpoint**, targeting the pre-existing `FINSERV.TRADE_SETTLEMENT.SETTLEMENT_RISK_AGENT`.

The decision turned on a fact discovered by reading the connected system rather than assuming it: **`SO Snowflake SQL API`'s `baseUrl` is the account root**, not `/api/v2/statements`. Any path on the account is therefore reachable with the existing PAT — which made this a real choice rather than a forced one.

| Route | Verdict |
|---|---|
| **`DATA_AGENT_RUN` via `/api/v2/statements`** | **CHOSEN.** Grounded (the agent runs Analyst over the semantic view and executes the SQL); maximum reuse — same connected system, same PAT, same endpoint, same body shape and same `body.data[1][1]` response path as the proven `SO_simulateFeed`; one call per question. |
| Cortex Analyst REST (`/api/v2/cortex/analyst/message`) | **Rejected on rule (3).** It returns the *generated SQL*, not results — the caller must execute it. Two calls per question. Worth noting it *would* have worked: `semantic_view` accepts a fully-qualified existing view, and `TRADE_SETTLEMENT_ANALYTICS` already exists. |
| Cortex Agents REST (`agents/{name}:run`) | **Rejected on risk, not capability.** Equivalent and viable with `stream:false`, but a new endpoint path and new auth surface against a proven one. Kept as the documented fallback. |
| `AI_COMPLETE` / `CORTEX.COMPLETE` as SQL | **Rejected on rule (1)** — the brief's own warning. Ungrounded unless data is stuffed into the prompt, which is model free-association wearing a SQL costume. |

**Read-only, and how it is actually enforced.** Three things, none of them hope:
1. **The statement is a single `SELECT`.** There is no second statement and no DDL/DML verb anywhere in it.
2. **The question is passed as BINDING 2, never concatenated.** A user cannot alter the statement's shape, whatever they type — this is the same parameterisation that makes SQL injection impossible, applied deliberately.
3. **Answer extraction happens inside that same SELECT** (`FLATTEN` + `WHERE type='text'`), so there is no second round trip to be hijacked.

**What is NOT enforcement, stated plainly:** the integration's `usage` flag. It governs caching and where the integration may be called, **not permissions**. And the PAT is scoped to `FINSERVADMIN`, which owns the schema — so the *role* is not restricting anything. **The residual gap, named:** the agent's own toolset is the one link I could not inspect, because a session has no Snowflake execution path. If `SETTLEMENT_RISK_AGENT` were ever given a tool that writes, the argument above would not cover it. Cortex Analyst itself is text-to-SQL over a semantic model and emits SELECT only.

## (b) Snowflake objects created: NONE — and that is the finding

**Nothing was created, and nothing needed to be.** The agent (`SETTLEMENT_RISK_AGENT`) and the semantic view (`TRADE_SETTLEMENT_ANALYTICS`) already existed. No stage, no semantic model file, no helper view, no deploy note, no `snowflake/` script, and **no Snowsight round trip** — which also means this session had no dependency on Scott running anything first. The additive-only constraint is satisfied vacuously: the 50K baseline, the packet, `SIMULATE_FEED` and `RESET_SESSION` were never touched.

## (c) Integration and settings

**`SO_askSnowflake`** (`3abbedbd-f93b-4ae6-923e-c3a08d7eba66`), v7, on `SO Snowflake SQL API`. **PAT field never touched and never read.**

| Setting | Value | Why |
|---|---|---|
| Path | `/api/v2/statements` | POST, same as the proven integrations |
| `requestTimeout` | **120 s** | Measured answers land 22–45 s; 120 leaves headroom without hanging a demo indefinitely |
| statement `timeout` | **120 s** | Snowflake-side, matched |
| `usage` | **MODIFY** | A caching choice — see (g); not a security one |
| `autoConvertToJson` | **false** | The body is already a finished JSON string |
| `responseBodyParsing` | `CONVERT_JSON` | |
| Headers | `Content-Type`, `Accept`, `User-Agent`, **`X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN`** | The last one is what makes PAT auth work; copied from the working integration rather than rediscovered |

**`SO_askAnswerText`** v4 — trims and guards. It deliberately **no longer parses anything**; see (g).
**`SO_askPanel`** v2 — the panel, built once, used by both screens. Scope is the only parameter that differs.

## (d) Seeded questions and answers — PARTIAL (3 of 6, once each)

**The brief's supervisor topics were adjusted, as it permits, because two of them are unanswerable by this mechanism.** STP trend and escalation patterns live in **Appian** (`SO Settlement Case`), not Snowflake; the Cortex agent cannot see them. The three shipped are the semantic model's own verified queries, which CLAUDE.md flags as the tested vocabulary.

**Supervisor (house scope):**
1. Which counterparties have the highest settlement fail rates?
2. What is the settlement fail rate by asset class?
3. What is the total notional at risk for High and Critical risk trades? *(not yet run)*

**Analyst (scoped to the selected row):**
1. How does this counterparty's settlement fail rate compare with the rest of the book?
2. Which risk factors most often drive settlement fails for trades like this one? *(not yet run)*
3. How does this trade's notional compare with typical trades of this asset class? *(not yet run)*

**Answers captured verbatim — 3 of an intended 18.**

**S1, `sam.supervisor`, 36 s:**
> "The counterparties with the highest settlement fail rates are all classified in the **high** risk tier, led by **Jade Capital** at a 27.23% fail rate (281 of 1,032 trades failed), followed by **Beacon Finance** (25.99%) and **Liberty Trust** (25.28%). … Notably, every counterparty in the top 10 carries a "high" risk-tier classification, and fail rates cluster tightly between roughly 22.5% and 27.2% — reinforcing that the risk-tier labeling aligns well with actual settlement outcomes."

**S2, `sam.supervisor`, 22 s:**
> "There's a verified query that exactly matches this question. Here is the settlement fail rate broken down by asset class. Equities have the highest fail rate at 13.91%, followed closely by FX forwards (12.29%) and bonds (12.24%), with ETFs the lowest at 11.93%. … Equities stand out as the clear leader — its ~14% fail rate is nearly two percentage points above ETFs, and it also carries the largest trade volume (18,776 trades, 2,611 fails), making it the biggest contributor to overall settlement failures."

**A1, `alex.analyst`, `TRD030639` selected, 45 s:**
> "I'll look at the data model first, then compare Beacon Finance's fail rate against the rest of the book. Beacon Finance is a clear outlier on the high side. Its settlement fail rate is **25.99%** (276 fails out of 1,062 trades) — more than double the **12.55%** fail rate across the rest of the book (6,140 fails out of 48,938 trades). That's roughly **2.1x** the book-wide benchmark, so the trade in question (TRD030639, ULVR LN) is with a counterparty carrying elevated settlement risk. … Given the 2+ row comparison with a clear metric, a visual makes the gap easy to read. … The chart makes the gap visually stark: Beacon Finance's fail rate towers over the rest of the book at essentially double the height. Given TRD030639 sits with this counterparty, it's worth treating with above-average settlement scrutiny."

**GROUNDING CHECKED AGAINST RECORDED TRUTH, not taken on trust.** A1's own arithmetic: 276 + 6,140 = **6,416** fails over 1,062 + 48,938 = **50,000** trades — exactly the baseline CLAUDE.md records. S2's equity figures reconcile the same way (2,611 / 18,776 = 13.91%). And A1 names **Beacon Finance**, **TRD030639** and **ULVR LN**, all inherited from the selected row via `contextLine`. The answers are computed over the real book.

**Latency**

| Ref | Persona | Run | Latency |
|---|---|---|---|
| S1 | sam.supervisor | 1 | 36 s |
| S2 | sam.supervisor | 1 | 22 s |
| A1 | alex.analyst | 1 | 45 s |
| FAIL | sam.supervisor | 1 | **1 s** (fails fast) |
| *(earlier, pre-fix)* | sam.supervisor | 3 | 35 / 34 / 39 s |

**Range 22–45 s.** Demo-viable but not brisk: a presenter must talk over it. That is a talk-track fact for Part 2, not a defect.

## (e) Panel behaviour, evidenced

**IDLE** — supervisor, before asking: chips render as `<click>` (were inert `a!tagItem`), the text field is no longer `[DISABLED]`, **Ask** is correctly `[DISABLED]` with an empty draft, and the idle line shows.

**ANSWERED** — the question echoed in bold, the answer, then the provenance line with the snowchip: *"❄ Computed in Snowflake by Cortex over the live book — nothing copied, nothing synced."* Verified rendering on all three answers above.

**FAILED** — exercised deliberately by repointing the integration at `ZZ_NO_SUCH_AGENT`, then restored. Result: **1 s**, and
> "Snowflake did not return an answer. Nothing else on this screen is affected — ask again, or carry on."
**The page stayed alive — 37 display values still rendering.** That matters because the earlier build *did* take the whole page down (see (g)). Restored and re-verified by a fresh 22 s answer.

**ASKING — there is no such rendered state, and I did not fake one.** The call is synchronous, so no intermediate local can paint. I tried to add a per-button spinner: **`a!buttonWidget`'s `enableLoadingIndicator` is rejected by the object validator ("Unrecognized Keyword")** even though it appears in a rendered button's component tree — a fourth instance of the rendered-tree-is-not-a-parameter-list trap. Visible progress is whatever the platform paints during evaluation, and **confirming that it is adequate on stage is a browser check for Scott.**

**Analyst panel placement** — a full-width card at the foot of the queues, per your ruling. Its blurb switches on selection ("Select a trade above…" → "…scoped to the trade selected above"), so it degrades to house-wide rather than to an error.

## (f) Scott's browser script

1. **Supervisor screen, panel geometry** — does the Ask card sit correctly in the right rail without crowding the trend/reason/queue cards below it?
2. **Analyst watchlist, panel geometry** — the new card at the foot of the queues: does it crowd the three queues, and does it sit sensibly beside the 320px preview rail?
3. **The asking state.** Press a chip and watch for ~30 s. **Is the platform's own progress rendering enough that it doesn't look frozen?** If not, that is a real finding — there is no per-button spinner available (above), so the fix would be structural.
4. **Answer typography** — answers run several paragraphs; check line length and spacing at laptop width. **Known cosmetic defect: excess blank lines** between paragraphs (the `CHR(10)||CHR(10)` join compounds with the agent's own newlines).
5. **Provenance line** — snowchip renders, line reads correctly beneath the answer.
6. **Failure styling** — ask with the network throttled or simply trust the evidence in (e); confirm the amber one-liner reads calmly.
7. **One free-typed question per panel**, your choice, as ad-lib insurance.

## (g) Stopped on, and everything that is not done

**1. Task 4 is 3 of 6 questions, run ONCE each — not 18 answers, not the three-run stability bar.** Each call costs 22–45 s plus retrieval, and the session ran out of room after the mechanism itself took four diagnostic rounds. **The stability bar is therefore unproven.** Nothing was fabricated to fill the gap.

**2. No demo packet was loaded, so the analyst panel was verified against a FIXTURE row (`TRD030639`), not the hero.** The environment was at clean baseline and loading a packet costs ~2 minutes plus triage. The context-line mechanism is proven — the answer named the selected trade, its ticker and its counterparty — but **the hero specifically was not exercised.**

**3. The brief's premise was wrong about the analyst panel, and you ruled on it mid-session.** There was only ever ONE dormant panel. The analyst watchlist had none — not in the built screen, not in `mockups/analyst_watchlist.html`, and BUILD_PLAN's Phase 6 line scopes only *"a supervisor Ask panel"*. So the analyst side is new design work, placed by your ruling at the foot of the queues.

**4. Two content defects in the answers, both real and both for Part 2:**
   - **The agent narrates its own process and references a chart that does not exist.** A1 contains *"I'll look at the data model first…"* and *"The chart makes the gap visually stark…"* — the panel renders no chart. On stage that reads as a broken promise. These arrive as `type:"text"` elements, so they cannot be filtered without also filtering answer prose; **the fix is the agent's instructions, not the panel.**
   - Excess blank lines between paragraphs.

**5. The 4000-character truncation is a live constraint, not a solved problem.** Extracting the answer server-side puts today's answers comfortably under it, but a long answer could still be cut. Unmeasured where the cap comes from.

**6. `SO_zzAskProbe` and `SO_zzFastSqlProbe` deleted, both verified by absence (404 / absent from listing).**

---

## Verified / not verified

**Verified.** Object validator accepted every save; `SO_supervisorCommand` v9, `SO_analystWatchlist` v20, both **byte-identical** on readback. Three live grounded answers reconciling to recorded baseline truth. Failure path exercised and page survival confirmed. Idle state confirmed. Restore after the break-test confirmed by a fresh answer.

**Not verified.** Three of six questions; the three-run stability bar; the hero with a packet loaded; all geometry; the asking state's adequacy; the agent's toolset (no Snowflake execution path from a session).

## Promotion candidates

**4 found; 0 promoted, 3 staged, 1 correction to the supplemental.**

1. **CORRECTION TO appian-supplemental §3, measured:** *"Design tooling caps one evaluation at 5 seconds; `testInterface` tolerates longer — the interface route is the only legal and measurable home for real model calls."* **`testInterface` timed out at 5001 ms here too**, identically to `testRule`. The real home for a long model call is a **persona session through sail**, which ran the same call for 45 s without complaint. *Staged for the supplemental with the measurement.*
2. **STAGED (gate 1): a QUERY-usage integration's response is cached, and the cache survives a fresh page load.** Trap: "ask again" silently does not ask, and a repeat-run stability check passes without a second call leaving Appian. Tell: a call that took 35 s returns in 1 s. Working form: MODIFY usage for anything that must genuinely re-run. *Trigger: the next integration called repeatedly with identical inputs.*
3. **STAGED (gate 1): an integration invoked as a smart service must be called through the `rule!` domain, or `fv!result` does not resolve.** The same integration under QUERY usage is called bare. Same object, two call syntaxes depending on usage. *Trigger: the next MODIFY integration called from an interface.*
4. **`enableLoadingIndicator` — fourth instance of the existing rendered-tree trap.** Not new; it strengthens an entry already promoted.

**Promotion checkpoint: current through this entry.**

## TODO changes

Added 5: complete Task 4 (3 remaining questions + the three-run bar); verify the analyst panel on the hero with a packet loaded; **agent instructions leak process narration and promise a chart** (Part 2, agent-side); answer blank-line cosmetics; the 4000-char cap as an unmeasured constraint. Closed 1: the Phase 6 "Ask panel visibly unfinished" item — both panels are now live.

## BUILD_PLAN changes

Phase 6: Ask panels wired; noted Part 1 as partially verified with the gaps named.
