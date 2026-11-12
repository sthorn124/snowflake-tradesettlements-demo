# SO_prepareRun: outline

Built on NY on 2026-11-12 through the Dev MCP as `scott.thorn@appian.com` (Phase 11). Published version 2.0. UUID `0000f0b2-3422-8000-2c92-7f0000014e7a`. Constant `cons!SO_PM_PREPARE_RUN`.

**Not wired to the console.** Its synchronous part measured 34 seconds against the 20-second limit in `prompts/002-phase11-one-button-setup.md`, and the console's synchronous start gives up at 30. The build stopped there for a ruling.

Parameter: `runName` (Text, required). Every node runs as the initiator. Security: the same role map as `SO_simulateRun` (initiator `SO Demo Admins`).

Variables: `runName`, `state`, `ok` (Boolean), `message`, and for each step a message and a timed-out flag: `resetMessage`, `resetTimedOut`, `redateMessage`, `redateTimedOut`, `simulateMessage`, `simulateTimedOut`.

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Script "Read the run's state" (3) | `rule!SO_demoRunState(runName: upper(pv!runName))` | `pv!state` |
| 3 | XOR "Run in progress?" (4) | `state` = "RUNNING" | Routes: running to 5, otherwise to 6 |
| 4 | Script "Refuse: a run is in progress" (5) | | `ok` false; `message` = "REFUSED: a demo run is being prepared now. Nothing was changed. Wait about two minutes and refresh the page." Then End |
| 5 | Start Process, synchronous, "Clear the last run (SO_resetRun, sync)" (6) | `cons!SO_PM_RESET_RUN`, `runName` | `resetMessage` = the child's `pv!message`; `resetTimedOut` |
| 6 | XOR "Last run cleared?" (7) | `resetMessage` starts "OK run=" | Routes: yes to 8, otherwise to 20 |
| 7 | Start Process, synchronous, "Re-date the standing cases (SO_redateStandingCases, sync)" (8) | `cons!SO_PM_REDATE_STANDING_CASES` | `redateMessage`, `redateTimedOut` |
| 8 | XOR "Standing cases re-dated?" (9) | `redateMessage` starts "OK " | Routes: yes to 10, otherwise to 20 |
| 9 | Start Process, synchronous, "Load a fresh run (SO_simulateRun, sync)" (10) | `cons!SO_PM_SIMULATE_RUN`, `runName` | `simulateMessage`, `simulateTimedOut`. `SO_simulateRun` starts `SO_intakeRun` itself, in the background |
| 10 | Script "Report the load" (11) | `simulateMessage` | `ok` = message starts "OK run="; `message` = the load's message. Then End |
| — | Script "Stop at the failed step" (20) | the step messages | `ok` false; `message` = the failed step's own message, word for word, or a sentence naming a step that returned none. Then End |
| 11 | End (2) | | |

Notes
- `SO_resetRun` and `SO_simulateRun` are called as they are. Their `message` is not a process parameter, so a Sub-Process node cannot map it out; the Start Process smart service (`appian.system.smart-services.start-process-6`) returns it in `ProcessInfo`, read with `ac!ProcessInfo.pv.message`.
- Measured 2026-11-12, run 1 (nothing loaded before): 34.0 seconds start to end. About 2 s to read the state, 9 s for the reset step, 8.2 s for the re-date, 8.0 s for the load, and 3 to 4 s between each pair of steps. Start to Ready: 102 seconds.
- A start while the state was RUNNING was refused in 1.1 seconds with no step run.
- For the first 25 seconds or so of a Prepare, nothing in the data says a run is under way: the state reads the old state, then "Nothing loaded", until the load stamp lands. A second start in that window is not refused.
