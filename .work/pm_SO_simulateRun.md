# SO_simulateRun: outline

Read from NY on 2026-11-11 through the Dev MCP (`getProcessModel`) as `scott.thorn@appian.com`. Published version 3.0, saved 2026-09-11 15:47 UTC by `scott.thorn@appian.com`; no newer draft. UUID `0000f060-f4ba-8000-2418-7f0000014e7a`.

Started synchronously by the console's Load button with `runName` = `cons!SO_DEMO_RUN_NAME` (`DEMO`). Every node runs as the initiator.

Variables: `runName` (Text, parameter, required), `message` (Text).

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | XOR "Built-in test data?" (3) | `pv!runName` = `P4-VERIFY` | Routes: yes to 4, otherwise to 5 |
| 3 | Script "Refuse built-in test data" (4) | | `pv!message` = "REFUSED: P4-VERIFY is the built-in test data, not a demo run. Nothing was sent to Snowflake." Then End |
| 4 | Call Integration "Load feed in Snowflake (SO_simulateFeed)" (5) | `pv!runName`; the integration's response | Snowflake: `SIMULATE_FEED` for the run (the packet's trades and predictions). `pv!message` = the first value of `Result.body.data`, verbatim; or "No result from Snowflake…" when that is empty; or "Snowflake call failed: …" when the call fails |
| 5 | XOR "Feed loaded?" (6) | `left(pv!message, 7) = "OK run="` | Routes: yes to 7, otherwise to End |
| 6 | Start Process "Start intake (SO_intakeRun, async)" (7) | `cons!SO_PM_INTAKE_RUN`, `pv!runName` | Starts `SO_intakeRun` asynchronously with `runName`. The node's `ProcessInfo` output is not saved |
| 7 | End (2) | | |

Notes
- The model ends as soon as intake has been started. It writes nothing that says a run is under way; `pv!message` goes back to the console's local variable and is lost on a page refresh.
- Run time in the process history: 8 seconds on 2026-11-05 and on 2026-11-09.
