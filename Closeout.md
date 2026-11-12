# Closeout — 2026-11-12 — Phase 11 built and verified: triage guard, re-date model, one-button Prepare with a run record, one-status-line console, documents; Ready now ends at the hero's cutoff

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/002-phase11-one-button-setup.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. The session had three rounds. The first built Parts 0 to 4 and stopped, as the prompt says to, when Prepare's synchronous part measured 34 seconds against a limit of 20. Scott then ruled "Start without waiting", and the second round built that, the console and the documents. The second close-out asked whether "Ready" should stop showing once the hero's cutoff has passed; Scott answered "Yes, add it", and the third round built it. This file describes the work as it now stands.

**Scope and identity.** Every Appian call went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`, a direct member of `SO Supervisors` and `SO Demo Admins`. The supervisors' case rule has no condition, so every read below is full-scope. Identity was confirmed by an assertion with a negative control. No sail session was used, by ruling. The runtime server's tools were present and never loaded or called. Helper agents made read-only Dev MCP calls under the same account (a node-type listing, and renders of three screens) and reported what they read.

## Preflight

- **Plan:** populated. **Dev MCP:** design surface present (218 tools counted); `listRecordTypes` returned the 11 record types and User.
- **Versions:** plugin and server 26.9.5, build `20261026-140102`. The pins describe 26.6.105; the App Market has 26.9.15. The update procedure was not run, by ruling. The pack's manifest matches the plugin.
- **Groups, by readback:** `SO Users` holds `SO Administrators`, `SO Analysts`, `SO Supervisors`. `SO Analysts` holds `alex.analyst` and no group. `SO Supervisors` 11 users, `SO Demo Admins` 9.
- **Personas:** every sail session on the machine is expired. None was needed.
- **Ritual:** skipped, by the prompt. Part 2 replaced it.
- **Git:** the local folder was one commit behind `origin/main` and was fast-forwarded first.

## Part 0: skills

| Copy | Before | After |
|---|---|---|
| `~/.kiro/skills/appian-supplemental` (master) | Version 2026-11-10.4 | unchanged |
| `~/.claude/skills/appian-supplemental` | Version 2026-10-28 | Version 2026-11-10.4 |
| `skills/appian-supplemental/SKILL.md` (repo) | Version 2026-10-05.2 | Version 2026-11-10.4 |
| `~/.kiro/skills/appian` (master) | `274ce627` | unchanged |
| `~/.claude/skills/appian` | `eb82064a` | `274ce627` |

The copies are exact. The old `~/.claude` copies were backed up outside the repo first. After the copy the Skill tool still served the supplemental it had cached at session start, so the new file was read from disk; the pack loaded from the new copy.

## What changed on NY

| Object | Version | Change |
|---|---|---|
| `SO_triageCase` | 14.0 → 18.0 | New check "Case still exists?" (node 14) straight after the agent node. If the case is gone, the process ends and writes nothing. Description corrected |
| `SO_intakePlan` | 1 → 2 | Each story carries a console label and its scripted status; a `stories` output hands them on. Intake reads nothing new |
| `SO_standingCaseOffsets` | new, 5 | The standing cases' offsets, in minutes. The one home of them |
| `SO_standingCaseRedate` | new, 1 | The clock, the stamps, the record values, and the ids missing from the site |
| `SO_redateStandingCases` | new, 5.0 | Checks the ids, then writes cases, comments and events on one clock |
| `SO Demo Run` | new record type | One row per press of Prepare: run name, who, when, PREPARING / LOADED / FAILED, the message |
| `SO_demoRunState` | new, 3 | The run's state in seven values, the status line and its colour, and the last failure. Version 3 ends Ready when the hero case's cutoff passes |
| `SO_prepareRun` | new, 4.0 | The part the page waits for: refuse if Running, record the start, hand off, answer |
| `SO_prepareRunSteps` | new, 2.0 | In the background: reset, re-date, load; stops at a failed step; closes the run record |
| `SO_demoAdminConsole` | 12 → 14 | One button, one status line, "Environment OK" / "Environment problem", no agent check |
| Three constants | new | `SO_PM_REDATE_STANDING_CASES`, `SO_PM_PREPARE_RUN`, `SO_PM_PREPARE_RUN_STEPS` |

The three new process models carry `SO_simulateRun`'s security, read back: viewer for `SO Users` and its groups, start rights for `SO Demo Admins`. `SO Demo Run` has the application's default security (viewer for `SO Users` and its groups) and no record-level rule.

**Not changed:** `SO_resetRun`, `SO_simulateRun`, `SO_intakeRun`, every persona screen, every other record type.

**In the repo:** rule sources and model outlines in `.work/`; `.work/gen/` (a reference expander, two rule templates, the check that compares a re-date with the old script); `fixtures/p4-verify-redate.py` marked superseded; `.kiro/steering/project.md`; the three demo documents; the installed skill copy; `BUILD_PLAN.md`, `TODO.md`, `BUILD_LOG.md`, this file.

## How Prepare works now

1. The button starts `SO_prepareRun` and waits for it. It reads `SO_demoRunState`. If the state is Running, it answers "REFUSED: a demo run is being prepared now. …" and changes nothing.
2. Otherwise it writes one `SO Demo Run` row (PREPARING, who, when), starts `SO_prepareRunSteps` in the background, and answers. About 5 seconds.
3. In the background: `SO_resetRun`, then `SO_redateStandingCases`, then `SO_simulateRun`, which starts intake. If a step fails or refuses, the chain stops there. The row is closed as LOADED, or as FAILED with that step's message word for word. About 30 seconds.
4. Intake and triage run as before. Ready comes about 100 seconds after the press.
5. Ready lasts until the hero case's cutoff, about three hours after the load. After that the line reads "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again."

The state reads Running from the press because of the row. Without it, for the half minute in which the last run is cleared, the site holds no packet and no case, and a rule reading data alone said "No demo loaded." and let a second press through.

## Part 1: the triage guard

**Reproduced first, on version 14.0.** A throwaway case (135, session `ZZ-GUARD`, baseline trade `TRD000003`) was deleted while the agent ran. The late writes left the case **re-created under its own id** with status "Pending Analyst", the remediation and a score of 0.88, and no trade, session, fail reason, desk or cutoff; one comment (the 642-character assessment); and two "Agent Triage Complete" events. That is the blank case of 2026-10-22, measured.

**With the guard, version 18.0.** The same test on case 136: the process ended in 28 seconds and wrote nothing. With a parent row put back at that id, the only child was the Case Created event from before the delete.

**A case left alone (137)** ran in 45 seconds and routed straight-through at 0.88, writing the case, the comment and the two events that lane writes. The routing was not changed.

## Part 2: re-dating the standing cases

- **The ids match.** NY holds 17 cases (36 to 52), 12 comments (41 to 52) and 14 events (111 to 124), on the same parents as the script's tables, with no extra row.
- **Same stamps as the script, on two clocks.** After runs on the 06:00 and the 07:00 UTC clocks, all 43 rows stored on NY equal what `fixtures/p4-verify-redate.py` produces for that hour: an exact comparison of 2,720 characters, with a wrong expectation failing as the control.
- **Case 39 is the only standing case past cutoff** after every run that was checked. Before the first, all 17 were, dated 2026-10-23.
- **A second run in the same hour changes nothing.** Four runs wrote the 06:00 clock; the comparison held after each.
- **It stops rather than guess.** A wrong id in the table stopped it before any write, with a message naming the row. Three rows broken on purpose were put right by the next run.
- **It writes times and nothing else.** A standing case a rehearsal has changed keeps the change.
- The script says at its top that it is superseded. `project.md` names `SO_redateStandingCases` as the per-session ritual.

## Parts 3 and 4: the state rule and Prepare

**The part the page waits for:** 4.95, 5.55 and 5.20 seconds on the three runs of the second round, and 4.46 on the one run of the third. The limit was 20. (The first design, with the three steps inside it, took 34.0 and 33.9.)

| | Run A | Run B (forced failure) | Run C | Run D (third round) |
|---|---|---|---|---|
| State at start | Ready | Ready | No demo loaded | Not ready, hero past cutoff |
| Page-facing part | 4.95 s | 5.55 s | 5.20 s | 4.46 s |
| Background half | 31.7 s | 17.6 s, stopped at the re-date | 29.9 s | 37.6 s |
| Run record | LOADED | FAILED, with the re-date's message | LOADED | LOADED |
| Ended in Ready with no other action | yes, by 114 s | no, by design | yes, by 105 s | yes, by 114 s |
| Demo cases after | 3 | 0 | 3, not 6 | 3, not 6 |

- **Straight after the start the state is Running:** 13 seconds into run A, with no packet and no case on the site.
- **A start while a run is in progress is refused:** at that same moment, in 2.2 seconds, with nothing written.
- **After a run:** the hero is "Pending Analyst" with about three hours to cutoff, story 02 is "Escalated", story 03 is "Resolved - Straight Through".
- **After runs A and C:** the standing cases carry today's dates and only case 39 is past cutoff. Not re-checked after run D.
- **A failed step stops the chain and is reported word for word.** In run B the re-date was made to stop; the load did not run, and the record holds "STOPPED: nothing was re-dated. These standing rows are listed in SO_standingCaseOffsets but this account cannot read them on the site: comment 41 on case 37. Either they were deleted, or this account is not in SO Supervisors."
- **A run that dies unlocks itself:** with one story left "New", the state read Running at 239 seconds and Did not finish at 302.

## Ready and the hero's cutoff (third round)

**Reproduced first.** At 9:25 AM Eastern the rule (version 2) still returned "Ready to present. Loaded today at 2:09 AM." The hero case's cutoff had been 5:14 AM. Version 2 on NY was read back and matched the repo copy byte for byte before it was changed.

**The change, `SO_demoRunState` version 3.** The rule reads each demo case's cutoff. When every story is in its scripted status and the hero case's cutoff is at or before now, the state is a seventh value, HERO_PAST_CUTOFF, and the line reads "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again." in amber. The hero is the story labelled `hero` in `SO_intakePlan`'s story table. A story out of place is still reported first. Nothing else in the rule moved, and the console was not edited: it takes its text and colour from the rule.

**Measured through `testRule`, pass conditions written first.** On the 2:09 AM run, whose hero cutoff was 10:14:21 UTC:

| Clock | Returned |
|---|---|
| now, 9:27 AM Eastern | "Not ready. The hero case passed its cutoff at 5:14 AM. Prepare the demo again." Amber |
| 22 seconds before the cutoff | "Ready to present. Loaded today at 2:09 AM." Green |
| 38 seconds after the cutoff | "Not ready. …" Amber |
| tomorrow | "Loaded before today. Prepare the demo again for fresh dates." As before |

**The console rendered the new line** (one `testInterface` render, version 14, no error): the line above in `#96590A`, the button enabled, no "Not prepared" block, "Environment OK", and "Ready to present" nowhere on the page.

**Prepare starts from the new state (run D).** Started while the line read "Not ready", it answered "OK started run=DEMO. …" in 4.46 seconds. The rule read Running four times during the run, once with the packet loaded and no case yet, where the hero has no cutoff to read; it returned with no error. Ready came by 114 seconds: "Ready to present. Loaded today at 9:28 AM." With the clock set past the new hero's cutoff the rule returned "Not ready. The hero case passed its cutoff at 12:34 PM. Prepare the demo again."

## Part 5: the console

Rendered through `testInterface` as the design account, with no error in any render. One button, "Prepare the demo". The verdict reads "Environment OK · data 50,000/50,000 · 9/9 connections". Nothing on the page says "Load the demo", "Reset the demo" or "agent". Details has eight rows and no agent row; "Demo cases" read 3 with a run loaded and 0 without.

| State | Reached how | Line as rendered | Colour | Button disabled |
|---|---|---|---|---|
| Ready | real | "Ready to present. Loaded today at 2:04 AM." | green | no |
| Running | real, 9 s into a run | "Preparing the demo. About two minutes. Refresh this page to check." | neutral | **yes** |
| Nothing loaded | real, after the forced failure | "No demo loaded." | neutral | no |
| Story out of place | real, by setting the hero case to Escalated | "Not ready. The hero case is Escalated, not Awaiting review. Prepare the demo again." | amber | no |
| Did not finish | real, by setting one case back to New and waiting 5 minutes | "The last run did not finish. Prepare the demo again." | amber | no |
| Hero past cutoff | real, seven hours after the 2:09 AM load | "Not ready. The hero case passed its cutoff at 5:14 AM. Prepare the demo again." | amber | no |
| Loaded before today | from the rule only, clock set a day ahead | "Loaded before today. Prepare the demo again for fresh dates." | amber by the rule; not rendered | not rendered |

After the forced failure the page showed, under the button, "Not prepared" in red, the time, and the STOPPED sentence in full. It was gone on the next press.

The two status edits were made on demo cases of an earlier run and put back; that run has since been cleared by Prepare.

**The watchlist and the supervisor screen** rendered with no error after run C. The watchlist showed the hero (`TRD9DEMO01`) under Needs your action at "2h 58m" to cutoff, "Awaiting review", and `TRD9DEMO02` under Escalated; of the ten rows rendered, only the standing past-cutoff case mentioned "past cutoff". The supervisor's escalations grid listed SO-39, SO-43, SO-40 and SO-148. They were not rendered again after run D.

## Part 6: documents

Eleven lines changed across `demo-script-15min-client-awareness.md`, `talk-track-10min-internal.md` and `video-script-5min.md`: every line that named Load or Reset. The prep now reads: open the Demo Admin site; unless the status line says "Ready to present", press Prepare the demo, wait about two minutes, refresh, and confirm "Ready to present"; after a rehearsal or a session, press Prepare again. "Never click Load twice" is gone. In the 15-minute script the recovery line's "About 4 minutes end to end" became "About 3 minutes", since it described the two-button path.

The third round changed none of them. Their rule already covers the new line: anything other than "Ready to present" means press Prepare.

## Rulings given

- **"Start without waiting"** (Scott, 2026-11-12), for how the page starts Prepare.
- **"Yes, add it"** (Scott, 2026-11-12), to: should "Ready" stop showing once the hero's cutoff has passed?

## Rulings needed

1. **Reset leaves each run's assessment comments in the table.** After Reset deleted a demo case, a row put back under the same id showed its comment still stored and its audit events gone. A comment is readable only through its case, so the leftovers are invisible to every account and every count; the 2026-09-09 "comments 14 → 12" was a count of what could be seen. Measured once. Should Reset delete the comments before the cases, and should the rows already left be cleaned up? `SO_resetRun` was not edited.
2. **Should the Ready line name who loaded the demo?** Proposed earlier and not ruled. `SO Demo Run` now stores it.
3. **The words of the new line are mine.** You ruled the behaviour. "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again." follows the story line's pattern. Say so if you want other words.

Still yours from earlier: cancelling the two stuck `SO_triageCase` instances, in Process Monitoring.

## How NY was left

- **Ready, from the last Prepare** (run D, loaded 14:28:53 UTC, 9:28 AM Eastern): 15 packet trades; cases 150 (hero, Pending Analyst), 151 (Escalated), 152 (Resolved - Straight Through). `SO_demoRunState` returned "Ready to present. Loaded today at 9:28 AM."
- **The hero's cutoff is 12:34 PM Eastern.** From then the console reads "Not ready. The hero case passed its cutoff at 12:34 PM. Prepare the demo again." Press Prepare before presenting.
- The standing cases were re-dated by run D, on the 14:00 UTC clock by the model's design. Their stamps were not compared this round.
- `SO Demo Run` holds four rows (ids 1 to 4); id 2 is the forced failure, kept as history.
- No throwaway is left: the four `zz` rules created in the session return 404, and no case carries session `ZZ-GUARD`. The third round created none.

## Not verified

- **The button press, and the page as a person sees it.** `testInterface` cannot press. Prepare was started through `testProcessModel` with the parameter the button passes. Colour, wrapping and the feel of the 5 seconds are browser checks, below.
- **A Prepare started by another account.** By the docs, a presenter needs viewer on `SO_prepareRun` to get its answer back; the role map gives it to `SO Users`.
- **A background half that dies before loading.** The unlock for it is built and was not forced.
- **"Loaded before today" on the page.** Read from the rule only.
- **A story out of place together with a passed cutoff.** The rule tests the story first; that order is read from the source and was not exercised.
- **A hero case with no cutoff stored.** Only the moment with no case yet was seen; the rule returned with no error.
- **The console's Ready render on rule version 3.** The rule's Ready answer was read after run D; the page was last rendered in Ready on version 2.
- **The standing cases and the two persona screens after run D.** Checked after runs A and C only.
- **What each persona sees.** By ruling. No persona screen or security rule changed.
- **How many comments Reset has left behind.** They cannot be listed over the Dev MCP.
- **A difference between the two screens' value at risk** in renders of the same second in the first round (698.4M on the supervisor screen, 662.5M on the watchlist). Not investigated; neither screen changed this phase.
- **Geometry of the console.** The tree carries none.

## Browser checklist (Scott)

As an account in both `SO Demo Admins` and `SO Supervisors`, on https://ny.appiancloud.com/suite/sites/settlement-ops-admin:

1. Press **Prepare the demo**. Within about 5 seconds the status line reads "Preparing the demo. About two minutes. Refresh this page to check." and the button is disabled.
2. Refresh after two minutes. The line reads "Ready to present. Loaded today at <time>", in green, with your local time.
3. The page has one button and one status line, with nothing wrapped or cramped.
4. The watchlist and the supervisor screen look as they did before this phase.
5. About three hours after a Prepare, once the hero's cutoff has passed, refresh. The line reads "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again." in amber, with your local time, and the button is enabled. Today that is any time after 12:34 PM Eastern, if nobody has pressed Prepare since 9:28 AM.

## Records

**Promotion candidates:** 11 found across the three rounds; 0 promoted; 11 listed in `BUILD_LOG.md` with triggers. Of the four staged on 2026-11-11: one resolved (already in the installed skill), one unchanged, two measured further and kept staged. New in the first two rounds: a Dev MCP record delete cascades to nothing and its orphans read as deleted; Reset's cascade removes one child type and leaves another; `intervalds()` wraps for large hour counts; `text()` prints local time and `gmt()` shifts it; a multi-type write failed loudly where the skill records a silent no-op; a synchronous Start Process returns the child's variables; each node write publishes at once; `maxResponseSizeBytes` did not cut a response; a short synchronous model that records and hands off; a marker written before a destructive first step. New in the third: `getExpressionRule` on a UUID that does not exist answered 404 where the skill records 403.

**TODO changes:** the Phase 11 section now holds thirteen items. Closed in the third round: Ready and the age of today's load. Added in the third round: Ready has no margin before the cutoff; a comment in the console's source is one state behind; the story-first order is not exercised. Changed: the browser checklist gained step 5. Closed earlier in the session: the timing ruling; the console; the documents; a second start during a Prepare. Still open: Reset's leftover comments; `SO Demo Run` is never pruned; the state rule reads the packet by prefix; the value-at-risk difference; the browser checklist. In the Phase 10 section, closed: the three skill copies, the "stub" description, the "agent OK" check. Unchanged and still open: the stale `BUILD_LOG.md` header checkpoint, under Blocking.

**BUILD_PLAN.md changes:** Phase 11: every console line, the three standing-case lines, the triage guard and the documents line are ticked; the timing ruling is recorded as found and ruled the same day; the status-line list gained the hero-past-cutoff line; "Ready and the age of today's load" is ticked as ruled and built. One added line stays open: Reset's leftover comments. Phase 10: the skills line ticked.

**Credits.** Not recorded. This session ran in Claude Code.
