Read-only session on NY. Change nothing in Appian: no creates, updates or deletes, no `testProcessModel`, no record writes.

1. Before any tool call, confirm the rules loaded: list the steps of the close-out routine (core §10) from context, without opening a file. If you can't, stop and say so.
2. Run the preflight (`CLAUDE.md`, "Session start"). If the Dev MCP design tools are missing, stop and say so.
3. Read the deployed source of `SO_demoAdminConsole` and the process models `SO_simulateRun`, `SO_intakeRun`, `SO_resetRun` and `SO_triageCase`. Save the console's source over `.work/SO_demoAdminConsole.sail`. For each process model, write a short outline (nodes in order, what each reads and writes) to `.work/pm_<name>.md`.
4. Answer from what you read, without running anything:
   - Where does `SO_triageCase` write the agent's result to the case, and what does that write do if the case has been deleted?
   - What does the console's status line count to decide a demo is loaded?
   - What could a screen read to tell "run in progress" from "run finished"?
5. List the cases that have no trade (reported as SO-106 to SO-110): case id and status only. Do not delete them.
6. Close out per core §10 and push. Put the answers to 4 and 5 in `Closeout.md` under "Inputs for Phase 11". Tick the Phase 10 audit item in `BUILD_PLAN.md`.
