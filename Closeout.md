# Closeout — 2026-09-22 — Investigation: intake created 1 case where Snowflake counted 3

Read-only investigation of the B2 live pass. **No Appian object, process or row was created, changed or deleted, and the B2-TEST run is still loaded** so the fix session can work on the live evidence.

## Scope and identity

- Dev MCP as `scott.thorn` (member of `SO Supervisors`), so every readback below is full-scope and an absence is a real absence.
- No `appian_*` / `ping` — the runtime server stayed banned, including for the one question it could have answered (process-instance status).
- No Snowflake execution, no sail run, no persona check.
- Tools used: `testRule` on the existing `SO_intakePlan`, `listRecordData`, `getRecordType`, `getProcessModel` / `listProcessModelNodes`, `getInterface`.

## What changed

**Nothing in Appian.** Files only: this close-out, `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`.

## What the evidence says

**The case that exists.** `caseID 55`, trade `TRD9B2TEST01`, session tag **`B2-TEST`** (with the dash), `Pending Analyst`, `confidenceScore 0.62`, desk `EQ_FLOW`, `cutoffTs 2026-09-23 00:42:01`. That is **story 01, the hero — and the first item of the plan's `toCreate` list**. Comment id 55 and audit rows 127, 128, 129 all belong to it. No case carries `B2TEST` without the dash.

**The plan is healthy; the loop is the suspect.** `SO_intakePlan("B2-TEST")`, evaluated live this session:

```
atRiskTradeIds: [TRD9B2TEST01, TRD9B2TEST02, TRD9B2TEST03]
alreadyCased:   [TRD9B2TEST01]
noStory:        []
toCreate:       TRD9B2TEST02 (Critical 0.81, funding_gap, 150)
                TRD9B2TEST03 (High 0.72, operational_error, 540)
```

The two missing trades are sitting in `toCreate` right now. Tier reading and id derivation are not broken.

**The data is all there.** All 15 predictions and all 15 trades exist. `01` Critical 0.83, `02` Critical 0.81, `03` High 0.72; the other twelve are Low or Medium, 0.10–0.45. `SO Trade Predictions` is `sourceType: SNOWFLAKE`, read live, not synced.

**The second Load never reached Snowflake.** Every prediction row carries `scoredAt 2026-09-22 21:36:53` — one stamp, one load. `SIMULATE_FEED` re-stamps `SCORED_AT` on every successful call, so a second successful load would have moved all fifteen. It did not, which means the second Load returned something other than `OK run=` and node 6 stopped without starting intake. **The second Load is not evidence about the loop.**

**Timing.** Insert 21:36:53 UTC → case created 21:37:05 (12 seconds later, ~1 minute after the button) → assessment 21:38:02 → referral 21:38:07. One case, 62 seconds end to end. No later case-creation event exists, so trades 02 and 03 were never attempted — not attempted and failed.

**An unexplained gap.** Case ids **53, 54**, comment ids **53, 54** and audit ids **125, 126** are missing from otherwise contiguous sequences, immediately before the B2-TEST rows. Two case-shaped sets of ids were consumed and are not in the tables.

## Verified / not verified

**Verified** (Dev MCP, as `scott.thorn`, full scope): the case row and its children; the plan rule's live output in both run-name forms; all 30 packet rows; the predictions record type's source; the deployed node graphs of `SO_intakeRun` and `SO_simulateRun`; the console's stored `upper(local!runName)`.

**Not verified, and why:**
- **The intake process instance — whether it completed, is still running, or is paused by exception.** The Dev MCP design surface has no instance listing, history or status tool; `testProcessModel` starts a new instance instead of reading one. The only instance-status tool in the session is on `appian-runtime`, which CLAUDE.md bans and which needs a process id I do not have. Not worked around. **This is the fact that would separate the two candidates below.**
- Whether a list of maps survives storage in a Map-typed process variable — the 2026-09-11 shape probe ran inside an expression rule, never through a PV.
- Nothing browser-only arose; no geometry or persona question was in scope.

## Two candidate causes, ranked — inference, not measurement

1. **The loop ran one iteration because `count` evaluated to 1 inside the process.** `pv!plan` is a **Map** PV holding `toCreate` as a list of maps, and both node 4's count and node 6's item extraction depend on that nesting surviving PV storage. If it collapses to its first element, count is 1, iteration 1 writes the first item — **trade 01, exactly the case that exists** — and idx 2 exits to End. Supporting: the surviving case is the first list item, not a random one; the rule is healthy standalone; the PV round-trip is the one step in this path never measured.
2. **The loop stalled after iteration 1** — node 7's synchronous Start Process pausing by exception on the second pass, or the flow back to node 5. Consistent with one case plus a completed triage. Slightly against: nodes 10 and 11 demonstrably worked once, so the failure must be specific to the second pass.

## Rulings and answers needed from Scott

1. **What did the second Load show?** The message text decides whether anything is wrong with `SO_simulateRun` at all, or only with the loop.
2. **Was there an earlier load-and-reset today?** That would explain the id gaps; if not, two case inserts were rolled back and that is a second defect.
3. **Fix-session scope:** measure candidate 1 first with a PV round-trip probe (cheap, decisive), and keep the B2-TEST run loaded until it is.

## Promotion candidates

**2 found; both STAGED, neither promoted.**

- **(a) A list of maps stored in a Map-typed process variable may not survive as a list.** Gate 1 not met — the mechanism is inferred from one run's outcome, not measured. *Trigger: the fix session's PV round-trip probe.*
- **(b) Process instances are not readable over the Dev MCP** — no listing, history or status tool; `testProcessModel` only starts one. Rule-shaped as "plan verification that never depends on reading an instance", but stated from one session's tool surface. *Trigger: the next session that needs instance state; confirm against the tool list then.*

NTZ-as-UTC and chart-type remain staged from earlier sessions.

## TODO changes

Added: fix the intake loop (blocking, with both candidates and the "leave the run loaded" note); the second-Load message question; the id-gap question; process-instance observability as a standing tooling limit. Updated: the live-pass item now records that steps 1–5 ran and 6–9 did not.

## BUILD_PLAN changes

The intake and console-wiring items now record that the live pass ran on 2026-09-22 and found the defect; Part C stays closed behind it.
