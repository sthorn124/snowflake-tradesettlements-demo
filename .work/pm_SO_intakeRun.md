# SO_intakeRun: outline

Read from NY on 2026-11-11 through the Dev MCP (`getProcessModel`) as `scott.thorn@appian.com`. Published version 4.0, saved 2026-09-22 22:15 UTC by `scott.thorn@appian.com`; no newer draft. UUID `0000f060-f4bd-8000-2419-7f0000014e7a`.

Started asynchronously by `SO_simulateRun` after an "OK run=" load. Every node runs as the initiator (the presenter who pressed Load).

Variables: `runName` (Text, parameter, required), `plan` (Map), `idx`, `count`, `curTradeId`, `curFailReason`, `curProb`, `curCutoff`, `curDesk`, `createdCaseId`.

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Script "Plan intake from risk tier (SO_intakePlan)" (3) | `rule!SO_intakePlan(runName)`. The rule reads SO Trade Predictions for the run's 15 packet ids (`TRD9` + run code + `01`..`15`) with tier High or Critical, and SO Settlement Case for trades already cased under this session ID | `pv!plan` (`atRiskTradeIds`, `alreadyCased`, `noStory`, `toCreate`); `pv!idx` = 1 |
| 3 | Script "Count trades to create" (4) | `pv!plan.toCreate` | `pv!count` |
| 4 | XOR "Anything to create?" (12) | `count >= 1` and `idx <= 15` | Routes: yes to 6, otherwise to End |
| 5 | Script "Take next trade (loop target)" (6) | `pv!plan.toCreate[idx]` | `curTradeId`, `curFailReason`, `curProb`, `curDesk`; `curCutoff` = `now()` + the story's `cutoffMinutes`; `createdCaseId` = null |
| 6 | Start Process "Create case (SO_createTriageCase, sync)" (7) | The five `cur*` values and `pv!runName` | Through the subprocess: one SO Settlement Case row (`tradeID`, `sessionID` = run name, `status` "New", `failReason`, `desk`, `cutoffTs`), unless an open case for the same trade and session exists; then a Case Created event (type 1, no user, automation INTEGRATION) |
| 7 | Script "Find the case just written" (8) | SO Settlement Case where `tradeID` = current trade, `sessionID` = run name, `status` = "New"; newest `caseID` | `createdCaseId` |
| 8 | XOR "Case written?" (9) | `createdCaseId` not empty | Routes: yes to 10, otherwise to 11 |
| 9 | Start Process "Start triage (SO_triageCase, async)" (10) | `createdCaseId` | Starts `SO_triageCase` asynchronously with `caseId`. `ProcessInfo` is not saved |
| 10 | Script "Next trade (increment)" (11) | `idx` | `idx` + 1 |
| 11 | XOR "Another trade to create?" (13) | `idx <= count` and `idx <= 15` | Routes: yes back to 6, otherwise to End |
| 12 | End (2) | | |

Notes
- Intake ends when the last triage has been started, not when it has finished. It writes no run-level state.
- Cases are created one at a time: create (synchronous), then triage (asynchronous). The three triage runs therefore overlap, started about 10 seconds apart.
- Story attributes live in `SO_intakePlan`: sequence 01 `insufficient_securities` 185 minutes to cutoff; 02 `funding_gap` 150; 03 `operational_error` 540.
- Run time in the process history: 32 seconds on 2026-11-05 and on 2026-11-09.
- `SO_createTriageCase` was read for this outline (nodes: check for an open case, XOR, Write New Case, XOR, Write Case Created Event). It has no outline file of its own.
