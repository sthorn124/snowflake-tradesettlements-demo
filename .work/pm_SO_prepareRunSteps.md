# SO_prepareRunSteps: outline

Built on NY on 2026-11-12 through the Dev MCP as `scott.thorn@appian.com` (Phase 11). UUID `0000f0b2-3930-8000-2c97-7f0000014e7a`. Constant `cons!SO_PM_PREPARE_RUN_STEPS`.

**The background half of Prepare.** Started asynchronously by `SO_prepareRun`. Every node runs as the initiator (the presenter who pressed the button). Security: the same role map as `SO_simulateRun`.

Variables: `runName` (Text, parameter, required), `runId` (Integer, parameter, required: the SO Demo Run row to close), `ok`, `status`, `message`, and for each step a message and a timed-out flag (`resetMessage`, `resetTimedOut`, `redateMessage`, `redateTimedOut`, `simulateMessage`, `simulateTimedOut`), `errRecord`, `errRecordMsg`.

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Start Process, synchronous, "Clear the last run (SO_resetRun, sync)" (6) | `cons!SO_PM_RESET_RUN`, `runName` | `resetMessage` = the child's `pv!message`; `resetTimedOut` |
| 3 | XOR "Last run cleared?" (7) | `resetMessage` starts "OK run=" | Routes: yes to 8, otherwise to 20 |
| 4 | Start Process, synchronous, "Re-date the standing cases" (8) | `cons!SO_PM_REDATE_STANDING_CASES` | `redateMessage`, `redateTimedOut` |
| 5 | XOR "Standing cases re-dated?" (9) | `redateMessage` starts "OK " | Routes: yes to 10, otherwise to 20 |
| 6 | Start Process, synchronous, "Load a fresh run (SO_simulateRun, sync)" (10) | `cons!SO_PM_SIMULATE_RUN`, `runName` | `simulateMessage`, `simulateTimedOut`. `SO_simulateRun` starts `SO_intakeRun` itself |
| 7 | Script "Report the load" (11) | `simulateMessage` | `ok`; `status` = "LOADED" when the message starts "OK run=", otherwise "FAILED"; `message` = the load's message |
| — | Script "Stop at the failed step" (20) | the step messages | `ok` false; `status` "FAILED"; `message` = the failed step's own message, word for word, or a sentence naming a step that returned none |
| 8 | XOR "Run record known?" (29) | `runId` | Routes: present to 30, otherwise to End |
| 9 | Write Records "Close the run record" (30) | `runId`, `status`, `message` | The SO Demo Run row by `id`: `status`, `message` (first 4,000 characters), `updatedOn` |
| 10 | End (2) | | |

Notes
- `SO_resetRun` and `SO_simulateRun` are called as they are. Their `message` is not a process parameter, so a Sub-Process node cannot map it out; the Start Process smart service (`appian.system.smart-services.start-process-6`) returns it in `ProcessInfo`, read with `ac!ProcessInfo.pv.message`. The initiator needs viewer on the child model for that.
- A step that fails or refuses stops the chain: nothing after it runs. `SO_demoRunState` hands the recorded message to the console, which shows it until the next press.
- Run time: about 32 seconds (reset 9, re-date 8, load 8, the rest between steps).
