# Closeout — 2026-09-22 — Intake loop fixed: a flow back into an XOR gateway never re-fires

The intake loop created one case per run because the flow returning to its XOR gateway never re-activated it. The loop was restructured, measured in isolation, and verified on the live B2-TEST run: **all three cases now exist**, one per story, with the two missing ones created this session.

## (a) The probe measurement, quoted

Three throwaway objects, all deleted at the end. Every run below is `testProcessModel` output.

**1. Does a list of maps survive a Map-typed PV? Yes — a literal list, read back in a later node:**
```
countInline: 3     countFromPv: 3
item1: "T01"       item2: "T02"      item3: "T03"
toCreateText: "[tradeId:T01,...]; [tradeId:T02,...]; [tradeId:T03,...]"
```

**2. Does the real rule's output survive it? Yes — `rule!SO_intakePlan("B2TEST")` stored in the same Map PV, read back in a later node:**
```
ruleCountInline: 3   ruleCountFromPv: 3
ruleItem1: "TRD9B2TEST01"   ruleItem2: "TRD9B2TEST02"   ruleItem3: "TRD9B2TEST03"
```
**Candidate 1 is dead in both forms.** The plan reaches the loop intact.

**3. The loop shape mirrored, with Start Process children standing in for case creation and triage:** hung past 60 s, exactly like production.

**4. The same loop with the Start Process nodes removed — no records, no agent, no integrations:**
```
status: "ACTIVE"   (timed out at 45s)
idx: 2   count: 3   trace: "seed;take1=A;mid1;inc;"
```
One pass ran, the increment ran, and the token then sat at the gateway. **The smart services were never involved.**

**5. The same loop with the gateway moved downstream of the increment, loop-back into the script node:**
```
status: "COMPLETED"   (6.5s)
idx: 3   trace: "seed;take1=A;mid1;inc;take2=B;mid2;inc;take3=C;mid3;"
```

## (b) Root cause, two sentences

A flow returning to an XOR gateway that has already fired does not re-activate it, so the loop completed its first pass, incremented the index, and then sat forever at the gateway with no error, no pause and no alert. The plan, the count, the item extraction and both Start Process nodes were always correct — the loop-back target was the whole defect.

## (c) Changes, with readback

**`SO_intakeRun`** (`0000f060-f4bd-8000-2419-7f0000014e7a`) — the only production object changed. New flow:

```
3 plan (+idx=1) → 4 count → 12 XOR "Anything to create?" → 6 take next trade (LOOP TARGET, script)
  → 7 create case (sync) → 8 find the case → 9 XOR "Case written?" → 10 triage (async)
  → 11 increment → 13 XOR "Another trade to create?" → back to 6
```

- **Removed** node 5, the XOR that the loop used to return to.
- **Added** node 12 (`count >= 1 and idx <= 15`) and node 13 (`idx <= count and idx <= 15`).
- **Node 6 is now the loop target**, entered from 12 and from 13; it is a script node, which re-fires correctly.
- **Every gateway now has exactly one incoming flow** — 12 from 4, 9 from 8, 13 from 11.
- The hard 15 bound is kept on both gateways; nodes 6, 7, 8, 9, 10 are otherwise unchanged.

Readback: `updateProcessModel` returned every node, expression and flow as sent, and `validateDesignObject` returns `hasErrors: false`.

**Unchanged, as required:** `SO_intakePlan`, `SO_createTriageCase`, `SO_triageCase`, `SO_simulateRun`, `SO_resetRun`, both integrations, the connected system, the console, and everything Snowflake-side.

**Throwaways created and deleted this session** (all confirmed deleted): `SO_zzPlanShapeProbe`, `SO_zzLoopProbe`, `SO_zzLoopProbeChild`, constant `SO_zzPM_LOOP_CHILD`.

## (d) Verification on the live run

`testProcessModel` on the fixed `SO_intakeRun` with `runName: "B2-TEST"` returned **`status: "COMPLETED"`** in 14 s, `createdCaseId: 57`, `idx: 2` against `count: 1` — the loop exited through node 13 instead of hanging.

**The run's three cases, by readback:**

| case | trade | status | reason | score | disposition |
|---|---|---|---|---|---|
| 55 | `TRD9B2TEST01` | Pending Analyst | `insufficient_securities` | 0.62 | — |
| 56 | `TRD9B2TEST02` | Pending Analyst | `funding_gap` | 0.35 | — |
| 57 | `TRD9B2TEST03` | Resolved - Straight Through | `operational_error` | 0.90 | Settled - Corrected |

- **No duplicate for trade 01**, and no case for any of the twelve background trades.
- **Desks and fail reasons** match the plan on all three.
- **Audit and comments arrived**: events 133/134/135 on case 57 — created, assessed at 0.90, then "Straight-through: Correct & resubmit | confidence 0.90 >= threshold 0.80 | disposition Settled - Corrected | resolved before cutoff without analyst review".
- **Idempotency re-checked after the run:** `SO_intakePlan("B2-TEST")` now returns `alreadyCased` = all three and **`toCreate: []`**.

**One delta, recorded not forced:** packet-spec expects story 02 to **escalate**; it landed in the analyst lane at 0.35. The agent did not set escalate and `funding_gap` is not a reason override, so a sub-threshold score routes to a human — the lane is defensible, but it is not what the packet promises. Story 03 behaved exactly as specified.

**What this run did not prove:** the multi-iteration path on the *production* model with real data, because only one trade remained to create. The three-iteration proof is the isolated probe (measurement 5), and Scott's clean re-run after a reset will exercise it end to end on the real path.

## (e) Scott's remaining live-pass steps, renumbered against the current state

The run is loaded and all three cases exist, so the earlier steps 1–5 are done. What is left:

1. **Look at the three cases** on the analyst watchlist as `sam.supervisor` (all three are EQ_FLOW): 01 *Awaiting review*, auto-release score 62; 02 *Awaiting review*, score 35; 03 *Resolved · straight through*, Settled - Corrected. Confirm the hero reads as expected and tell me if story 02's analyst lane is acceptable or if the packet should be re-authored to force the escalation.
2. **Refused path:** console panel 2, type `1012-ACME-EXTRA` (15 characters), press Load. Expect red "Not loaded — refused" and verbatim `REFUSED: a run name is 1 to 13 letters, digits or dashes, e.g. 1012-ACME.` Then type `p4-verify` and confirm Load is disabled with the red built-in-test-data line.
3. **Repeat-press observation (not a fix target):** type `b2-test` again and press Load a second time. **Write down verbatim what the panel displays**, and whether it looks like a fresh answer or the previous one redisplayed. Last time the console read green while Snowflake's `SCORED_AT` proved the procedure ran only once. This feeds the queued console rework.
4. **Reset:** panel 3, type `b2-test`, press Delete. Expect "Cleaned up: B2-TEST", the verbatim `OK run=… trades_deleted=15 predictions_deleted=15`, "Appian was: 3 cases · 3 comments · 9 audit rows" and "Appian now: 0 cases · 0 comments · 0 audit rows".
5. **Both sides clean:** reload the console. Panel 1 should read demo-run trades 0, leftover 0, built-in 17, case comments 12, audit rows 14.
6. **The real three-iteration proof, if you want it in one pass:** after the reset, Load `b2-test` once more and confirm **three** cases appear from a single press. That is the loop fix exercised through the console rather than from a session.

## (f) The id gap, explained

Bracket: the missing ids sit after the P4-VERIFY fixture rows (case ids ≤ 52, comment ids ≤ 52, event ids ≤ 124) and before the first B2-TEST row on 2026-09-22 21:37, so they were consumed between 2026-09-10 and 2026-09-22.

Within that window CLAUDE.md records the matching event exactly: the 2026-09-09 cascade measurement on the Demo Admin site — **"two throwaway cases plus two comments and two events, deleted by case alone, took comments 14→12 and events 16→14"**. Two cases, two comments, two events, created and then deleted. That is case ids 53–54, comment ids 53–54 and event ids 125–126. **Explained, not a defect**, and consistent with Scott's answer that nothing ran in the eleven days before the live pass.

## Verified / not verified

**Verified** (Dev MCP as `scott.thorn`, SO Supervisors, full scope): the five probe runs quoted above; the fixed model's readback and validation; the completed live run; the three cases, their comments and their audit rows; idempotency after the run; the deletion of all four throwaways.

**Not verified:**
- Multi-iteration on the production model with live data — see (d); the console re-run covers it.
- **Parked instances.** The two intake instances started before the fix (the console's live run, and this session's first attempt) are still `ACTIVE` at the old gateway and will sit there. They cannot be cancelled over the Dev MCP; they are harmless but should be cleaned up from the Admin Console when convenient.
- Whether the console redisplays a stale result on a second press — deliberately left as an observation for step (e) 3, since the console is out of scope this session.

## Promotion

**1 candidate, PROMOTED** to appian-supplemental §9, and it **corrects that file's own explicit-loop recipe**, which prescribed the flow back to the XOR:

> A flow returning to an XOR gateway that has already fired does not re-activate it; the instance sits `ACTIVE` with no error, no pause and no alert, which in production reads as "the loop did one item and stopped". Working form: loop back to the script node and put the continue/stop gateway downstream of the increment, so every gateway has one incoming flow. Isolate before blaming the work nodes — the same loop hung identically with Start Process nodes in it, which reads like a smart-service fault.

Measured, reproduced in both directions, zero project nouns, contradiction named. The installed skill and the repo copy are in sync.

The investigation session's two staged candidates: **(a) the Map-PV collapse is DISCARDED** — measured false in both forms, and the discard is recorded rather than the history rewritten. **(b) process instances are not readable over the Dev MCP** stays staged, and it cost real time again today: the only way to see where the loop stopped was to rebuild it as a probe.

## TODO changes

Closed the blocking intake-loop item and both investigation questions. Added: the story-02 lane ruling, cleanup of the two parked instances, and the console repeat-press observation folded into Scott's step 3.

## BUILD_PLAN changes

The intake item is now done, with the defect and fix recorded; the console item points at the remaining live-pass steps; Part C stays behind Scott's clean console run.
