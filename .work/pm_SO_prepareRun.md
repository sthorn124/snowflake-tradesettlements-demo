# SO_prepareRun: outline

Built on NY on 2026-11-12 through the Dev MCP as `scott.thorn@appian.com` (Phase 11). UUID `0000f0b2-3422-8000-2c92-7f0000014e7a`. Constant `cons!SO_PM_PREPARE_RUN`.

**The part of Prepare the page waits for.** Started synchronously by the "Prepare the demo" button on `SO_demoAdminConsole` with `runName` = `cons!SO_DEMO_RUN_NAME`. It answers in about 5 seconds and hands the work to `SO_prepareRunSteps` in the background. Every node runs as the initiator. Security: the same role map as `SO_simulateRun` (viewer `SO Users` and its groups, initiator `SO Demo Admins`); the page needs viewer to read `pv!message` back.

History: version 2.0 ran the three steps itself and took 34 seconds, over the 30 the page will wait. Scott ruled "start without waiting" on 2026-11-12; the steps moved to `SO_prepareRunSteps` and the run record was added.

Variables: `runName` (Text, parameter, required), `state`, `ok` (Boolean), `message`, `runRecord` (list of SO Demo Run), `errRecord`, `errRecordMsg`.

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Script "Read the run's state" (3) | `rule!SO_demoRunState(runName: upper(pv!runName))` | `pv!state` |
| 3 | XOR "Run in progress?" (4) | `state` = "RUNNING" | Routes: running to 5, otherwise to 12 |
| 4 | Script "Refuse: a run is in progress" (5) | | `ok` false; `message` = "REFUSED: a demo run is being prepared now. Nothing was changed. Wait about two minutes and refresh the page." Then End |
| 5 | Write Records "Record the start" (12) | `runName`, `pp!initiator`, `now()` | One new SO Demo Run row: `runName`, `status` "PREPARING", `startedBy`, `startedOn`, `updatedOn`. No key is passed, so it is always an insert. Saves the row to `runRecord`, and `errRecord` |
| 6 | XOR "Start recorded?" (7) | `errRecord`, `runRecord` | Routes: recorded to 8, otherwise to 20 |
| 7 | Start Process, asynchronous, "Start the steps in the background" (8) | `cons!SO_PM_PREPARE_RUN_STEPS`; `runName`; the new row's `id` | Starts `SO_prepareRunSteps` with `runName` and `runId` |
| 8 | Script "Report the start" (11) | | `ok` true; `message` = "OK started run=DEMO. The demo is being prepared in the background: about two minutes." Then End |
| — | Script "Stop: the start was not recorded" (20) | `errRecordMsg` | `ok` false; `message` = "Prepare could not record its start, so nothing was changed. …" Then End |
| 9 | End (2) | | |

Notes
- The run record is what makes the state read Running from the press. Without it, for the half minute in which the last run is cleared and the standing cases re-dated, the data holds no packet and no case, the state read "Nothing loaded", and a second press was not refused.
- A refused start writes nothing, so it cannot hide the record of the run in progress.
- Between reading the state and writing the record there is about a second in which a second press could also pass the check.
