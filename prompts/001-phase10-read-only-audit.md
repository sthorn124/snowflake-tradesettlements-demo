# Phase 10: read-only audit of the NY environment

This session builds nothing. It reads the NY Appian environment, records what is there, and closes out. The next build prompt (Phase 11 in `BUILD_PLAN.md`, the demo setup experience) will be written from this session's `Closeout.md`, so the close-out is the deliverable.

## Background

- The last build session on record is 2026-09-24 (`BUILD_LOG.md`).
- NY was changed after that with no close-out. These changes are known only from planning chats, dated 2026-10-22 and 2026-10-23:
  - a sort fix on the analyst watchlist;
  - a hand re-date of the 17 standing cases (the hand-authored cases every Phase 4 screen renders from, session `P4-VERIFY`, case ids 36 to 52 in `fixtures/p4-verify-cases.csv`);
  - the "Cleared this batch" card on the analyst watchlist hidden in Designer;
  - blank cases, reported as SO-106 to SO-110, left when Reset ran while triage was still running.
- The repo moved to the Kiro method on 2026-10-07. No Kiro session ran on it. On 2026-11-11 `CLAUDE.md` was added so Claude Code loads the rules from `.kiro/steering/`. This is the first session to rely on it.
- Treat every item above as a claim to test. Report what NY shows, including where it disagrees with this list.

## Hard limits for the whole session

NY is read-only. If answering a question would break a limit, leave the question unanswered and say why.

1. No Dev MCP call that creates, updates, deletes, publishes, adds or removes anything. Reads only: `get*`, `list*`, `validate*`, `testRule`, `testInterface`, `getDevMcpVersionInfo`.
2. No `testProcessModel`. It starts a real process.
3. No record writes of any kind. This includes the per-session re-date ritual: do not apply the `fixtures/p4-verify-redate.py` CSVs this session. The audit needs the standing cases exactly as the 2026-10-23 hand re-date left them. Record in the log that the ritual was skipped and why.
4. Before running `testRule` or `testInterface` on an object, read its source. Do not run it if the run would start a process, write a record, call the triage agent, or call Snowflake Cortex (the Ask panels). Reading Snowflake data through the record types is fine. One exception: render `SO_demoAdminConsole` once, pressing nothing, if its source shows the render starts no process and does not call the triage agent.
5. sail reads pages only. No submits. No button that starts a process. A record action may be listed but not followed.
6. No deletes. The blank cases are recorded, never removed. Phase 11 removes them.
7. No `appian_`-prefixed tool and no `ping`. No Snowflake execution path. Both are already in the rules.
8. Nothing is fixed. If something is broken, record it with its evidence and move on.
9. The only files written are in this repo: `.work/` copies, `Closeout.md`, `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`.

## Part 0: Confirm the rules loaded, then preflight

Do these in order, before any other work.

1. Without opening any file, state the seven steps of the close-out routine (core §10) and the binding rule on `appian_`-prefixed tools (`project.md`). Then list which of these are in your context: `CLAUDE.md`, `core-00` to `core-06`, `project.md`. If you cannot do this from context, STOP and report that the `CLAUDE.md` imports did not load. Do not make any Dev MCP call.
2. Confirm the repo is clean and level: `git status` reports nothing to commit and `HEAD` equals `origin/main` after a fetch. If the local repo is behind, pull. If it has local changes, STOP and report them.
3. Run `python3 .kiro/scripts/preflight.py` and read its report (`CLAUDE.md`, item 1).
4. Skills. Look in `~/.claude/skills/` for `appian-supplemental` and `appian`. Load each one that is there. If `appian-supplemental` is missing, read the repo copy at `skills/appian-supplemental/SKILL.md` and say so. If the installed copy's version line differs from the repo copy, report both. If Appian's `appian` skill is missing, say so and carry on, because this session creates and edits nothing.
5. Run the core §2 steps marked `[agent]`: the design tool surface and tool count, one `listRecordTypes` read on the Application UUID, `getDevMcpVersionInfo` against the pins, which server each tool family belongs to, and the executing identity with its groups read back from NY. Skip step 7 under hard limit 3.
6. If the design tools are missing or the read fails, STOP as core §2 step 3 says. Close out with what you have.
7. If runtime-server tools are present in the session, name the server they sit under. Do not call them.
8. If any read returns NY's Appian platform version, record it.
9. Take the baseline for the read-only proof, as `scott.thorn`: the row counts of `SO Settlement Case`, `SO Case Comment` and `SO Settlement Case Event History`, and the highest case id.

## Part 1: What changed in NY since 2026-09-24

1. List every design object in the Settlement Operations application modified after 2026-09-24: name, type, last modifier, modified date, current version.
2. Compare deployed source with the repo. `.work/` holds 36 saved copies of interfaces and expression rules. For each of the 36, and for every object on the list from step 1, read the deployed source and say whether it matches the `.work/` copy. Where it differs, describe the difference in plain words and overwrite the `.work/` copy with the deployed source. Where a changed object has no `.work/` copy, add one, following the existing file naming.
3. The list from step 1 and the differences from step 2 should agree. Where they do not, say so.
4. Find and describe these two changes specifically:
   - the watchlist sort fix: which object, what the sort was, what it is now;
   - the "Cleared this batch" card (queue 3 in `SO_analystWatchlist`): whether it is hidden, by what means, and whether anything else in the screen still counts or refers to it.
5. Process models. For `SO_simulateRun`, `SO_intakeRun`, `SO_resetRun`, `SO_triageCase` and `SO_createTriageCase`: current version, last modified, and whether it changed since 2026-09-24. Write a plain outline of each to `.work/pm_<name>.md`: the nodes in order, what each reads and writes, and each gateway's condition. Phase 11 changes these models, and this is its starting point. Answer these from the node configuration, without running anything:
   - `SO_triageCase`: where the agent's result is written back to the case, and what that write does if the case row no longer exists. Does it fail, do nothing, or create a new row?
   - `SO_resetRun`: the order of its steps, exactly what it deletes, and whether anything checks for triage still running.
   - `SO_simulateRun` and `SO_intakeRun`: what a screen could read to tell "a run is in progress" from "the run has finished", and what marks the three stories as each having an agent decision.
6. `SO_demoAdminConsole`: what its status line reads (which queries and which counts), and where the `P4-VERIFY` refusal and the `SO Supervisors` check sit. Render it once under hard limit 4 and record its default view word for word.

## Part 2: The data as it stands

Every readback here runs as `scott.thorn`, full scope. Say so on each.

1. The 17 standing cases. For each: case id, status, desk, assignee, cutoff, created, modified and resolved times. Compare with `fixtures/p4-verify-cases.csv` and say whether NY matches it. Say how far past cutoff the book is today. For their comments and events, compare the timestamps with the other two CSVs and report how many match.
2. The blank cases. Find every case outside the 17 that is missing its trade, desk or cutoff. For each: case id, session id, status, fail reason, score, disposition, which fields are empty, its resolved time, and its comments and events with their text. A process-written case has no created or modified time by design (`project.md`, Repeatability), so those two being empty is not evidence. Confirm or correct the reported ids SO-106 to SO-110.
3. Every other case: any case that is neither standing nor blank, grouped by session id, with status and trade id.
4. Whether a demo is loaded. Through the record layer, list the trades and predictions in the reserved `TRD9` id range, with trade id and scored-at time. Then state which of these NY is in: nothing loaded; loaded and complete; partly loaded (trades without cases, or cases without trades).
5. Process instances for the five models in Part 1 step 5:
   - anything running, paused or in error now: id, model, start time, initiator. Cancel nothing.
   - the instances from 2026-10-22 and 2026-10-23, if NY still has them: id, model, status, start, end, initiator.

## Part 3: The hero that escalated (observe only)

On one Load on 2026-10-22 the hero case landed in Escalated instead of Needs your action. The cause is unknown. Change nothing and do not run a Load to reproduce it.

1. If the 2026-10-22 `SO_triageCase` instances still exist, find the hero's. Record the values that decide the lane: broker confirmation lag, hours to cutoff at triage, score, the agent's escalate flag, fail reason, final status. Record the timing too: when the case was created, when triage started, when the agent answered.
2. Read the deployed escalation logic in `SO_triageCase` beside `hero-trade-spec.md` §3. State the margin the hero has at Load between its lag and its window, and name every path in the deployed model that can end in Escalated for the hero.
3. End with one of three verdicts: cause found, with the evidence; candidates narrowed, with what would tell them apart; no evidence left. Do not guess (core §3).

## Verification

### Read-only proof

- Re-read the three row counts and the highest case id from Part 0 step 9. They should equal the starting values. If they differ, report it, and do not assume the cause: another user may have been on NY.
- List every Dev MCP tool name called this session and confirm none is a write.
- `git status` before the commit shows only `.work/` files, `Closeout.md`, `BUILD_LOG.md`, `BUILD_PLAN.md` and `TODO.md`.

### As each persona, through sail (read only)

The standing cases will show stale dates because the re-date was skipped. Read for content and structure, and do not report the staleness as a defect. If a persona has no live session, report "no live session for `<persona>`, run the login" and skip that persona.

As `alex.analyst` (SO Analysts, desk EQ_FLOW), record:
- which pages of the site resolve;
- on the watchlist: which queues render, with their counts; whether "Cleared this batch" renders; the order of the rows in Needs your action and what that order follows;
- whether any blank case appears anywhere on the watchlist;
- on one open case: the record actions the header lists.

As `sam.supervisor` (SO Supervisors), record:
- which pages of the site resolve;
- whether the supervisor screen renders without an error;
- whether any blank case appears in its counts, its queues or the Analyst Queues card.

For both: the Demo Admin site should not resolve.

### Operator's browser checklist (Scott; write it into `Closeout.md`, do not attempt it)

1. In Designer on NY, New, Connected System: is there a Databricks tile? This is the first gate of Phase 12.
2. As `alex.analyst`, the watchlist: the "Cleared this batch" card is not on the page, and the rest of the page is laid out as before.
3. As the presenter, the Demo Admin console: the status line, as it reads on screen.

## Close-out

Run the full close-out of core §10, with `CLAUDE.md` items 5 and 6.

- `Closeout.md`, rewritten whole, in plain language. It must include:
  - the table of changed objects from Part 1;
  - an answer to every numbered question in Parts 1 to 3, each with the evidence it rests on;
  - what each persona saw;
  - what was not verified, and why;
  - the operator's browser checklist;
  - a section headed "Inputs for Phase 11" with: the confirmed blank-case ids; where the agent write-back sits and how it behaves when its case is gone; what a status line can read to tell running from ready; the fields a re-date has to move on cases, comments and events; the hero verdict.
- `BUILD_PLAN.md`: tick the Phase 10 audit item with the date. Where the audit found facts that differ from the Phase 10 introduction or the Phase 11 blank-case line, correct those lines. Add nothing else.
- `BUILD_LOG.md`: one entry, with the scope line and the promotion checkpoint.
- `TODO.md`: close "Confirm `CLAUDE.md` loads the rules in Claude Code" if Part 0 step 1 passed. Add the operator's browser checklist under browser checks owed. Add anything the audit found that needs an owner. End the response with the `TODO changes:` line.
- Commit as `closeout: <today's date> — Phase 10 read-only audit of NY`, push to `origin main`, and verify `HEAD` equals `origin/main`.
- Skip `credits.py`, and say in `Closeout.md` that the session ran in Claude Code.
