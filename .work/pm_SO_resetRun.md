# SO_resetRun: outline

Read from NY on 2026-11-11 through the Dev MCP (`getProcessModel`) as `scott.thorn@appian.com`. Published version 3.0, saved 2026-09-11 15:48 UTC by `scott.thorn@appian.com`; no newer draft. UUID `0000f060-f4bf-8000-241a-7f0000014e7a`.

Started synchronously by the console's Reset button with `runName` = `cons!SO_DEMO_RUN_NAME` (`DEMO`). Every node runs as the initiator.

Variables: `runName` (Text, parameter, required), `cases` (list of SO Settlement Case), `deletedCount`, `errDelete`, `errDeleteMsg`, `message`.

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | XOR "Built-in test data?" (3) | `pv!runName` = `P4-VERIFY` | Routes: yes to 4, otherwise to 5 |
| 3 | Script "Refuse built-in test data" (4) | | `pv!message` = "REFUSED: P4-VERIFY is the built-in test data, not a demo run. Nothing was deleted." Then End |
| 4 | Script "Find this run's cases" (5) | SO Settlement Case (`caseID`, `sessionID`) where `sessionID` = `pv!runName`, first 1000 rows | `pv!cases` |
| 5 | XOR "Any cases in Appian?" (6) | `pv!cases` empty | Routes: empty to 9, otherwise to 7 |
| 6 | Delete Records "Delete this run's cases (comments + audit cascade)" (7) | `pv!cases` | Deletes those cases. Their comments, audit events and subscribers go with them through the CASCADING relationships. `PauseOnError` is false. Saves `deletedCount`, `errDelete`, `errDeleteMsg` |
| 7 | XOR "Appian delete succeeded?" (8) | `errDelete` | Routes: no error to 9, error to 10 |
| 8 | Call Integration "Remove run from Snowflake (SO_resetSession)" (9) | `pv!runName`; the integration's response | Snowflake: `RESET_SESSION` for the run. `pv!message` = the procedure's message verbatim; or "No result from Snowflake…"; or "Snowflake call failed: …". Then End |
| 9 | Script "Stop before Snowflake" (10) | `errDeleteMsg` | `pv!message` = "Appian could not delete this run's cases, so Snowflake was not touched. …" Then End |
| 10 | End (2) | | |

Notes
- Cases are selected by session ID only. A case whose session ID is empty is never selected, so Reset cannot remove it.
- The model does not look for, wait for or cancel running `SO_intakeRun` or `SO_triageCase` instances.
- Run time in the process history: 8 seconds on each of the three runs listed (two on 2026-11-05, one on 2026-11-09).
