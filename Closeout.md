# Closeout — 2026-09-24 — Watchlist v5 build, console final copy, and full persona verification; a demo-breaking supervisor defect confirmed as a real user

*Session span:* began 2026-09-23, continued into 2026-09-24 when Scott added the persona sail sessions. The build is 09-23's; everything under **Persona verification** is 09-24's.

*Scope and identity:* Dev MCP as `scott.thorn` (SO Supervisors — full scope) for all design work. **sail as `alex.analyst` and `sam.supervisor`** for every persona-scoped observation, each from its own data directory, stated per reading. No `appian_*` tools, no `ping`. Two production objects changed: `SO_analystWatchlist` (v16 → v18), `SO_demoAdminConsole` (v9 → v11). Nothing else in the application touched.

---

## Gate

**The mockup gate failed on the first read and the session stopped.** `mockups/analyst_watchlist.html` was still the old flat-list mockup — unchanged since the retrofit commit, neither marker present — with the v5 content beside it as an untracked `analyst_watchlist_v5.html`. Reported and held. On Scott's word the v5 file was moved over the canonical name, the gate re-run (both markers, all three queue headings), and the session continued.

**Environment gate passed:** 17 cases all `P4-VERIFY`, 12 comments, 14 audit rows, 0 reserved `TRD9` trades. Restored to exactly that at close.

**Per-session ritual run twice** — once on 09-23, again on 09-24 when the date rolled over and the fixtures went a day stale. All three CSVs applied through `updateRecordData` before anything rendered, both times.

**Version pin drift (flag, not gate):** Dev MCP and sail both report **26.6.95** (`20260911-210447`); `reference/toolchain.md` pins **26.6.90**. App Market says `UP_TO_DATE`, so the pin is stale, not the server.

---

## (a) Task 0 — data reconciliation, from live queries

A real run (`DEMO`) was loaded through the console's own process model, measured, and reset. Read from rows, not from `packet-spec.md`.

### 1. Desk mix of the 15 packet trades

| desk | count | sequences |
|---|---|---|
| **EQ_FLOW** | **8** | 01, 02, 03, 04, 08, 11, 13, 15 |
| FI_TRADING | 3 | 05, 09, 14 |
| FX_DESK | 2 | 06, 10 |
| ETF_MM | 1 | 07 |
| CREDIT | 1 | 12 |

All three stories are EQ_FLOW. Of the background twelve, **5 are EQ_FLOW**; 7 sit on other desks. An EQ_FLOW analyst sees **8 of the 15** — and the built screen was later confirmed to say exactly that as the persona: *"8 trades on your desk"*.

### 2. The standing fixture book as an EQ_FLOW analyst sees it

**13 of the 17 fixture cases are EQ_FLOW**; the other four are one each on FI_TRADING, FX_DESK, ETF_MM, CREDIT.

| stored status | displayed | EQ_FLOW |
|---|---|---|
| New | New | 4 |
| Agent Triage | In triage | 0 |
| Pending Analyst | Awaiting review | 2 |
| In Remediation | In remediation | 2 |
| Escalated | Escalated | 2 |
| Resolved - Straight Through | Resolved · straight through | 1 |
| Resolved - Analyst | Resolved · analyst | 2 |

**Open: 10** — 8 needing the analyst, 2 escalated. Confirmed as the persona: the screen reads `Predicted fails — open 10 / 8 need action · 2 escalated`.

**Standing escalations exist**, so that queue is never empty: **SO-39** (`funding_gap`, past cutoff) and **SO-40** (`counterparty_default`, score 0.86 — the high-score-escalated-anyway case the lane rule was bought with).

### 3. What "cleared this batch" can query

- **12 of 15 predictions sit below the High floor** (Low/Medium, p 0.10–0.45) — the twelve background trades. EQ_FLOW subset **5**.
- Fields for the Disposition column: `riskTier`, `failProbability`, `scoredAt`; side, quantity, notional, currency; ticker and counterparty through the relationships.
- **The batch stamp is real and single-valued:** all 15 predictions of a run carry **one identical `SCORED_AT`**, because `SIMULATE_FEED` writes it explicitly at call time.
- The straight-through case: status `Resolved - Straight Through`, disposition **`Settled - Corrected`**, `resolvedOn` populated.
- **MEASURED AND CONSEQUENTIAL: process-written cases come back with `createdOn` NULL and `modifiedOn` NULL.** All demo cases; all fixture resolved cases have both. This drove the console's load timestamp and is the root of the supervisor defect in (f).

**Nothing rendered empty or absurd on the real mix.** No desks retagged, packet unaltered.

---

## (b) Objects changed, with readback

### `SO_analystWatchlist` — `_a-0001f054-7a62-8000-9c49-011c48011c48_562262`, **v16 → v18**
Both `updateInterface` readbacks **byte-identical** to the local `.work` source (compared, not eyeballed). `validateDesignObject` → `hasErrors: false`. `testInterface` → `error: null` in both data states.

KPI strip stays four book-level cards (card 4 now batch-scoped); a **Latest scoring batch band** sits between the KPIs and the queues; **three stacked queues** replace the single grid — NEEDS YOUR ACTION (selectable, feeds the rail, paged footer), ESCALATED — WITH SUPERVISOR (muted, not selectable), CLEARED THIS BATCH (collapsible section, initially collapsed, not selectable). Preview rail unchanged in structure and contract.

### `SO_demoAdminConsole` — `_a-0000f057-1da8-8000-9c4b-011c48011c48_564828`, **v9 → v11**
One **explainer box** at the top of the Run card carrying Scott's copy verbatim; **both captions deleted**; status line `Demo loaded 23 Sep 10:33 · 15 trades · 3 cases`; **amber stale-date line** added and rendered.

---

## (c) The query definitions, stated plainly

**"Open" — one definition; the KPI cannot drift from the queues because it is not computed separately.** `local!caseRows` queries SO Settlement Case with `status in {New, Agent Triage, Pending Analyst, In Remediation, Escalated}`. The KPI counts the rows assembled from it; the two case queues **partition** that same set on one boolean:

- NEEDS YOUR ACTION = `status <> "Escalated"`
- ESCALATED = `status = "Escalated"`

No second status list exists in the interface. Verified at both scopes: full-scope **16 = 12 + 4** loaded and **14 = 11 + 3** clean; **as `alex.analyst`, 12 = 9 + 3 loaded and 10 = 8 + 2 clean.**

**The batch.** `local!batchTrades` queries **SO Trade** — not SO Trade Predictions — filtered `tradeId starts with "TRD9"`, pulling the 1:1 prediction through the relationship. Anchoring on SO Trade is the whole point: record-level security is defined there, so the band and cleared queue are desk-scoped **by construction**. Proven by the persona render — the same band that reads *15 trades* to a supervisor reads ***8 trades on your desk*** to `alex.analyst`. `"starts with TRD9"` is the same predicate the console uses, so console and watchlist cannot disagree about what is loaded.

**The batch timestamp.** Batch rows sorted by `scoredSortKey` descending; row 1's `scoredAt`. **Not `max()`** — `min()`/`max()` over Dates return a Decimal.

**The three queue populations.**
1. **NEEDS YOUR ACTION** — open, not escalated, sorted by `cutoffSortKey` ascending (null cutoff pinned to 99999 so it sorts last). Default shows the **4 nearest**; the footer toggles to all and back.
2. **ESCALATED — WITH SUPERVISOR** — open, `status = "Escalated"`, same sort.
3. **CLEARED THIS BATCH** — batch trades classified into exactly one bucket each: `SCORED_CLEAR`, `AGENT`, `ANALYST`, `ESCALATED`, `NEEDS`, `UNCASED`. The queue shows the first three. **Because every trade lands in exactly one bucket the chips always sum to the trade count** — verified 12+1+1+1 = 15 full-scope and **5+1+1+1 = 8 as the persona**.

**"Straight-through today"** = `SCORED_CLEAR + AGENT` for the batch. An analyst-resolved case is deliberately excluded: it had analyst touch.

---

## (d) The no-run band behaviour, and why

**The band hides when no packet is loaded. So does the CLEARED THIS BATCH card. The straight-through KPI renders `—` with "no scoring batch on your desk".** One local, `local!hasBatch`, governs all three, so they cannot disagree.

Every value in the band is a fact **about a batch** — a stamp, a trade count, four dispositions — so with none loaded each is zero or blank under a heading that is no longer true. The alternative the brief allowed ("collapse to whatever the latest scoring state truthfully is") would mean naming the newest `scoredAt` across the 50,000 baseline predictions: real, but not a batch. The KPI says `—` rather than falling back to the standing book's resolved count, because two meanings under one label is what the display canon exists to prevent.

Verified in both states and at both scopes.

---

## Persona verification (2026-09-24) — the part that could not be done before

Both sessions live: `alex.analyst` and `sam.supervisor`, each in its own data directory, checked read-only against `settlement-ops`.

**Two standing browser checks closed from the terminal, no browser needed:**
- **The page gate holds.** `alex.analyst` sees **2 pages** (Watchlist, Cases); `sam.supervisor` sees **3** (Watchlist, Cases, **Supervisor**). The Supervisor tab is not merely hidden from the analyst — it is not in their page list at all.
- **The supervisor source line** reads exactly `house view across 5 desks · 17 cases in scope`.

**As `alex.analyst`, no demo loaded:** open `10` / `8 need action · 2 escalated`; NEEDS YOUR ACTION (8) showing 4 with `showing 4 nearest cutoffs   View all 8`; ESCALATED (2); **batch band absent, CLEARED card absent**, straight-through `—  no scoring batch on your desk`. No errors.

**Behaviour, actually driven rather than inspected:**
- **The view-all toggle works.** Clicking `View all 8` took the grid from `showing 1-4 of 4` to `showing 1-8 of 8` and flipped the footer to `showing all 8 / Show nearest 4`. So the KPI's 10 equals the 8 + 2 rows genuinely reachable through the queues — exercised, not asserted.
- **`selectable: false` is positively confirmed.** sail marks the escalated and cleared grids `[READONLY]` and lists **no row handles** for them, while the needs-action grid exposes a checkbox handle per row. Configuration alone could not show this.
- **The rail binds as the persona.** Selecting `TRD026800` produced the full rail — Engie SA, 11.8M EUR, 79% Critical, *"Does not fit the window — confirmation takes 10.2h against only 2.6h remaining"*, score 68 against the 80 gate, the gate bar, `SO Triage Agent · 08:30` attribution, the assessment, and an `Assign` affordance.

**As `alex.analyst`, demo loaded** — every check the brief asked for, at the scope the demo actually runs at:

| check | observed |
|---|---|
| open = needs + escalated | `12` / `9 need action · 3 escalated` |
| batch band, desk-scoped | `Latest scoring batch  09:57 today  ·  8 trades on your desk` |
| four chips sum to the trade count | `5 cleared by Snowflake   1 agent-resolved   1 needs review   1 escalated` = **8** |
| straight-through KPI | `6` · `6 of 8 in latest batch · no analyst touch` |
| hero with batch tag | row handle `☐ TRD9DEMO01  09:57` |
| story 02 breach arithmetic | `Window breached  confirm lag 26.0h · 2.4h to cutoff` |
| cleared section collapsed | `[Show the 6 cleared trades]` |
| honest split | `5 cleared by Snowflake scoring · 1 resolved by the agent · 6 of 8 without analyst touch` |
| two distinct verbs | `Agent resolved · score 88  Settled - Corrected` vs `Cleared by Snowflake scoring  no case needed` |
| scored-clear rows carry no case link | only `TRD9DEMO03` has a `⤴` |

**The Act 1 beat, end to end as the persona:** selecting the hero opened the rail on SAP GY — BUY 210,000 shares, 18.7M EUR, 83% Critical, *"Fits the window — confirmation takes 1.2h against 3.0h remaining, completing about 1.9h before cutoff"*, `Auto-release score 62, releases at 80`, the gate bar, `SO Triage Agent · 09:58`, the assessment naming the case and instrument, then `Assign` and `Open case →`.

*Note:* the agent scored **0.88** on this run against 0.90 yesterday. Non-deterministic, both comfortably above the 0.80 gate, both straight-through. Worth knowing on stage; not a defect.

---

## (e) Scott's browser script

The terminal now covers content, state and behaviour as both personas, so the browser script is **geometry and paint only** — the things sail provably cannot see.

1. **Console** (`settlement-ops-admin` → Admin): does the **explainer box** read before the buttons, and does the grey panel separate it enough from the status line?
2. **Load the demo**, wait ~90 seconds, refresh: is the status line's timestamp legible, and does the layout hold when the amber line is absent?
3. **Watchlist as `alex.analyst`**:
   - Do the three queues read top-down as **urgent → muted → quiet**?
   - Is the **batch tag** legible without shouting at 1440px?
   - Does the **cleared summary line fit one line** at laptop width, or wrap?
   - Does the **view-all footer** sit as a footer rather than floating?
   - Do the two-line grid cells (Agent, Cutoff, Fail risk, Status, Disposition) sit level, or does one column's second line push its row taller?
   - **The fold:** the hero is the 4th and last visible row. Does it read as "on the list" or as "nearly cut off"? This is the ruling in (f).
4. **Amber stale-date line**: load a demo, leave it overnight, open the console next morning. Does it read as a state rather than an error?
5. **Reset** and confirm the page settles back without layout shift.

---

## Verified, and how

| what | how | result |
|---|---|---|
| Watchlist, both data states | `testInterface` (full scope) **and sail as `alex.analyst`** | `error: null`; partition holds at both scopes; band/cleared present loaded, absent clean |
| Chips sum to trade count | render text + persona render | 12+1+1+1 = 15 · **5+1+1+1 = 8** |
| Two verbs distinct | persona render | one `Agent resolved · score 88`; five `Cleared by Snowflake scoring` |
| Escalation sub-lines | persona render | `Window breached · confirm lag 26.0h · 2.4h to cutoff`; `Window breached · confirm lag 3.0h · past cutoff` (negative hours handled); `Reason override · counterparty default — credit decision required` |
| View-all toggle | **clicked as the persona** | 4 → 8 rows, footer flipped both ways |
| Non-selectable queues | **sail `[READONLY]` + absent row handles** | confirmed on escalated and cleared |
| Rail binding | **clicked as the persona**, twice | full rail on a standing case and on the hero |
| Page gate | `sail pages` per persona | analyst 2, supervisor 3 |
| Console, both states | `testInterface` | explainer present, captions gone, timestamp in status line, Reset `disabled` true/false correctly |
| Console amber line | throwaway copy with the comparison inverted, rendered, deleted | `Loaded before today. Reset, then Load for fresh dates.` at `#96590A`, SMALL, STRONG |
| Console word budget | counted from rendered strings | **exactly 60 words**, longest sentence 11 |
| Supervisor regression | `testInterface` **and sail as `sam.supervisor`**, loaded then reset | **fails loaded, passes clean — at both scopes** |
| Cleanup | `listInterfaces` query `SO_zz` | `total: 0` |
| Environment restored | console readback | 0 demo trades · 0 demo cases · 17 built-in · 12 comments · 14 audit rows |

## Not verified, and why

- **All geometry and paint.** sail carries style values and requested widths, never pixels — no wrapping, truncation, alignment or card heights. That is the whole of the browser script above.
- **The cleared section's collapse was not clicked.** sail shows it collapsed (`[Show the 6 cleared trades]`) and lists its rows, so the state and contents are verified; the expand interaction itself is not.
- **The console buttons were not pressed from the console.** Load and Reset were exercised through their process models; `a!startProcess` cannot be invoked from `testInterface`, and neither persona is in SO Demo Admins.

---

## (f) Flagged — two rulings and one blocker

### 🔴 BLOCKING — `SO_supervisorCommand` breaks whenever a demo is loaded

**Not caused by this session's changes, and deliberately not fixed** (the brief says supervisor screens stay untouched).

Measured with a control, at **both** scopes:

| state | design account (`testInterface`) | **`sam.supervisor` via sail** |
|---|---|---|
| demo loaded | `at function 'text' [line 351]: A null parameter has been passed as parameter 1` | **HTTP 500 — "Error Evaluating UI Expression". The page will not open.** |
| after reset | `error: null` | loads cleanly, full house view |

One variable changed. `local!cycleList` on **line 345** guards the null:

```
if(a!isNullOrEmpty(index(fv!item, "modifiedOn", null)), "", text(index(fv!item, "modifiedOn", null), "yyyy-mm-dd"))
```

`local!cIdx` on **line 351** does not:

```
local!cIdx: wherecontains(true, a!forEach(items: local!resolved,
  expression: text(index(fv!item, "modifiedOn", null), "yyyy-mm-dd") = local!c)),
```

A process-written case has a NULL `modifiedOn` (measured: all demo cases NULL, all fixture resolved cases populated). **Every demo run produces exactly one straight-through resolution by design**, so the supervisor screen is unreachable from the moment the agent resolves story 03 until Reset — precisely the window Act 2 would open it in. The persona check makes this concrete: a supervisor clicking their own tab mid-demo gets an error page, not a degraded one.

**The fix is one line** — give line 351 the guard line 345 already has. **Ruling wanted; it blocks Part C.**

### 🟠 The hero lands on the fold of NEEDS YOUR ACTION

Built to the mockup's four nearest cutoffs. **Confirmed at persona scope:** with a demo loaded, `alex.analyst` sees 9 needing action and the hero `TRD9DEMO01` is the **4th and last visible row**, because three standing fixtures have nearer cutoffs. One more nearby fixture pushes the Act 1 beat below the fold. **Ruling:** raise `local!nearest` from 4 to 6, or move a fixture cutoff. One-token edit either way.

### 🟡 The console is exactly at its word budget

CLAUDE.md says "under 60 words of visible prose on the healthy default view". The explainer costs 39 words where the two captions cost 17, and the measured view is now **exactly 60** — at the line, not under it. The copy is yours and verbatim, so the budget is what gave; recorded in the object header so the next edit knows there is no headroom. Longest sentence 11 words, inside the 15-word rule.

### Deliberate departures from the mockup, logged as structural deltas
- **The filter row is gone** (priority / fail reason / search). v5 has none, and with the list partitioned by urgency and sorted by cutoff, search earned less than it cost. Reversible in one edit.
- **Scores render on the 0–100 scale**, not the mockup's `0.62` / `0.90` — the display canon is explicit that "confidence" is governance vocabulary. So `Held · 62`, `Agent resolved · score 88`.
- **The Escalation column names the condition, not an actor** — `Window breached` / `Reason override` / `Agent escalated` where the mockup says "By policy". The screen cannot read which mechanism fired (that text lives in the audit trail, one query per row), and a case the agent escalated whose window has since closed would be mis-attributed.
- **The Agent column's sub-line carries the full canon remediation** where the mockup abbreviates; there is no short-remediation vocabulary and inventing one inline is the casing-trick failure the display rule forbids.
- **Two extra chips exist but are invisible unless non-zero** — `analyst-resolved` and `awaiting intake`. Without the first the chips stop summing the moment you resolve the hero on stage; the second is a truthful signal during the ~60s between Load and the cases appearing.
- **The page head cannot say "Equity Flow desk"** as the mockup does — that is record-level security, and restating it on the screen would be a second, driftable copy.
- **Cleared rows are not selectable**; most have no case for the rail to preview, and the one that does carries a record link instead.

### Carried forward
- Version pins in `reference/toolchain.md` are one release behind the running server.

---

## Promotion candidates: 2 found; 1 promoted, 1 staged

- **PROMOTED to CLAUDE.md** (project rule, fails the noun test on purpose): process-written `SO Settlement Case` rows come back with `createdOn` and `modifiedOn` NULL while script-written fixture rows have both. Any screen formatting either field must guard the null; anything needing a "when" for a process-created row reads a field the process actually wrote.
- **STAGED, gate 1:** *a fixture set and a process-written set can differ in which system-managed fields are populated, so a screen verified against fixtures is not verified against production rows.* **Trigger: the next build with both hand-authored fixtures and process-created rows in one table.**
- **Second observation, same direction:** unused locals block a save (`HTTP 400 — Unused Local Variables … local!actionStatuses`). Still staged pending a deliberate re-test rather than a third accident.
- Unchanged: the agent-boolean method note; Dev MCP process-instance blindness; NTZ-as-UTC; chart-type.

*Promotion checkpoint: current through this entry.*
