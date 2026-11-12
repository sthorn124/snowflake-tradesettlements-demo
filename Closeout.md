# Closeout — 2026-11-12 — Phase 11 build: triage guard, re-date model, run-state rule and Prepare built and verified; stopped at Prepare's timing, console and documents not changed

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/002-phase11-one-button-setup.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. This file replaces the close-out of the Phase 10 audit.

**Scope and identity.** Every Appian call went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`, a direct member of `SO Supervisors` and `SO Demo Admins`. The supervisors' case rule has no condition, so every read below is full-scope. Identity was confirmed by an assertion with a negative control. No sail session was used, by ruling. The runtime server's tools were present and never loaded or called. Two helper agents made read-only Dev MCP calls under the same account (a node-type listing, and two screen renders).

**Outcome in one paragraph.** Parts 0 to 4 are built and verified. Part 4's pass condition failed: the part of Prepare the page would wait for takes 34 seconds, against a limit of 20, and the console's synchronous start gives up at 30. The prompt says to stop and report there and not to redesign, so Parts 5 (console) and 6 (documents) were not done. NY's console is the same two-button page as before and still works. `SO_prepareRun` exists and runs correctly through the Dev MCP, but nothing on a page starts it.

## Preflight

- **Plan:** populated. **Dev MCP:** design surface present (218 tools counted); `listRecordTypes` returned the 11 record types and User.
- **Versions:** plugin and server 26.9.5, build `20261026-140102`. The pins describe 26.6.105; the App Market has 26.9.15. The update procedure was not run, by ruling. The pack's manifest matches the plugin.
- **Groups, by readback:** `SO Users` holds `SO Administrators`, `SO Analysts`, `SO Supervisors`. `SO Analysts` holds `alex.analyst` and no group. `SO Supervisors` 11 users, `SO Demo Admins` 9.
- **Personas:** every sail session on the machine is expired. None was needed.
- **Ritual:** skipped, by the prompt. Part 2 replaced it.
- **Git:** the local folder was one commit behind `origin/main` (the prompt's last edit) and was fast-forwarded first.

## Part 0: skills

| Copy | Before | After |
|---|---|---|
| `~/.kiro/skills/appian-supplemental` (master) | Version 2026-11-10.4 | unchanged |
| `~/.claude/skills/appian-supplemental` | Version 2026-10-28 | Version 2026-11-10.4 |
| `skills/appian-supplemental/SKILL.md` (repo) | Version 2026-10-05.2 | Version 2026-11-10.4 |
| `~/.kiro/skills/appian` (master) | `274ce627` | unchanged |
| `~/.claude/skills/appian` | `eb82064a` | `274ce627` |

The copies are exact (no differing file). The old `~/.claude` copies were backed up outside the repo first. One thing to know: after the copy, the Skill tool still served the supplemental it had cached at session start (2026-10-28), so the new file was read from disk instead. The pack loaded from the new copy.

## What changed on NY

| Object | Version | Change |
|---|---|---|
| `SO_triageCase` | 14.0 → 18.0 | New check "Case still exists?" (node 14) straight after the agent node. If the case is gone, the process ends and writes nothing. Description corrected |
| `SO_intakePlan` | 1 → 2 | Each story carries a console label and its scripted status; a new `stories` output hands them on. Intake reads nothing new |
| `SO_standingCaseOffsets` | new, 3 | The standing cases' offsets, in minutes. The one home of them |
| `SO_standingCaseRedate` | new, 1 | The clock, the stamps, the record values, and the list of ids missing from the site |
| `SO_redateStandingCases` | new, 5.0 | Checks the ids, then writes cases, comments and events on one clock |
| `SO_demoRunState` | new, 1 | The run's state in six values, with the status line and its colour |
| `SO_prepareRun` | new, 2.0 | Refuse if Running; reset; re-date; load. Returns the failed step's message word for word |
| `SO_PM_REDATE_STANDING_CASES`, `SO_PM_PREPARE_RUN` | new | Process-model constants |

Both new models carry `SO_simulateRun`'s security, read back: start rights for `SO Demo Admins`.

**Not changed:** `SO_demoAdminConsole` (version 12), `SO_resetRun`, `SO_simulateRun`, `SO_intakeRun`, every persona screen, every record type.

**In the repo:** the three rule sources and two model outlines in `.work/`; `.work/gen/` (a reference expander, rule templates, the check that compares a re-date with the old script, and the undeployed console draft with the patch that makes it); `fixtures/p4-verify-redate.py` marked superseded; `.kiro/steering/project.md` (the ritual, the Repeatability section, two new facts, one correction); the installed skill copy; `BUILD_PLAN.md`, `TODO.md`, `BUILD_LOG.md`, this file.

## Part 1: the triage guard

**Reproduced first, on version 14.0.** A throwaway case (135, session `ZZ-GUARD`, baseline trade `TRD000003`) was deleted while the agent ran. The late writes left:
- the case **re-created under its own id**, with status "Pending Analyst", the remediation and a score of 0.88, and no trade, session, fail reason, desk or cutoff;
- one comment, the agent's 642-character assessment;
- two audit events, both "Agent Triage Complete" ("Agent assessed unknown reason; …" and "Referred to analyst: no straight-through disposition for this fail reason | …").

That is the blank case of 2026-10-22, measured.

**With the guard, version 18.0.** The same test on case 136: the process ended in 28 seconds and wrote nothing. No case row. With a parent row put back at that id, the only child was the Case Created event from before the delete: no comment, no agent event.

**A case left alone (137)** ran in 45 seconds and routed straight-through at 0.88, writing the case, the comment and the two events that lane writes. The routing was not changed.

All three cases, their comments and events were deleted, children first, and read as absent.

## Part 2: re-dating the standing cases

- **The ids match.** NY holds 17 cases (36 to 52), 12 comments (41 to 52) and 14 events (111 to 124), on the same parents as the script's tables, with no extra row.
- **Same stamps as the script.** For the same UTC hour, all 43 rows stored on NY after a run equal what `fixtures/p4-verify-redate.py` produces: one exact comparison of 2,720 characters, with a wrong expectation failing as the control.
- **Case 39 is the only standing case past cutoff** after every run. Before the first run all 17 were, dated 2026-10-23.
- **A second run in the same hour changes nothing.** Four runs wrote the 06:00 UTC clock; the comparison held after each.
- **The model refuses to guess.** A wrong id in the table stopped it before any write, with a message naming the row. Three rows broken on purpose were put right by the next run.
- **It writes times and nothing else.** A standing case a rehearsal has changed keeps the change.
- The script says at its top that it is superseded. `project.md` now names `SO_redateStandingCases` as the per-session ritual.

## Part 3: the run's state

`SO_demoRunState` returned each of the six states on NY, with the ruled copy:

| State | Reached how | Line returned |
|---|---|---|
| Nothing loaded | real | "No demo loaded." |
| Running | real, 12 s after a load | "Preparing the demo. About two minutes. Refresh this page to check." |
| Ready | real | "Ready to present. Loaded today at 1:42 AM." (green; the reader's time zone) |
| Story out of place | real, by setting the hero case to Escalated | "Not ready. The hero case is Escalated, not Awaiting review. Prepare the demo again." |
| Did not finish | real, by setting one case back to New: Running at 239 s, Did not finish at 302 s | "The last run did not finish. Prepare the demo again." |
| Loaded before today | from the rule only, with its clock set a day ahead | "Loaded before today. Prepare the demo again for fresh dates." |

Demo cases are counted by run name. The two status edits were made on demo cases that the next Prepare then cleared.

## Part 4: Prepare

Two runs through `testProcessModel`, as the design account.

| | Run 1 | Run 2 |
|---|---|---|
| State at start | Nothing loaded | Did not finish |
| Ended in Ready with no other action | yes | yes |
| **The part the page would wait for** | **34.0 s** | **33.9 s** |
| Start to Ready | about 102 s | about 99 s |
| Demo cases after | 3 | 3, not 6 |
| Hero | Pending Analyst, 3h 04m to cutoff | Pending Analyst, 3h 03m to cutoff |
| Story 02 / story 03 | Escalated / Resolved - Straight Through | the same |
| Standing cases | today's dates, only case 39 past cutoff | the same |

- Straight after each start the state read Running.
- A start while a run was in progress was refused in 1.1 seconds, and nothing ran.
- After run 2 the watchlist and the supervisor screen rendered with no error. The watchlist shows the hero under Needs your action at "3h 03m".

**Where the 34 seconds go:** about 2 to read the state, 9 for the reset, 8 for the re-date, 8 for the load, and 3 to 4 between each pair of steps. The two Snowflake calls are about 16 seconds on their own, so the order the prompt sets cannot come in under 20. A third run was not made: two settle it, and each costs three agent calls.

## Rulings needed

**1. How should the page start Prepare?** My recommendation is the first.

- **Start it without waiting, and record the run.** The button returns in two or three seconds. Prepare writes a small run record when it starts and when a step fails (a new record type, one row per run name: started at, by whom, last message). `SO_demoRunState` reads it, so the page shows Running from the press, shows a failure message after a refresh, word for word, and refuses a second start from the first second. It also gives the "who loaded it" line the planning chat proposed. Cost: one new record type and a change to the state rule and to Prepare.
- **Keep waiting, and run the re-date beside the reset and load instead of between them.** About 24 to 25 seconds. Over the 20, under the 30, with little margin: one slow Snowflake call and the page reports "no answer" while the run carries on.
- **Leave the two buttons.** Everything built today still helps: the guard, and a re-date that a session or a third button could start.

**2. Reset leaves each run's assessment comments in the table.** After Reset deleted a demo case, a row put back under the same id showed its comment still stored and its audit events gone. Comments are readable only through their case, so the leftovers are invisible to every account and every count; the 2026-09-09 "comments 14 → 12" was a count of what could be seen. Measured once. Two questions: should Reset delete the comments before the cases, and should the rows already left be cleaned up? `SO_resetRun` was not edited. One such comment (137, from run 1) was left as Reset left it.

**3. Should Ready look at how old today's load is?** A run loaded at 1:48 AM still reads "Ready to present" at 9 AM, with the hero's cutoff hours past. NY is in that state now (below).

Still open from earlier: cancelling the two stuck `SO_triageCase` instances is yours, in Process Monitoring; the rulings listed in `BUILD_PLAN.md` are unchanged.

## How NY was left

- **Ready, from the last Prepare** (run 2, loaded 06:48 UTC, 1:48 AM Eastern): 15 packet trades; cases 141 (hero, Pending Analyst), 142 (Escalated), 143 (Resolved - Straight Through). `SO_demoRunState` returns Ready.
- **Its dates are from 1:48 AM.** The hero's cutoff was 4:53 AM Eastern. Reset and Load on the console, or a Prepare through the Dev MCP, before anyone presents.
- The standing cases are dated on the 06:00 UTC clock of 2026-11-12.
- The console is version 12: Load and Reset, the old status line. It will read "Demo loaded … 15 trades · 3 cases".
- No throwaway is left: both `zz` rules return 404, and no case carries session `ZZ-GUARD`.

## Not verified

- **The console and the button press.** Not built. The six lines were read from the rule, not from a page.
- **The documents.** Not changed; they still describe the real prep.
- **What each persona sees.** By ruling; no persona screen or security rule changed.
- **A third Prepare run, a Prepare started from the site, and a Prepare started by another account.**
- **How many comments Reset has left behind.** They cannot be listed over the Dev MCP.
- **A difference between the two screens' value at risk** in renders of the same second (698.4M on the supervisor screen, 662.5M on the watchlist). Seen in the render check, not investigated; neither screen changed this phase.
- **Geometry.** Nothing visual was built.

**Browser checklist.** None owed yet. The four steps in the prompt apply once the button is on the page.

## Records

**Promotion candidates:** 8 found; 0 promoted; 8 listed in `BUILD_LOG.md` with triggers. Of the four staged on 2026-11-11: one resolved (the assertion harness is already in the installed skill), one unchanged, two measured further and kept staged (a failed agent run has no error output on the deployed node type; Write Records inserts a row for a key that no longer exists). New: a Dev MCP record delete cascades to nothing and its orphans read as deleted; Reset's cascade removes one child type and leaves another; `intervalds()` wraps for large hour counts; `text()` prints local time and `gmt()` shifts it; a multi-type write failed loudly where the skill records a silent no-op; a synchronous Start Process returns the child's variables; each node write publishes at once; `maxResponseSizeBytes` did not cut a response.

**TODO changes:** added a "Phase 11, found 2026-11-12" section with nine items (the timing ruling; the console not changed; the documents not changed; Reset's leftover comments; Ready and the age of today's load; a second start in Prepare's first 25 seconds; the state rule reading the packet by prefix; the value-at-risk difference; browser checks owed). Closed: the three skill copies; the "stub" description. Annotated: the "agent OK" check, still open with the console. Unchanged and still open: the stale `BUILD_LOG.md` header checkpoint, under Blocking.

**BUILD_PLAN.md changes:** Phase 11: ticked the state rule with Prepare's refusal, the three standing-case lines and the triage guard; annotated the six console lines as not done or part built; annotated the failed-agent-run and hero-in-Escalated lines with what was read; added two lines (the timing ruling; Reset's leftover comments). Phase 10: ticked the skills line.

**Credits.** Not recorded. This session ran in Claude Code.
