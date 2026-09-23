# Closeout — 2026-09-23 — Watchlist restructured to the v5 mockup; console final copy; a demo-breaking supervisor defect found

*Scope and identity:* Dev MCP as `scott.thorn`, member of `SO Supervisors` — **every readback in this session is full-scope**, so every desk-scoped figure below is derived by filtering in a throwaway probe, never by what the screen showed me. No `appian_*` tools, no `ping`. No sail (see "not verified"). Two production objects changed: `SO_analystWatchlist` (v16 → v18), `SO_demoAdminConsole` (v9 → v11). Nothing else in the application was touched.

---

## Gate

**The mockup gate failed on the first read and the session stopped.** `mockups/analyst_watchlist.html` was still the old flat-list mockup — unchanged since the retrofit commit, neither `Latest scoring batch` nor `CLEARED THIS BATCH` present — and the v5 content was sitting beside it as an untracked `mockups/analyst_watchlist_v5.html`. Reported and held. On Scott's word ("replace it") the v5 file was moved over the canonical name, the gate was re-run against it (both markers present, all three queue headings present), and the session continued.

**Environment gate passed:** 17 cases, all tagged `P4-VERIFY`; 12 comments; 14 audit rows; 0 reserved `TRD9` trades.

**Preflight flags (reported, not gating):**
- **Version pin drift.** Dev MCP and sail both report **26.6.95** (build `20260911-210447`); `reference/toolchain.md` pins **26.6.90** (`20260903-195919`). App Market says `UP_TO_DATE`, so the *pin* is stale, not the server. Say "run the update procedure" to re-verify §1/§2/§12 against the new build. Downloads: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` (operator entry) and `https://ny.appiancloud.com/suite/plugins/servlet/stateless/lcp-mcp-bundle` (direct bundle).
- **No persona sail sessions for this build.** `~/.sail-*` holds only `sd.accountant` and `sd.assetmanager` (another build); `~/.sail-designer` and `~/.sail` hold none. Per core §2 step 9 the `alex.analyst` and `sam.supervisor` verifications were **skipped, not substituted** — they are in the browser checklist below.
- Repo and installed `appian-supplemental` copies are identical.

---

## (a) Task 0 — data reconciliation, from live queries

A real run (`DEMO`) was loaded through the console's own process model, measured, and reset. Everything below is read from rows, not from `packet-spec.md`.

### 1. Desk mix of the 15 packet trades

| desk | count | sequences |
|---|---|---|
| **EQ_FLOW** | **8** | 01, 02, 03, 04, 08, 11, 13, 15 |
| FI_TRADING | 3 | 05, 09, 14 |
| FX_DESK | 2 | 06, 10 |
| ETF_MM | 1 | 07 |
| CREDIT | 1 | 12 |

**All three stories are EQ_FLOW**, as intended. Of the background twelve, **5 are EQ_FLOW** (04, 08, 11, 13, 15) and 7 sit on other desks. So an EQ_FLOW analyst sees **8 of the 15** packet trades — the three stories plus five background rows.

### 2. The standing fixture book as an EQ_FLOW analyst sees it

**13 of the 17 fixture cases are EQ_FLOW**; the other four are one each on FI_TRADING, FX_DESK, ETF_MM and CREDIT.

| stored status | displayed | EQ_FLOW count |
|---|---|---|
| New | New | 4 |
| Agent Triage | In triage | 0 |
| Pending Analyst | Awaiting review | 2 |
| In Remediation | In remediation | 2 |
| Escalated | Escalated | 2 |
| Resolved - Straight Through | Resolved · straight through | 1 |
| Resolved - Analyst | Resolved · analyst | 2 |

**Open (the five open statuses): 10** — 8 needing the analyst, 2 escalated.

**Standing escalations exist, and both are good demo material:**
- **SO-39** `TRD001089`, `funding_gap`, score 0.35, **past cutoff** — renders as *Window breached · confirm lag 3.0h · past cutoff*.
- **SO-40** `TRD010391`, `counterparty_default`, score 0.86 — renders as *Reason override · counterparty default — credit decision required*. This is the case CLAUDE.md's lane rule was bought with: a high score that is escalated anyway.

So the ESCALATED queue is **never empty**, with or without a demo loaded.

### 3. What "cleared this batch" can query

Everything needed is present and desk-securable.

- **Below-threshold packet predictions.** All 15 predictions are reachable, and **12 of 15 sit below the High floor** (tiers Low/Medium, p 0.10–0.45) — exactly the twelve background trades. The EQ_FLOW subset is **5**: `04` Low 18%, `08` Medium 31%, `11` Low 19%, `13` Medium 45%, `15` Medium 26%.
- **Fields for the Disposition column:** `riskTier`, `failProbability`, `scoredAt` from the prediction; side, quantity, notional, currency from the trade; ticker and counterparty name through the relationships.
- **The batch stamp is real and single-valued.** All 15 predictions of the run carried **one identical `scoredAt`** (`2026-09-23 10:33:15` local, 14:33 UTC) — `SIMULATE_FEED` writes it explicitly at call time, so the run genuinely has one scoring moment to name.
- **The straight-through case** SO-74 / `TRD9DEMO03`: status `Resolved - Straight Through`, `confidenceScore` 0.90, `disposition` **`Settled - Corrected`**, `proposedRemediation` `Correct & resubmit`, `resolvedOn` 10:34:34.
- **MEASURED AND CONSEQUENTIAL: process-written cases come back with `createdOn` NULL and `modifiedOn` NULL.** All three demo cases; all three fixture resolved cases have both populated. This is why the console's load timestamp is read from `SCORED_AT` and not from the case — and it is the root of the supervisor defect in (f).

**Nothing rendered empty or absurd on the real mix.** For an EQ_FLOW analyst the loaded screen reads: batch 8 trades → 5 cleared by Snowflake · 1 agent-resolved · 1 needs review · 1 escalated, and "6 of 8 without analyst touch". No desks were retagged and the packet was not altered.

---

## (b) Objects changed, with readback

### `SO_analystWatchlist` — `_a-0001f054-7a62-8000-9c49-011c48011c48_562262`, **v16 → v18**
Readback: `updateInterface` returned the stored expression **byte-identical** to the local `.work` copy on both saves (verified by comparison, not by eye). `validateDesignObject` → `hasErrors: false`. `testInterface` → `diagnostics.error: null` in both data states.

- **KPI strip** stays four book-level cards. Cards 1–3 unchanged in definition; card 1's sub-line now reads `N need action · N escalated`, which is the two queues beneath it. Card 4 is now batch-scoped (below).
- **Latest scoring batch band** added between the KPIs and the queues: snowchip, "Latest scoring batch", the derived stamp, the desk-scoped trade count, and the count chips.
- **Three stacked queues** replace the single grid, each its own card: NEEDS YOUR ACTION (selectable, feeds the rail, paged footer), ESCALATED — WITH SUPERVISOR (muted, `selectable: false`, no action affordances), CLEARED THIS BATCH (collapsible `a!sectionLayout`, initially collapsed, `selectable: false`).
- **Preview rail unchanged** in structure and contract.

### `SO_demoAdminConsole` — `_a-0000f057-1da8-8000-9c4b-011c48011c48_564828`, **v9 → v11**
`validateDesignObject` → `hasErrors: false`; `testInterface` → `error: null`.

- One **explainer box** at the top of the Run card, above both buttons, carrying Scott's copy verbatim. **Both button captions deleted** — confirmed absent in the render tree.
- Status line now `Demo loaded 23 Sep 10:33  ·  15 trades  ·  3 cases` (rendered, verbatim).
- **Amber stale-date line** added, and **rendered** (see verification).

---

## (c) The query definitions, stated plainly

**"Open" — one definition, and the KPI cannot drift from the queues because it is not computed separately.**
`local!caseRows` queries SO Settlement Case with `status in {New, Agent Triage, Pending Analyst, In Remediation, Escalated}`. The open-fails KPI counts the rows assembled from that query. The two case queues then **partition** the same assembled set on one boolean, `isEscalated`:

- NEEDS YOUR ACTION = rows where `status <> "Escalated"`
- ESCALATED = rows where `status = "Escalated"`

There is no second status list anywhere in the interface, so `open = needs + escalated` holds by construction rather than by agreement. Verified both ways: **16 = 12 + 4** loaded, **14 = 11 + 3** after reset.

**The batch.** `local!batchTrades` queries **SO Trade** — not SO Trade Predictions — filtered `tradeId starts with "TRD9"`, pulling the 1:1 prediction through the relationship. Anchoring on SO Trade is deliberate: record-level security is defined there, so the band and the cleared queue are desk-scoped **by construction**, not by a filter this screen would have to be trusted to keep correct. `"starts with TRD9"` is the same predicate the console uses for its demo-trade count, so console and watchlist cannot disagree about what is loaded.

**The batch timestamp.** The assembled batch rows are sorted by `scoredSortKey` descending and row 1's `scoredAt` is taken. **Not `max()`** — `min()`/`max()` over Dates return a Decimal, which then cannot be rendered as a time.

**The three queue populations.**
1. **NEEDS YOUR ACTION** — open cases, not escalated, sorted by `cutoffSortKey` ascending (hours to cutoff, with a null cutoff pinned to 99999 so it sorts last rather than reading as most urgent). Default view is the **4 nearest**; the footer toggles to all and back.
2. **ESCALATED — WITH SUPERVISOR** — open cases where `status = "Escalated"`, same sort.
3. **CLEARED THIS BATCH** — batch trades classified into exactly one bucket each: `SCORED_CLEAR` (no case, tier below High), `AGENT` (case resolved straight through), `ANALYST` (case resolved by an analyst), `ESCALATED`, `NEEDS`, or `UNCASED` (no case but tier is High/Critical — intake in flight, or failed). The cleared queue shows the first three. **Because every trade lands in exactly one bucket, the band's chips always sum to the batch's trade count** — verified 12 + 1 + 1 + 1 = 15.

**"Straight-through today"** is `SCORED_CLEAR + AGENT` for the batch. An analyst-resolved case is deliberately excluded: it had analyst touch.

---

## (d) The no-run band behaviour, and why

**The band hides when no packet is loaded. So does the CLEARED THIS BATCH card. The straight-through KPI renders "—" with the sub-line "no scoring batch on your desk".** All three are governed by one local, `local!hasBatch`, so they cannot disagree about whether a batch exists.

The brief allowed "collapse to whatever the latest scoring state truthfully is, or hide". Hiding was chosen because every value in the band is a fact **about a batch** — a stamp, a trade count, four dispositions — and with none loaded each one is zero or blank, which is a row of noise under a heading that is no longer true. The alternative reading would mean naming the newest `scoredAt` across the 50,000 baseline predictions: real, but not a batch, and absurd under the words "latest scoring batch". The KPI says "—" rather than falling back to the standing book's resolved count, because two different meanings under one label is the thing the display canon exists to prevent.

Verified in both states: band and cleared card **present** with a run loaded, **absent** after reset, with the two case queues and the KPI strip unchanged either way.

---

## (e) Scott's browser script — the loaded state, end to end

1. **Open `settlement-ops-admin` → Admin.** Verdict reads `Ready · data 50,000/50,000 · 9/9 connections · agent OK`. Status reads `No demo data loaded.` **Check the explainer box sits above the status line and both buttons, and that there are no captions under the buttons.**
2. **Press "Load the demo."** Expect `Feed loaded` and, verbatim, `OK run=DEMO trades=15 predictions=15 high_or_critical=3`. **Wait about 90 seconds** for intake and triage.
3. **Refresh the console.** Status should now read `Demo loaded <d mmm hh:mm>  ·  15 trades  ·  3 cases`, with **no amber line** (loaded today). Verdict stays green.
4. **Open `settlement-ops` as `alex.analyst` → Watchlist.**
   - KPI strip: open count equals `N need action` + `N escalated` in its own sub-line.
   - **Batch band** below the KPIs: snowchip, "Latest scoring batch", today's time, **8 trades on your desk**, and chips `5 cleared by Snowflake · 1 agent-resolved · 1 needs review · 1 escalated`. The four chips must sum to 8.
   - **NEEDS YOUR ACTION**: sorted by cutoff. `TRD9DEMO01` carries the small blue **batch-time tag** beside its id, Agent column reads `Held · 62` over `below the 80 release gate`. **It should be the 4th row — the last one visible before the footer.** Footer reads `showing 4 nearest cutoffs   View all 9`; click it and all nine appear; click again to collapse.
   - Click `TRD9DEMO01`: the rail shows SAP GY, 18.7M EUR, 83% Critical, *Fits the window*, the release-gate bar at 62 against 80, and the agent assessment with its AI attribution.
   - **ESCALATED — WITH SUPERVISOR**: `TRD9DEMO02` with `Window breached` over `confirm lag 26.1h · 2.4h to cutoff`, plus the two standing escalations. Muted styling, no clickable actions.
   - **CLEARED THIS BATCH**: collapsed, summary reads `5 cleared by Snowflake scoring · 1 resolved by the agent · 6 of 8 without analyst touch`. Expand: the agent row first (`Agent resolved · score 90` / `Settled - Corrected`), then five `❄ Cleared by Snowflake scoring` / `no case needed` rows. Confirm the scored-clear trade ids are **not** links and the agent row's id **is**.
   - **Straight-through KPI** reads `6`, sub-line `6 of 8 in latest batch · no analyst touch`.
5. **Open the Supervisor tab as `sam.supervisor`.** ⚠️ **Expect this to be broken while the demo is loaded** — see (f). Confirm the failure so it is on the record from a real browser, then move on.
6. **Back on the console, press "Reset the demo."** Expect `Cleaned up`, the was/now evidence line ending in `0 cases`, and `OK run=DEMO trades_deleted=15 predictions_deleted=15`.
7. **Re-open the watchlist.** Batch band gone, CLEARED card gone, straight-through KPI reads `—  ·  no scoring batch on your desk`, two queues remain. Supervisor tab renders again.

### Geometry and paint — browser-only, nothing here is terminal-verifiable
- Do the three queues read top-down as **urgent → muted → quiet**?
- Is the **batch tag** legible without shouting at 1440px?
- Does the **cleared summary line fit one line** at laptop width, or wrap?
- Does the **view-all footer** sit as a footer rather than floating?
- Does the **amber stale-date line** read as a state and not an error? (To stage it: load a demo, leave it overnight, open the console the next morning.)
- Does the **explainer box** read before the buttons, and does the grey panel separate it enough from the status line?
- Do the two-line grid cells (Agent, Cutoff, Fail risk, Status, Disposition) sit level, or does one column's second line push its row taller?

---

## Verified, and how

| what | how | result |
|---|---|---|
| Watchlist, demo loaded | `testInterface` as `scott.thorn` (full scope) | `error: null`; open 16 = needs 12 + escalated 4; band `10:33 today · 15 trades`; chips 12+1+1+1 = 15; footer `showing 4 nearest cutoffs / View all 12`; cleared summary `12 … · 1 … · 13 of 15 without analyst touch` |
| Watchlist, no demo | `testInterface` after reset | `error: null`; open 14 = 11 + 3; band **absent**; cleared card **absent**; KPI `—` / `no scoring batch on your desk` |
| Both verbs render distinctly | render text nodes | one `Agent resolved · score 90` / `Settled - Corrected`; twelve `Cleared by Snowflake scoring` / `no case needed`. No scored-clear row rendered as agent activity. |
| Escalation sub-lines | render text nodes | `Window breached / confirm lag 26.0h · 2.2h to cutoff`; `Window breached / confirm lag 3.0h · past cutoff` (negative hours handled, no mangled sign); `Reason override / counterparty default — credit decision required` ×2 |
| Batch tag | render text nodes | `10:33` beside `TRD9DEMO02` in the escalated queue; absent on standing rows |
| **Rail binds to the restructured queue** | throwaway copy with the selection pre-set, rendered, deleted | Full rail for SO-72: SAP GY, 18.7M EUR, 83% Critical, *Fits the window — 1.2h against 2.8h remaining*, gate bar at 62/80, AI attribution `SO Triage Agent · 10:34`, assessment text, `Open case →` |
| Console, loaded | `testInterface` | `Ready` verdict; explainer box both lines; `Demo loaded 23 Sep 10:33  ·  15 trades  ·  3 cases`; no captions; Reset `disabled: false` |
| **Console amber stale line** | throwaway copy with the date comparison inverted, rendered, deleted | `Loaded before today. Reset, then Load for fresh dates.` at `#96590A`, SMALL, STRONG, with the status line's margin correctly collapsing to sit above it |
| Console word budget | counted from the rendered strings | **exactly 60 words**, longest sentence 11 |
| Supervisor regression | `testInterface`, loaded then reset | **FAILS loaded, passes clean** — see (f) |
| Cleanup | `listInterfaces` query `SO_zz` | `total: 0` — all three throwaways gone |
| Environment restored | probe query | 17 cases (all `P4-VERIFY`), 12 comments, 14 audit rows, 0 `TRD9` trades, 0 `TRD9` predictions |

**Per-session ritual (core §2.7) was run**: `fixtures/p4-verify-redate.py`, all three CSVs applied through `updateRecordData` before anything rendered.

## Not verified, and why

- **Nothing was verified as a persona.** There is no live sail session for `alex.analyst` or `sam.supervisor` on this machine, so the desk-scoped view — the one the demo actually shows — is unobserved. Every figure above is full-scope or probe-derived. `SAIL_USERNAME`/`SAIL_PASSWORD` plus one `sail login` per persona would close this permanently.
- **All geometry and paint.** The render tree carries colour values and requested widths and no pixels.
- **The view-all toggle and the cleared section's collapse were not clicked** — both are `a!dynamicLink` / `a!sectionLayout` configuration, verified as configuration and by the footer's rendered text, not by interaction.
- **The console buttons were not pressed from the console.** Load and Reset were exercised through their process models directly; `a!startProcess` cannot be invoked from `testInterface`.

---

## (f) Stopped on, and flagged

### 🔴 BLOCKING THE DEMO — `SO_supervisorCommand` breaks whenever a demo is loaded

**Not caused by this session's changes, and deliberately not fixed** (the brief says supervisor screens stay untouched). But it is the most important thing found today.

**Measured, with a control:**

| state | `testInterface` on `SO_supervisorCommand` |
|---|---|
| demo loaded | `Expression evaluation error … at function 'text' [line 351]: A null parameter has been passed as parameter 1` — **the whole page fails to render** |
| after reset | `error: null` |

One variable changed. The cause is exact: `local!cycleList` on **line 345** guards the null —

```
if(a!isNullOrEmpty(index(fv!item, "modifiedOn", null)), "", text(index(fv!item, "modifiedOn", null), "yyyy-mm-dd"))
```

— and `local!cIdx` on **line 351** does not:

```
local!cIdx: wherecontains(true, a!forEach(items: local!resolved,
  expression: text(index(fv!item, "modifiedOn", null), "yyyy-mm-dd") = local!c)),
```

A process-written case has a NULL `modifiedOn` (measured above: all three demo cases NULL, all three fixture resolved cases populated). **Every demo run produces exactly one straight-through resolution by design**, so the supervisor screen is dead from the moment the agent resolves story 03 until Reset — which is precisely the window in which Act 2 would show it.

**The fix is one line**: give line 351 the same guard line 345 already has. **Ruling wanted** — it is a two-minute change but it is out of this session's scope.

### 🟠 The hero lands on the fold of NEEDS YOUR ACTION

Built to the mockup's four nearest cutoffs. On the real book that puts the demo hero **4th of 9** for an EQ_FLOW analyst — visible, but the last row before the footer, because three standing fixtures have nearer cutoffs (SO-37 at 1h21, SO-51 at 2h36, SO-36 at 2h51, against the hero's 3h05). One more fixture with a nearer cutoff pushes the Act 1 beat below the fold. **Ruling wanted:** raise the default from 4 to 6, or move a fixture cutoff. `local!nearest` is a single local, so either is a one-token edit.

### 🟡 The console is now exactly at its word budget

CLAUDE.md sets "under 60 words of visible prose on the healthy default view". The explainer costs 39 words where the two captions cost 17, and the measured healthy view is now **exactly 60** — at the line, not under it. The copy is yours and specified verbatim, so the budget is what gave; it is recorded in the object's own header so the next edit knows there is no headroom rather than discovering it. Longest sentence is 11 words, inside the 15-word rule.

### Deliberate departures from the mockup, all logged as structural deltas

- **The filter row is gone** (priority / fail reason / search). The v5 mockup has no filters, and with the list partitioned by urgency and sorted by cutoff, search earned less than it costs. **Reversible in one edit if you want it back.**
- **Scores render on the 0–100 scale**, not the mockup's `0.62` / `0.90`. The display canon is explicit that "confidence" is governance vocabulary and analyst screens say a score out of 100. So `Held · 62`, `Agent resolved · score 90`.
- **The Escalation column names the condition, not an actor** — `Window breached` / `Reason override` / `Agent escalated` where the mockup says "By policy". The screen cannot read which mechanism fired (that text lives in the audit trail, and reading it per row is a query per grid row), and a case the agent escalated whose window has since closed would be mis-attributed. The condition is checkable from the same two inputs the policy itself uses.
- **The Agent column's sub-line carries the full canon remediation** (`Treasury funding chase`) where the mockup abbreviates (`funding chase`). There is no short-remediation vocabulary, and inventing one inline is the casing-trick failure the display rule forbids.
- **A fifth and sixth chip exist but are invisible unless non-zero** — `N analyst-resolved` and `N awaiting intake`. Without them the chips stop summing to the trade count the moment you resolve the hero on stage, and "awaiting intake" is a truthful live signal during the ~60 seconds between Load and the cases appearing.
- **The page head cannot say "Equity Flow desk"**, as the mockup does. The screen deliberately has no desk knowledge — that is record-level security, and restating it here would be a second, driftable copy.
- **Cleared rows are not selectable.** Most have no case at all, so there is nothing for the rail to preview; the one that does carries a record link on its trade id instead.

### Carried forward
- Version pins in `reference/toolchain.md` are one release behind the running server.
- No persona sail sessions on this machine.

---

## Promotion candidates: 2 found; 1 promoted, 1 staged

- **PROMOTED to CLAUDE.md** (project rule, fails the noun test on purpose): process-written `SO Settlement Case` rows come back with `createdOn` and `modifiedOn` NULL, while script-written fixture rows have both. Any screen that formats either field must guard the null, and anything that needs a "when" for a process-created row reads a field the process wrote — here, the prediction's `SCORED_AT`.
- **STAGED, gate 1:** *a fixture set and a process-written set can differ in which system-managed fields are populated, so a screen verified against fixtures is not verified against production rows.* Portable if it reproduces. **Trigger: the next build with both hand-authored fixtures and process-created rows in the same table.**
- Unchanged: unused-locals-block-saves (fired again this session and held — `local!actionStatuses` was rejected with `HTTP 400 — Unused Local Variables`, a second observation in the same direction); the agent-boolean method note; Dev MCP process-instance blindness; NTZ-as-UTC; chart-type.

*Promotion checkpoint: current through this entry.*
