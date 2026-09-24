# Closeout — 2026-09-24 — Supervisor null-guard class sweep, and the watchlist fold at six

*Scope and identity:* Dev MCP as `scott.thorn` (SO Supervisors — full scope) for design work and the load/reset; **sail as `alex.analyst` and `sam.supervisor`** for every persona observation, each from its own data directory. No `appian_*` tools, no `ping`. Two objects changed: `SO_supervisorCommand` (v6 → v7), `SO_analystWatchlist` (v18 → v19). Console untouched, as instructed. One throwaway created and deleted.

*Gate:* environment verified at the clean baseline before starting — `Ready · 50,000/50,000 · 9/9 connections · agent OK`, 0 demo trades, 0 demo cases, 17 built-in, 12 comments, 14 audit rows. The P4-VERIFY re-date ritual had run 13 minutes earlier in the same session, so fixture offsets were live; not re-run.

---

## (a) The line-351 fix, and where null-dated cases now land

**The guard.** `local!cIdx` now computes its grouping key with the same null guard `local!cycleList` already used. The two are the same key computed twice, so they must be symmetric; they were not, and the asymmetry took the whole page down the moment a demo run resolved anything straight through.

**But the guard alone would have replaced a crash with a lie, so the grouping was fixed too.** Left as-is, a dateless case became a second cycle keyed `""` — enough to flip `haveTrend` true and draw the line chart. I rendered that counterfactual rather than arguing it (throwaway copy, guard kept, filter removed):

```
categories: [null, "2026-09-24"]
series:     [100,  33]
```

A line chart with a **`null` x-axis label**, plotting a fabricated fall from 100% to 33% — on the card whose own comment says drawing a line through one point "implies a direction the data cannot support". On stage that reads as "our straight-through rate collapsed". So `local!cycles` now drops the empty bucket.

**Where a null-dated resolved case lands: in every figure except the trend axis.**

Measured with the demo loaded, as `sam.supervisor`:

| figure | fixture book only | with the demo's straight-through case |
|---|---|---|
| cases in scope | 17 | **20** |
| Straight-through today | 33 % · 1 of 3 | **50 % · 2 of 4** |
| Penalties avoided | 3 fails prevented | **4 fails prevented** |
| EQ_FLOW desk STP column | 33% | **50%** |
| STRAIGHT-THROUGH RATE BY CYCLE | 1 cycle on record | **1 cycle on record** |

**Why that is sensible.** `local!resolved` feeds `resolvedCount`, `stCount`, `stPct`, `avoidedUsd` and the per-desk STP column — none of which needs a date — and the case is counted in all of them. The by-cycle trend is the single place where a date *is* the axis, and a case with no usable date cannot be placed on it. Excluding it there costs nothing anywhere else and prevents the chart asserting a movement that did not happen. It is also self-correcting: the moment the field question below is ruled, these cases join the axis rather than being dropped.

**The standing question, deliberately not answered here.** This groups by `modifiedOn` as a proxy for "the day it resolved", while **`resolvedOn` is the real field and IS populated on exactly these rows** (measured: process-written cases have `resolvedOn` set and `createdOn`/`modifiedOn` NULL). Swapping the field would *place* these cases instead of excluding them. Not done: that is a change of meaning, not a null guard, and the brief scoped this to guards. **In TODO for a ruling.**

---

## (b) The sweep — method first, so absence means something

**Inventory.** `listInterfaces` and `listExpressionRules` scoped to the application UUID returned **15 interfaces and 19 expression rules**; all 34 were fetched to `.work/` and the file count verified at 34. Nothing was excluded on the grounds that it "obviously" could not touch a case timestamp — that judgement is what the sweep exists to replace.

**What was searched, and why two patterns rather than one:**

1. **The field UUIDs** — `{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn` and `{4ac3036c-ab51-4940-a5d5-363e4f2a8a09}modifiedOn`. Catches UUID-qualified record reads.
2. **The bare identifiers** `createdOn` / `modifiedOn`. Catches **map-key reads on assembled rows** — `index(fv!item, "modifiedOn", null)`.

**The second pattern is the one that mattered: the actual defect at line 351 is a map-key read, and a UUID-only sweep would have missed it entirely.** Any future sweep of this class must search both forms.

**Hits — all nine in `SO_supervisorCommand`, none anywhere else.**

| line | site | classification | action |
|---|---|---|---|
| 74, 75 | both fields in the query `fields:` list | not a read | none |
| 140, 141 | stored into the row map with a `null` default | not a format/compare | none |
| 142 | `ageHrs` arithmetic on `createdOn` | **already guarded** | none |
| 190–191 | escalation-age arithmetic on `modifiedOn` | **already guarded** | none |
| 345 | `cycleList` — `text(modifiedOn)` | **already guarded** | none |
| **351** | `cIdx` — `text(modifiedOn)` | **UNGUARDED** | **fixed** |
| 377–378 | `waitHrs` arithmetic on `modifiedOn` | **already guarded** | none |

**Zero hits across the other 14 interfaces and all 19 expression rules.** The watchlist, case detail, console and every display rule read neither field. That is the meaningful shape of this result: the defect was not a systemic blind spot but **one miss out of six sites in a single file that otherwise handled the field correctly every time** — the author knew it was nullable.

**Adjacent, same defect class, different record types — checked, reported, not fixed (both safe):**
- **`SO Case Comment.createdOn`** — read in `SO_caseDetail` (125, 127, 131) and `SO_analystWatchlist` (624, 628, 1350), all feeding `assessmentAt` to the rail. Guarded at the row level (`if(a!isNullOrEmpty(local!assessment), null, …)`), and the field is explicitly stamped by the write path (CLAUDE.md), **observed populated on a process-written comment** — the rail rendered `SO Triage Agent · 09:58` for a demo case this session.
- **`SO Settlement Case Event History.timestamp`** — read in the console's AI-agent line, guarded by `agentOk`, **observed rendering** `last run 24 Sep 08:30` for a demo-created event.

Neither is at risk, and neither was touched.

---

## (c) The hero at six

`local!nearest` 4 → 6. **The footer copy already derived from that local**, so `"showing 6 nearest cutoffs"` and `"Show nearest 6"` followed with no separate edit — the number and the words it prints cannot drift apart.

As `alex.analyst`, demo loaded, NEEDS YOUR ACTION (9), showing 1–6 of 6:

| # | trade | |
|---|---|---|
| 1 | TRD030639 | 0h 41m |
| 2 | TRD023894 | 1h 56m |
| 3 | TRD026800 | |
| **4** | **TRD9DEMO01  10:15** | **the hero** |
| 5 | TRD046440 | |
| 6 | TRD021300 | |

Footer: `showing 6 nearest cutoffs     View all 9`.

**The hero is 4th of 9 by cutoff — its true position in the data — and now 4th of 6 visible, with two rows of headroom below it.** Previously it was the last visible row. The data did not move; the fold did.

---

## (d) Verification

| # | check | result |
|---|---|---|
| 1 | Load a real DEMO run through the console's process path, wait for triage | `OK run=DEMO trades=15 predictions=15 high_or_critical=3`. Triage settled between t+15s and t+30s. **Incidental confirmation:** mid-flight the band truthfully read `5 cleared by Snowflake · 0 agent-resolved · 3 need review · 0 escalated` — still summing to 8 — then settled to `5 / 1 / 1 / 1`. |
| 2 | **`sam.supervisor` via sail, demo loaded** — the check that was impossible before the fix | **Page opens.** House view renders: 20 cases in scope, 16 open, 698.4M USD eq., 4 escalations, STP **50% (2 of 4)**, 4 fails prevented, desk grid, runway chart. Trend card: **1 cycle on record**, no phantom chart. |
| 3 | `alex.analyst` via sail — six rows, hero position | NEEDS YOUR ACTION (9), showing 1–6 of 6, hero 4th with two rows below, footer `showing 6 nearest cutoffs / View all 9`. |
| 4 | `testInterface` on every object touched, both data states | `SO_supervisorCommand` clean `error: null` (1 cycle, 33% of 3) and loaded `error: null` (cycle chart **not rendered** — trend card in its text state). `SO_analystWatchlist` clean `error: null` (`showing 6 nearest cutoffs / View all 11`) and loaded `error: null` (band present, `13 of 15 without analyst touch`). `validateDesignObject` clean on both. Both `updateInterface` readbacks **byte-identical** to the local `.work` source. |
| 5 | Reset through the console path; both screens clean; baseline restored by readback | `OK run=DEMO trades_deleted=15 predictions_deleted=15`. `sam.supervisor`: 17 cases in scope, 33% (1 of 3), 1 cycle on record. `alex.analyst`: open 10 = 8 + 2, band absent, cleared absent, `showing 6 nearest cutoffs / View all 8`. Console readback: **0 demo trades · 0 demo cases · 17 built-in · 12 comments · 14 audit rows**, `No demo data loaded.`, Reset `disabled: true`. |

**Cleanup:** `SO_zzCycleProbe` created for the counterfactual and deleted in the same session (`Deleted successfully`).

**Not verified:** all geometry and paint — the render tree and sail both carry style values and requested widths, never pixels. Specifically unverified: whether six rows changes the queue's visual balance against the escalated and cleared cards beneath it, and whether the taller needs-action card pushes the cleared summary below the fold at laptop height. Both are in the browser checklist.

---

## (e) Stopped on, and flagged

**Nothing was stopped on.** Three things flagged:

1. **RULING WANTED — `modifiedOn` vs `resolvedOn` in the cycle trend.** The chart's own comment says "grouped by the DAY they resolved", and `resolvedOn` is that field and is populated on the rows currently being excluded. One-line change, but it changes what the axis means, so it is yours. Until then, dateless cases are counted everywhere and plotted nowhere — honest, if slightly lossy.
2. **Edge, unreachable today:** if *every* resolved case were dateless, `cycles` would be empty and the card would read "0 cycle on record" (singular, and slightly odd) while `resolvedCount > 0`. Not reachable while the P4-VERIFY fixtures exist, since they always contribute a dated cycle, and the console refuses to delete them. Left alone under "nothing else changes".
3. **The counterfactual is worth keeping in mind as a pattern**, not just this bug: the minimal fix to a null-crash produced a *plausible* chart rather than an obviously broken one. A guard that stops an exception is not the same as a guard that makes the data honest, and the second is the one that matters on stage.

---

## Browser checklist (geometry only)

- Does NEEDS YOUR ACTION at six rows still read as a short, urgent list rather than a flat queue?
- Does the taller needs-action card push ESCALATED and CLEARED below the fold at 1440×900? If so, is that acceptable given the hero is now comfortably visible?
- On the supervisor screen with a demo loaded, does the trend card's text state sit cleanly where the chart would be, without a collapsed gap?

---

## Promotion candidates: 1 found; 0 promoted, 1 staged

- **STAGED, gate 1 — method, not platform:** *when fixing a null-formatting crash, check what the guarded value does to any grouping, aggregation or axis it feeds; the minimal guard can convert a crash into a plausible wrong answer, which is worse.* Measured here: guard-only rendered a line chart with a `null` category plotting a fabricated 100% → 33% movement. **Trigger: the next null guard added to a value that feeds a chart, a group-by or a count.**
- Unchanged from 2026-09-23: the promoted CLAUDE.md rule on NULL `createdOn`/`modifiedOn` on process-written rows (this session is its first application and it held — it is what made the sweep targeted rather than exploratory); the fixture-vs-process-rows staged candidate; unused-locals-block-saves; the agent-boolean method note; Dev MCP process-instance blindness; NTZ-as-UTC; chart-type.

*Promotion checkpoint: current through this entry.*
