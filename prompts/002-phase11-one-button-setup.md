# Phase 11: one-button demo setup

Build the Phase 11 scope in `BUILD_PLAN.md`. The facts to build on are in `Closeout.md` of 2026-11-11 ("Inputs for Phase 11") and the outlines in `.work/pm_*.md`. Read the deployed source of an object before changing it.

## Rulings (Scott, 2026-11-12)

- No blank cases are left on NY, so nothing is deleted for them.
- The triage routing does not change. The agent's `escalate` flag keeps its path.
- The console drops its "agent OK" check.
- The copies of `appian-supplemental` and `appian` under `~/.kiro/skills/` are the master copies.
- The Dev MCP update procedure is not run this session.
- Deletes: Scott's yes is given here for cases this session creates with session id `ZZ-GUARD`, and for design objects this session creates with a `zz` prefix. For anything else, stop and ask.

## Part 0: Start

1. Run the preflight as the rules require. Skip the fixture re-date ritual: Part 2 replaces it.
2. Skills. Copy `~/.kiro/skills/appian-supplemental` and `~/.kiro/skills/appian` over the copies in `~/.claude/skills/`. Copy the `appian-supplemental` `SKILL.md` into `skills/appian-supplemental/` in the repo. Report each version line before and after, then load both skills from the new copies. If the `~/.kiro` copies cannot be read, stop.

## Part 1: The triage guard (`SO_triageCase`)

1. Reproduce first, on the current version. Create one throwaway case (session id `ZZ-GUARD`, on a real baseline trade), start triage on it, and delete the case while the agent is running. Record exactly what the late writes leave behind: case row, comment, events. Clean up and prove it by absence.
2. Add one check immediately after the agent node, before anything reads or writes the case: does the case still exist? If it does not, the process ends and writes nothing.
3. Repeat the test from step 1. Pass: no case row, no comment, no event, and the process has ended. Then run one case that is not deleted, and confirm it routes and writes as it did before.
4. Correct the model's description, which still says "stub".

## Part 2: Re-dating the standing cases

1. New process model `SO_redateStandingCases`. It moves the 17 standing cases, their 12 comments and their 14 events to offsets from now, exactly as `fixtures/p4-verify-redate.py` does: the same offsets, the same single clock rounded down to the hour, the same rule that triage comes before cutoff, and a resolved time only on cases 41, 42 and 50. The offsets live in one expression rule. Every write names its ids. Nothing is selected by query.
2. Before the first write, confirm the script's id lists match NY. If they differ, stop and report.
3. Pass: after a run, every case, comment and event time equals what the script produces for the same hour. Case 39 is still past cutoff. A second run in the same hour changes nothing.
4. The script and its three CSVs are superseded. Say so at the top of the script. In `.kiro/steering/project.md`, change the Per-session ritual build parameter and the Repeatability section to "run `SO_redateStandingCases`".

## Part 3: One rule for the run's state

New expression rule `SO_demoRunState`. The console and Prepare both read it. It works from data the processes already write (`Closeout.md`, input 3) and returns one of six states:

| State | When |
|---|---|
| Nothing loaded | No `TRD9` trades and no cases tagged with the run name |
| Loaded before today | The load stamp's date is not today |
| Running | Loaded today, not every story has an agent decision, and the load stamp is under 5 minutes old |
| Did not finish | Loaded today, not every story has a decision, and the load stamp is 5 minutes old or more. Also any partly loaded state that fits no other row |
| Story out of place | Every story has a decision, and at least one is not in its scripted status |
| Ready | Every story has a decision, and each is in its scripted status |

- A story has its decision when its case's status is neither "New" nor "Agent Triage".
- Scripted statuses: story 01 "Pending Analyst", story 02 "Escalated", story 03 "Resolved - Straight Through". Add them to the story table that already defines the three stories (`SO_intakePlan`). Do not write the story list a second time.
- Demo cases are the cases tagged with the run name. A case with any other session id, or none, is not counted.

## Part 4: Prepare (`SO_prepareRun`, new process model)

In order: refuse if the state is Running; then `SO_resetRun`; then `SO_redateStandingCases`; then `SO_simulateRun`, which starts intake. `SO_resetRun` and `SO_simulateRun` are called as they are and are not edited. If a step fails or refuses, stop there and return that step's message. Give both new models the same security and start rights as `SO_simulateRun`.

Pass: the part of Prepare that the page waits for finishes in under 20 seconds on three runs. If it does not, stop and report. Do not redesign.

## Part 5: The console (`SO_demoAdminConsole`)

1. One button, "Prepare the demo", starts `SO_prepareRun`. The Load and Reset buttons, their captions and their result lines leave the page. A failure or refusal message from Prepare shows in full, word for word.
2. The button is disabled only in the Running state.
3. One status line. This copy is the contract:
   - Nothing loaded: "No demo loaded."
   - Running: "Preparing the demo. About two minutes. Refresh this page to check."
   - Ready: "Ready to present. Loaded today at <time>."
   - Loaded before today: "Loaded before today. Prepare the demo again for fresh dates."
   - Did not finish: "The last run did not finish. Prepare the demo again."
   - Story out of place: "Not ready. The <hero | escalation | straight-through> case is <its status>, not <its scripted status>. Prepare the demo again." Statuses render through `SO_statusDisplay`.
4. Ready is green. Nothing loaded and Running are neutral. The other three are amber. `<time>` is in the presenter's time zone.
5. The top line's verdict word changes from "Ready" / "Not ready" to "Environment OK" / "Environment problem", so the page has one "Ready". Remove "agent OK" from that line and the agent check from Details.
6. Wherever the console counts demo cases, it counts cases tagged with the run name.
7. No progress bar. No page that refreshes itself. No other change to the page.

## Part 6: Documents

After the build is verified, change only the lines that name the two buttons in `demo-script-15min-client-awareness.md`, `talk-track-10min-internal.md` and `video-script-5min.md`. The new prep is: open the Demo Admin site; unless the status line says "Ready to present", press Prepare the demo, wait about two minutes, refresh, and confirm "Ready to present". After a rehearsal or a session, press Prepare again. Drop "never click Load twice".

## Verification

No sail this session (Scott, 2026-11-12). Every check runs through the Dev MCP as the design account, and says so.

Prepare, run through `testProcessModel`:
- One run, from whatever state NY is in, ends with `SO_demoRunState` returning Ready, with no other action. Record the seconds from start to Ready.
- Straight after the start, the state is Running.
- A second run from Ready ends at Ready again, with three demo cases and not six.
- A start while a run is in progress is refused.
- After a run: the hero case is "Pending Analyst" with about three hours to cutoff, story 02 is "Escalated", and story 03 is "Resolved - Straight Through".
- After a run: the standing cases carry today's dates, and only case 39 is past cutoff.

The console, rendered through `testInterface`:
- It shows the copy for the state NY is in, and the button is disabled only when that state is Running.
- Each of the six states shows its copy. Reach them through real states where that is cheap. Say which were reached and which were only read from the rule.

The watchlist and the supervisor screen render without an error after a Prepare.

Not verified, by ruling: what each persona sees, and the button press itself. Phase 11 changes no persona screen and no security. The press is Scott's, below.

Operator's browser checklist (Scott):
1. On the Demo Admin site, press Prepare the demo. The page shows the Running line and the button is disabled.
2. Refresh after two minutes. The line reads "Ready to present. Loaded today at <time>", in green, with the local time.
3. The page has one button and one status line, with nothing wrapped or cramped.
4. The watchlist and the supervisor screen look as they did before this phase.

## Close-out

Core §10. Leave NY in the Ready state from the last Prepare, and say so. In `BUILD_PLAN.md`, tick what was built in Phase 11.
