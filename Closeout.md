# Closeout — 2026-09-24 — Phase 5 Part C: cycle-axis ruling, then the full dress rehearsal

*Scope and identity:* Dev MCP as `scott.thorn` (SO Supervisors — full scope) for Task 0 and the process-path load/reset; **sail as `alex.analyst` and `sam.supervisor`** for every persona observation, each from its own data directory. No `appian_*`, no `ping`. **One object changed, in Task 0 only:** `SO_supervisorCommand` v7 → v8. Nothing changed after the rehearsal began. Two throwaways created and deleted.

*Gate:* environment verified at clean baseline before starting. The P4-VERIFY re-date ritual ran earlier in the same session (13:56 UTC), 13 minutes before Task 0 — fixture offsets live, not re-run.

---

## (a) Task 0 — cycle trend axis, ruled and swapped

**1. Every resolved case carries `resolvedOn`. No stop.** Read from `listRecordData` across all 17 fixtures:

| case | status | `resolvedOn` |
|---|---|---|
| SO-41 | Resolved - Analyst | `2026-09-24 12:45:00` |
| SO-42 | Resolved - Analyst | `2026-09-24 12:45:00` |
| SO-50 | Resolved - Straight Through | `2026-09-24 12:45:00` |

No fixture row lacks it, so nothing was backfilled.

**2. Swapped.** `resolvedOn` added to the supervisor's row map (it was already in the query's `fields:` list but never carried), then **both** grouping reads — `cycleList` and `cIdx` — moved from `modifiedOn` to `resolvedOn` **together**, guards kept. They are the same key computed twice; splitting them is how the original defect happened, and the comment now says so.

**3. Verified, and the claim is measured rather than asserted.** The rendered card cannot distinguish the two groupings — it says "1 cycle on record" either way, and its rate text is global, not cycle-scoped. So a throwaway computed both keys over the same live resolved set:

| case | status | old key (`modifiedOn`) | new key (`resolvedOn`) |
|---|---|---|---|
| SO-41 | Resolved - Analyst | `2026-09-24` | `2026-09-24` |
| SO-42 | Resolved - Analyst | `2026-09-24` | `2026-09-24` |
| SO-50 | Resolved - Straight Through | `2026-09-24` | `2026-09-24` |
| **SO-83** | **Resolved - Straight Through** *(demo)* | **`''` → dropped** | **`2026-09-24` → on the axis** |

`OLD: cycles=1 n-in-today=3 dropped=1` → `NEW: cycles=1 n-in-today=4 dropped=0`.

**What the trend card renders.** Clean: `1 cycle on record · Today's rate is 33% (1 of 3)`. Loaded: `1 cycle on record · Today's rate is 50% (2 of 4)`. Still one cycle because fixtures and demo resolve on the same calendar day — but the demo case is now *inside* it rather than excluded. `testInterface` `error: null` both states; `validateDesignObject` clean; readback byte-identical.

**The swap also serves the analyst lane**, which the ruling did not explicitly anticipate: after the rehearsal's analyst disposition the card read `1 cycle on record · Today's rate is 40% (2 of 5)` — the analyst-resolved case joined the cycle too, because `resolvedOn` is written by the disposition path as well.

---

## (b) Timing table — press to settled

Load pressed **14:42:13 UTC**. Poller sampling the analyst watchlist every ~7s.

| event | time | Δ press |
|---|---|---|
| Load pressed | 14:42:13 | — |
| Snowflake responded `OK run=DEMO trades=15 predictions=15 high_or_critical=3` | 14:42:22 | **+9s** (8,807 ms measured) |
| Batch band up; 5 scored-clear trades visible; `3 awaiting intake` | 14:42:27 | +14s |
| **Case 1 `TRD9DEMO01`** (hero) appears | 14:42:34 | **+21s** |
| **Case 2 `TRD9DEMO02`** appears | 14:42:49 | **+36s** |
| **Case 3 `TRD9DEMO03`** appears; `awaiting intake` clears | 14:42:57 | **+44s** |
| Triage lands case 2 → `1 escalated` | 14:43:33 | **+80s** |
| Triage lands case 3 → `1 agent-resolved`; **settled** | 14:43:41 | **+88s** |

**Press to settled: 88 seconds.** The console's explainer says "About 2 minutes" — accurate, slightly conservative.

**Instrument limitation, stated:** the band's chip vocabulary groups `New` with `Pending Analyst` under "needs review", so the hero's *triage-completion* instant is not separable from its *creation* instant by this poll. The case detail's activity log gives it independently: Case Created 10:42, Agent Triage Complete 10:43.

Other timings: second Load 8,238 ms · Reset 7,686 ms · load→reset full cycle about 6½ minutes including observation.

---

## (c) Per-step observations

### Step 1 — Baseline
`Ready · data 50,000/50,000 · 9/9 connections · agent OK` · Demo trades **0** · Demo cases **0** · Built-in test cases **17** · Case comments **12** · Audit rows **14** · AI agent `last run 24 Sep 08:30` · `Status: No demo data loaded.` · Reset `disabled: true`.

### Step 3 — Mid-flight (14:42:33, t+20s), chips verbatim
```
5 cleared by Snowflake   0 agent-resolved   1 needs review   0 escalated   2 awaiting intake
```
5+0+1+0+2 = **8** — the chips sum *during* intake, and the conditional `awaiting intake` chip does exactly the job it was added for. Band already reading `Latest scoring batch  10:42 today  ·  8 trades on your desk`; open 11 = 9 + 2.

### Step 4 — Settled, `alex.analyst`
`Predicted fails — open 12 / 9 need action · 3 escalated` · `Value at risk 289.2M USD eq.` · `Inside critical window 5 / cutoff within 4h · 98.6M USD eq.` · `Straight-through today 6 / 6 of 8 in latest batch · no analyst touch` · band `Latest scoring batch 10:42 today · 8 trades on your desk` · chips `5 cleared by Snowflake  1 agent-resolved  1 needs review  1 escalated` (= 8) · `NEEDS YOUR ACTION (9)` showing 1–6 with `showing 6 nearest cutoffs   View all 9` · `ESCALATED — WITH SUPERVISOR (3)` · `CLEARED THIS BATCH (6)` with `5 cleared by Snowflake scoring · 1 resolved by the agent · 6 of 8 without analyst touch`.

**Hero position: 4th of 6 visible**, two rows of headroom — the fold ruling holding on live data.

**Hero case detail** (`TRD9DEMO01`, case SO-84), as rendered to the persona:
- Header `B  SAP SE · BUY 210,000 shares · 18.7M EUR`
- `Fail probability 83% / Critical tier` · `Predicted reason Insufficient securities / deliver-side shortfall` · `Cutoff 3h 02m · 13:47` · `Value at stake 18.7M EUR / 210,000 shares`
- **`Auto-release: Held for review — score 65 · releases at 80`**
- Trade: trade date Wed 23 Sep, settles Thu 24 Sep T+1, desk EQ_FLOW, **broker confirmation lag 1h 08m**
- Settlement: ISIN `DE0007164600`, Clearstream (CBF), **Matched Yes**, Equity
- Counterparty: Diamond Trust · APAC · High · **12-mo fail rate 19.9%** · ops contact rendered
- Exposure: penalty accrual **~1.9K EUR/day**, five-day **~9.4K EUR excl. funding**, **onward deliveries None next 2 cycles — contained**
- Activity: `Case Created 24 Sep 10:42` → `Agent Triage Complete 24 Sep 10:43` ×2
- Agent narrative (verbatim, abridged): *"…broker confirmation lag is 1.15h, leaving an adequate but not generous window. The trade is matched and carries no onward delivery risk, but counterparty Diamond Trust is rated HIGH risk tier with a historical fail rate of 19.89% — more than double the 9.2% dataset average and well above the 13.8% materiality threshold — two compounding concerns that meaningfully reduce remediation confidence."*
- `Proposed remediation: Arrange cover borrow / partial release` · `Urgency HIGH`

**Newly established:** the record header's related actions **do render to sail** — `Record Disposition · Assign · Escalate · Add Comment`, in the order Scott set in Designer. CLAUDE.md records the status→action mapping as "a browser check and only a browser check"; that is now out of date and the rule should be relaxed.

### Step 5 — Settled, `sam.supervisor`
`house view across 5 desks · 20 cases in scope` · `Predicted fails — open 16` · `Value at risk 698.4M USD eq.` · `Inside critical window 7 / 393.7M` · `Escalations awaiting action 4 / oldest waiting 7h 45m · SLA 1h` · **`Straight-through today 50% / 2 of 4 resolved · gate at 80`** · `Penalties avoided 3.0K USD eq./day · 4 fails prevented`.

Desk grid `EQ_FLOW, 12, 280.5M, 5 inside 4h, 3 esc, STP 50%` · house line `16 open · 698.4M USD eq. · 7 inside 4h · 4 escalated · 50% straight-through` · reason mix `Funding gap leads the open book at 9 of 16 — treasury timing is the constraint` · analyst queues `Unassigned 11 · Sam Supervisor 1 (FX_DESK) · Alex Analyst 4`.

**Escalation queue shows story 02 with its policy arithmetic**, beside the standing escalations:
```
SO-85  Confirmation lag exceeds window   26.1h lag · 2.5h to cutoff — cannot complete straight-through
SO-39  Confirmation lag exceeds window   3.0h lag · cutoff passed at 04:00 — fail management, not remediation
SO-43  Credit decision required          counterparty-default cases route to a human regardless of score
```

### Step 6 — Analyst action
`Record Disposition` on SO-84 → `Settled - Borrow Executed` (the disposition `SO_remediationForReason` maps to `insufficient_securities`), with a resolution note. Submitted 14:46:13, process 38894. Verified by fresh read, never by the submit output.

**What changed — this is the design's payoff and it held end to end:**

| | before | after |
|---|---|---|
| open | 12 (9 + 3) | **11 (8 + 3)** |
| NEEDS YOUR ACTION | 9 | **8** — hero left |
| CLEARED THIS BATCH | 6 | **7** — hero joined |
| band chips | `5 / 1 agent / 1 needs review / 1 esc` | **`5 / 1 agent / 1 analyst-resolved / 0 / 1`** — conditional 5th chip fired, still sums to 8 |
| cleared summary | `5 … · 1 by the agent · 6 of 8 without analyst touch` | **`5 … · 1 by the agent · 1 by an analyst · 6 of 8 without analyst touch`** |
| **Straight-through today** | 6 of 8 | **6 of 8 — unchanged** |
| supervisor open | 16 | **15** |
| supervisor STP | 50% (2 of 4) | **40% (2 of 5)** |
| penalties avoided | 3.0K / 4 prevented | **5.0K / 5 prevented** |

**The analyst-resolved case added a third verb, kept the chips summing, and did not inflate the no-analyst-touch figure** — which is exactly the honesty property the split was built for, now demonstrated on a live run rather than argued.

Three verbs side by side in the cleared queue:
```
TRD9DEMO01  SAP GY  18.7M EUR  83% Critical   Analyst resolved  Settled - Borrow Executed      10:46
TRD9DEMO03  IFX GY  634.8K EUR 72% High       Agent resolved · score 90  Settled - Corrected   10:43
TRD9DEMO04… ×5                                Cleared by Snowflake scoring  no case needed
```

### Step 7 — Edge observations
**Double Load: nothing duplicates.** Second press returned the identical `OK run=DEMO trades=15 predictions=15 high_or_critical=3` in 8,238 ms. Case set unchanged — still exactly SO-84/85/86, same statuses, same dispositions, same `resolvedOn`, no new ids, no re-triage.

**But it does move the batch stamp, and that is worth a talk-track line.** The band went `10:42 today` → **`10:47 today`** while every case and chip stayed identical. `SIMULATE_FEED` is idempotent by design, so it replaced the 15 trades and re-stamped `SCORED_AT`; the Appian cases were untouched. Both statements are true of the data, but after a double press the band says the batch scored at 10:47 while the case activity log says the case was created at 10:42 — a five-minute gap that never happened. **Not a defect. Do not press Load twice mid-demo.**

**Scope note, stated rather than claimed:** the logged risk is specifically "two Loads *within ~1 minute* can triage one case twice (both intakes find the same `New` case)". This press was ~4 minutes after the first with all three cases already created and two already resolved, so **that** race was not reproduced and is not closed by this observation.

**Delete-during-triage: skipped deliberately.** Its logged spec (TODO:58) records the behaviour as *unmeasured* and notes that cancelling orphaned processes is still open — it defines no safe way to observe it. Observing would mean resetting mid-triage and risking `ACTIVE` instances that cannot be cancelled over the Dev MCP (two are already parked from earlier sessions). Per the brief, stated and skipped rather than improvised.

### Step 8 — Reset
`OK run=DEMO trades_deleted=15 predictions_deleted=15`, `deletedCount: 3` (cases 84, 85, 86), 7,686 ms.

### Step 9 — Post-reset
`alex.analyst`: open `10 / 8 need action · 2 escalated` · band **absent** · CLEARED **absent** · `Straight-through today — / no scoring batch on your desk` · `showing 6 nearest cutoffs   View all 8`.
`sam.supervisor`: `17 cases in scope` · open 14 · `Straight-through today 33% / 1 of 3` · `Penalties avoided 2.9K / 3 fails prevented` · `1 cycle on record · 33% (1 of 3)`.
Console: **every step-1 value matches** — 50,000/50,000 · 0 demo trades · 0 demo cases · 17 built-in · 12 comments · 14 audit rows · `No demo data loaded.` · Reset `disabled: true`. Comments and audit returning to 12/14 re-proves the cascade removed the demo's assessments and events.

---

## (d) Defects and ambiguities

**1. STOPPED ON — "ZZ-CLICK" does not exist.** The brief's step 8 asks for "the ZZ-CLICK delete-click residual check per its spec". There is no such term anywhere in the repo — grepped across every `.md`, zero matches. The residual that *does* exist is **TODO.md:82, "Close the Reset delete-click residual"**, and its logged spec says the opposite of a session check: `a!deleteRecords` lives in a `saveInto`, **the click is handed to a human**, and the session's job is to *stage* a two-click verification. `reference/mcp-capability-boundaries.md:35` says the same. I did not improvise a substitute. **Ruling wanted: either point me at the intended ZZ-CLICK spec, or authorise staging the two-click verification (seed throwaway rows under a known tag) as its own task — it is a data write, which this rehearsal forbade.**

**2. STOPPED ON — the console's was/now line was not produced.** It is composed at button-click time from `local!resetBefore`; I drove `SO_resetRun` directly, because `a!startProcess` inside a `saveInto` cannot be invoked from a session. The equivalent evidence is recorded instead: before 3 cases / 15 trades / 15 predictions → after 0 / 0 / 0, with comments and audit back to 12 / 14. The line itself remains a human check, on the same footing as the delete click.

**3. DEFECT CAPTURED, not diagnosed — the counterparty recent-fails card renders blank instruments and zero values.** On the hero's case detail as `alex.analyst`:
```
Date, Trade, Instrument, Reason, Value
Sun 6 Jul, TRD040796, —, Operational error, 0
Thu 19 Jun, TRD022509, —, Insufficient securities, 0
+3 more
```
Instrument `—` and Value `0` on every row, while the card's own summary line correctly reads *"4 of 5 on insufficient securities — consistent with the predicted reason on this case"*. TODO already anticipates the likely mechanism — *"Expect some trade links to open as 'no access' for `alex.analyst` — SO Trade is desk-secured and a counterparty's recent fails span desks"* — which would make this row security working while the display says "0" rather than "not visible to you", exactly the absent-vs-invisible trap CLAUDE.md §4 names. **I did not confirm the cause** (reading the same card as `sam.supervisor` would settle it in one call) because diagnosing mid-rehearsal was out of scope. Weekend dates on this card are the known, deliberate artifact and are not part of this finding.

**4. AMBIGUITY, flagged as the brief anticipated — `hero-trade-spec` never names the analyst's action.** It specifies the *agent's* behaviour ("propose a borrow but hold it for a human because of position size") and stops there. I exercised the primary affordance, `Record Disposition → Settled - Borrow Executed`, which is the disposition the reason maps to. **The talk-track work needs to decide and write down what Alex actually clicks on stage**, because three other affordances are equally present (Assign, Escalate, Add Comment) and a presenter without a script will hesitate.

**5. OBSERVATION — `Matched Yes` still renders without a time on a packet row.** CLAUDE.md records the gate as opening in Phase 5, once packet trades author `MATCHED_AT` on the current clock. The packet does author it; the screen still shows state only. Not wrong — the display condition is conservative — but the ruled intent and the built screen have diverged. One for the mockup/talk-track pass.

**6. OBSERVATION — agent score variance, again.** The hero scored **0.65** this run against 0.62 and 0.65 in earlier runs; story 03 scored **0.90** against 0.88 yesterday. All lanes stable, all the right side of the gate. Consistent with the logged variance item; recorded so nobody reads it as drift.

---

## (e) Rehearsal verdict — can another SC run this cold today?

**Not cold. With this close-out in hand and about thirty minutes of reading, yes — and the machine itself is ready.**

What the rehearsal proves about the build: the whole lifecycle ran **twice** with no intervention beyond button-equivalents, settling in 88 seconds against an advertised two minutes; every figure on every screen reconciled at every stage, including mid-flight; the three-verb vocabulary held through an analyst action; both personas saw exactly their own scope; and reset returned the environment to the byte-level baseline. Nothing in the software stopped the rehearsal.

**What stands between here and "cold":**

1. **The demo script does not exist.** This is the big one. There is no document telling a presenter what to say, in what order, which screen to open when, or what to click as Alex — and step 6 exposed that the hero's own spec never names the analyst's action. Everything else on this list is smaller than this.
2. **`mockups/supervisor_command.html` is out of date with the built screen** (TODO, carried since Phase 4). A presenter comparing mockup to screen will find the layout reorganised.
3. **Phase 6 Ask panels are unbuilt.** The supervisor's `ASK ACROSS THE BOOK` card renders with a **disabled** text field and "Pick a question above, or ask your own" — visibly unfinished on the house view. Either build it or give the presenter a line for it.
4. **`SO Demo Admins` process-model security is unresolved** (TODO, blocking). A presenter who is only in that group cannot start Load/Reset, and the console then says "could not start". **Also: the presenter must be in `SO Supervisors`**, or intake reads a desk-scoped prediction set and silently finds only their own desk's stories.
5. **The two human-only checks remain human-only:** the Reset delete click and the console's was/now line. Neither blocks a demo; both should be ticked once by a person.
6. **Two parked `ACTIVE` intake instances** from earlier sessions are still uncancellable over the Dev MCP. Harmless, but they want clearing from the Admin Console before anyone inspects process history on stage.
7. **Operational hygiene a script must carry:** do not press Load twice (it moves the scoring stamp away from the case timestamps); reset before a demo if one was loaded on a previous day (the amber stale-date line will say so); and the fixture re-date ritual is a *session* ritual for rendering work, not something a presenter runs.

Nothing on that list is a code defect. Items 1–3 are content, 4 is a permissions ruling, 5–7 are hygiene.

---

## (f) Environment restored — evidenced

Console readback at 14:49, matching step 1 line for line: Baseline trades **50,000** · Baseline predictions **50,000** · Demo trades **0** · Demo cases **0** · Built-in test cases **17** · Case comments **12** · Audit rows **14** · Connections **9 of 9** · AI agent `last run 24 Sep 08:30` · verdict `Ready` · `No demo data loaded.` · Reset `disabled: true`. Both persona screens clean. Throwaways `SO_zzCycleProbe` and `SO_zzCycleCheck` deleted.

---

## Promotion candidates: 1 found; 0 promoted, 1 staged

- **STAGED, gate 1:** *a screen's rendered text can be identical under two different groupings, so "the screen looks right" does not verify a grouping change — compute both keys over the same live set and compare.* Measured here: the trend card read "1 cycle on record" before and after the swap, and only a probe showed the demo case moving from dropped to on-axis. **Trigger: the next change to a group-by, sort key or aggregation whose rendered output does not name the key.**
- **CLAUDE.md correction owed, not yet made** (no object changes permitted after Task 0): the file states the status→action mapping is "a browser check and only a browser check" because record-header actions render outside any interface a session can reach. **sail reaches them** — this rehearsal read `Record Disposition · Assign · Escalate · Add Comment` off the record header as the persona and drove one to completion. In TODO for the next session that may edit CLAUDE.md.
- Unchanged: the 2026-09-23 NULL-timestamp rule (applied again here — SO-84 still had blank `createdOn`/`modifiedOn` after the analyst's disposition write, while `resolvedOn` was set, which is precisely why the Task 0 swap was the right fix); the guard-vs-grouping method note; fixture-vs-process-rows; unused-locals; agent-boolean; process-instance blindness; NTZ-as-UTC; chart-type.

*Promotion checkpoint: current through this entry.*
