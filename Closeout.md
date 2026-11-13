# Closeout — 2026-11-13 — Phase 6.5 session 1: the agent card reads the agent's text, notes show in Activity, event text is fixed at the write, Needs your action sorts by priority; the hero's place is ruled ("Leave it 3rd")

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/005-phase65-case-record-fixes.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. Two rounds: the build, then Scott's ruling on the hero's place. This file is written from where the work stands after both.

**Where NY stands now.** A demo is loaded: "Ready to present. Loaded today at 1:28 PM by Scott Thorn." (18:28:10 UTC). The hero is case 165, Awaiting review, cutoff 21:33:17 UTC. **Ready ends at 2:33 PM Eastern (19:33:17 UTC)**, two hours before that cutoff. Round two wrote nothing to NY.

**The hero is not first in Needs your action, and that is ruled.** Asked whether it should be first, Scott answered **"Leave it 3rd"**. Nothing is changed to move it. Its place depends on the account, because the queue is desk-scoped: 3rd or 4th for an account that sees every desk, and 2nd for `alex.analyst`. Detail under Part 4.

**A correction to what I reported first.** My first close-out gave one rank, 3rd, and put it under `alex.analyst`'s name in the browser checklist. That rank is the design account's, which sees every desk. The planning chat's note in `TODO.md` raised it. `alex.analyst` sees EQ_FLOW rows only; in her queue the hero works out 2nd. The checklist below is corrected.

**Scope and identity.** Every Appian call went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`, confirmed by assertion (`loggedInUser()` equal to that name validated clean; the same check with another name failed). Direct member of `SO Supervisors`, `SO Demo Admins` and `SO Users`, so every read below is full-scope. No sail, by the prompt. The runtime server's tools were present and never loaded or called. One helper agent made read-only reads of six process models under the same account.

## Preflight

- **Plan:** populated. **Dev MCP:** 218 tools, design families present; `listRecordTypes` returned the application's 12 record types and User.
- **Versions:** plugin and server 26.9.5, build `20261026-140102`. The pins describe 26.6.105; sail here is 26.9.5; the App Market has 26.9.15. The update procedure was not run. Bundle paths for NY: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` and `https://ny.appiancloud.com/suite/plugins/servlet/stateless/dev-mcp-bundle`.
- **Skills:** `appian-supplemental` Version 2026-11-10.4; the repo copy and the installed copies are byte-identical. The pack's manifest, `274ce627`, matches the plugin. Pack references read: `process-models.md`, `tools-mcp.md`, `interface-generation-checklist.md`, `layouts/sidebyside-layout-instructions.md`, `expression-rules.md`. Docs-search was consulted on XOR gateways with more than one incoming flow. No layout or styling parameter was added or changed on any screen: a note in Activity reuses the event entry's components as they were, so the layout docs gate had no parameter to settle.
- **Groups, by readback (direct members):** unchanged. `SO Users` holds `SO Administrators`, `SO Analysts`, `SO Supervisors` and two users; `SO Analysts` holds `alex.analyst`; `SO Supervisors` 11 users; `SO Demo Admins` 9 users.
- **Personas:** every sail session on the machine is expired. None was used.
- **Ritual:** Prepare had run today (Scott, 16:03 UTC), so the re-date was not run on its own. Both Prepares of this session ran it.
- **Git:** the local folder was five commits behind `origin/main` at the start and was fast-forwarded. Before round two it was one behind (`1e14c30`, the planning chat's TODO note and a new item for the demo documents) and was fast-forwarded again. The prompt was already banked as `prompts/005`.

## What changed on NY

| Object | Version | Change |
|---|---|---|
| `SO_caseDetail` | 13 → 14 | The agent card reads the newest comment the agent wrote. People's notes are entries in Activity |
| `SO_analystWatchlist` | 25 → 26 | Needs your action sorts by priority. The preview reads the agent's comment only. Description brought level with the hidden third queue |
| `SO_supervisorCommand` | 11 → 12 | Both "USD eq." tiles carry the conversion note, which names no currencies |
| `SO_triageLane` | new, 1 | The one definition of the triage routing |
| `SO_triageCase` | 18.0 → 22.0 | Nodes 4, 5, 12 and 43: one triage entry on the analyst lane; the fail reason as its display label |
| `SO_createTriageCase` | 5.0 | Node 7: the fail reason as its display label |
| `SO_recordDispositionCase` | 6.0 | Node 4: no username tail |
| `SO_addCommentCase` | 7.0 | Node 4: no username tail |
| `SO_escalateCase` | 6.0 | Node 4: no username in the text |
| `SO_assignCase` | 9.0 | Node 3: no username tail |

**Not changed on NY:** `SO_casePriority`, `SO_watchlistPreviewRail`, `SO_remediationForReason`, the agent, `SO_demoAdminConsole`, `SO_demoRunState`, every record type, group and membership, and every standing-case row.

**Saved copy of `SO_caseDetail`.** The deployed version 13 was byte-identical to the saved copy of 2026-09-24. Nothing differed. The same held for the watchlist, the preview rail and the supervisor screen.

## Part 1: the agent card shows only the agent's text

**Reproduced first.** On demo case 159, a disposition with a note through `SO_recordDispositionCase`. The case screen then read "SO Triage Agent · 13 Nov 13:05" over the note, and the note was not in Activity. The watchlist's preview did the same on a throwaway copy of version 25: "SO Triage Agent · 13:13" over a person's comment.

**What tells the two apart.** `author`. `SO_recordDispositionCase` node 5, `SO_addCommentCase` node 3 and `SO_escalateCase` node 5 write `pp!initiator`. `SO_triageCase` writes null. On NY: 15 comments with no author (all 12 standing, 3 from the loaded run) and 1 with one. The query filter was checked by assertion, with a control that failed.

**The fix.** Both screens add `author` `is null` to the assessment query.

**Pass.** On the hero of the verification run (case 162), after a person's comment and then a disposition note: the agent card read "SO Triage Agent · 13 Nov 13:23" over the agent's assessment, and the preview read "SO Triage Agent · 13:23" over the same. A case with no agent comment (standing case 37) rendered leaf for leaf as before: 3,048 leaves, 0 differences. So did standing case 36, which has one: 3,810 leaves, 0 differences.

## Part 2: a person's note shows in Activity

Activity is one list: the case's events and its comments that have an author, newest first. A note is built the way an event is: a USR chip, the title "Note", the time and the writer's first and last name, and the text.

**Pass.** After Record Disposition with a note and after Add Comment, on case 162:

- "Disposition Recorded · 13 Nov 13:25 · Scott Thorn" / "Disposition: Settled - Partial Release"
- "Note · 13 Nov 13:25 · Scott Thorn" / the disposition note
- "Comment Added · 13 Nov 13:25 · Scott Thorn" / "Comment added"
- "Note · 13 Nov 13:25 · Scott Thorn" / the comment

**Standing cases that gained entries: none.** All 12 standing comments are the agent's.

## Part 3: the text of Activity entries

**Every process model that writes event text**, read on NY:

| Model, node | Entry | Text now |
|---|---|---|
| `SO_createTriageCase` 7 | Case Created | "Case created from feed for trade <trade> (<reason label, lower case>, desk <desk>)" |
| `SO_triageCase` 5 | Agent Triage Complete, escalate and straight-through lanes | "Agent assessed <reason label, lower case>; proposed <remediation> at confidence 0.00" |
| `SO_triageCase` 43 | Agent Triage Complete, analyst lane | "Held for analyst review: auto-release score N, releases at 80 — proposed <remediation>." |
| `SO_triageCase` 23 | Escalated, by the process | "Escalated by policy: <label> — …" or "Escalated by agent: <label> — …" (unchanged) |
| `SO_triageCase` 33 | Straight-Through Resolution | "Straight-through: <remediation> \| confidence 0.00 >= threshold 0.80 \| disposition <code> \| resolved before cutoff without analyst review" (unchanged) |
| `SO_recordDispositionCase` 4 | Disposition Recorded | "Disposition: <code>" |
| `SO_addCommentCase` 4 | Comment Added | "Comment added" |
| `SO_escalateCase` 4 | Escalated, by a person | "Escalated: <reason typed>" |
| `SO_assignCase` 3 | Assigned | "Assigned to <assignee>" |

The other six models write no event text (a helper agent read all their nodes). `SO_redateStandingCases` writes an event's id and time only.

**The duplicate.** The pre-route entry (node 5) ran on every lane, so the analyst lane wrote two "Agent Triage Complete" entries. The routing is now the rule `SO_triageLane`, read by the Route gateway and by node 4, which sends an analyst-lane case past node 5. Node 43 writes the lane's one entry, after the lane's writes succeed. The rule returned the same lane as the old conditions on all 972 input combinations tried.

**The other two lanes** write two entries with different titles. That is not the duplicate the prompt names. Reported and left.

**The standing cases' 14 events.** None holds a stored fail-reason code and none ends in "by" and a username. None was updated and none was deleted. Event 113 reads "Assigned to alex.analyst from the EQ_FLOW watchlist."; the username names the assignee and is not a tail, so it was left.

**Pass: the three demo cases' entries on the Prepare that NY now holds (cases 165, 166, 167):**

- Hero, 165: "Case created from feed for trade TRD9DEMO01 (insufficient securities, desk EQ_FLOW)"; "Held for analyst review: auto-release score 68, releases at 80 — proposed Arrange cover borrow / partial release." One "Agent Triage Complete" entry.
- Escalation, 166: "Case created from feed for trade TRD9DEMO02 (funding gap, desk EQ_FLOW)"; "Agent assessed funding gap; proposed Treasury funding chase at confidence 0.30"; "Escalated by policy: funding gap — broker confirmation lag 26.0h against 2.4h remaining, so the remediation cannot complete inside the window. Agent confidence 0.30; the breached window decides this case whatever the score."
- Straight-through, 167: "Case created from feed for trade TRD9DEMO03 (operational error, desk EQ_FLOW)"; "Agent assessed operational error; proposed Correct & resubmit at confidence 0.87"; "Straight-through: Correct & resubmit | confidence 0.87 >= threshold 0.80 | disposition Settled - Corrected | resolved before cutoff without analyst review".

No stored fail-reason code and no username tail in any of the eight.

## Part 4: Needs your action sorts by priority

**The order.** Rows inside their window first, highest priority first, ties by earliest cutoff; rows past cutoff after them. The caption reads "sorted by priority". The short view reads "showing top 6 by priority", and its link "Show top 6". The Escalated queue's order is unchanged, and `SO_casePriority` was not edited.

- **The short view's cut** is still the first six rows of the queue's order.
- **The preview has no default row.** It opens on "Select a row to review the case", as before.

**Pass.** Old and new source rendered side by side with view-all on, as the design account: the same 11 rows as a set, in a different order. Outside the rows, 2 of 2,644 leaves changed: the caption and the link. The tiles, the band and the Escalated queue did not change.

**Where the hero ranks.** Worked out from the cutoffs and probabilities read on NY. A copy of the rule's arithmetic agreed with the rule on 12 of 12 rows, and the queue rendered as the design account at 18:25 UTC was in the same order. The standing cutoffs are pinned to the hour and the hero's is 3 hours 5 minutes after the load, so the rank moves with the minute Prepare is pressed.

| Account | At the load | 65 minutes after it |
|---|---|---|
| Sees every desk: your own account, `sam.supervisor`, the design account (12 rows) | 3rd if Prepare is pressed in minutes 00 to 29 of the hour; 4th in minutes 30 to 59 | 4th or 5th |
| `alex.analyst`, EQ_FLOW only (9 rows) | 2nd on any load, below ULVR LN (TRD030639, priority 75) | 2nd or 3rd |

- **The hero's own priority is 66** until it has under two hours to cutoff.
- **Above it for an all-desk account at the load:** TRD030639 at 75 and TRD026551 at 68, and in the second half of the hour TRD005533 at 81.
- **The run NY holds now** (18:28 UTC): 3rd under an all-desk account, 2nd as `alex.analyst`.
- **Which rows are EQ_FLOW** was read on NY in round two: of the 12 open rows, 9 have a trade on desk EQ_FLOW and 3 do not (TRD026551 on FI_TRADING, TRD005533 on FX_DESK, TRD040366 on ETF_MM). Checked by assertion, with a control that failed.

**Ruled by Scott: "Leave it 3rd".** `SO_casePriority`, the standing cases and the hero's cutoff are not edited to move it.

## Part 5: riders

1. **`SO_supervisorCommand`.** The Value at risk tooltip and the Inside critical window tooltip are the watchlist's note: "Cross-currency total: nothing in the source data carries an FX rate. Converted at indicative static rates (SO_fxToUsd) for aggregation only — not a market feed, not a rate of record." Rendered before and after: 7 of 5,422 leaves changed, the 2 tooltips and 5 clock values.
2. **The three demo documents.** One sentence added to each prep step: "refresh the page first, since a page left open shows the status it loaded with." One line changed in each file.

## Verification: one run on a fresh Prepare, as the design account

The load of 18:22:31 UTC (cases 162, 163, 164).

1. **The hero's case screen.** Agent card: the agent's assessment, "13 Nov 13:23". Activity: one "Agent Triage Complete" entry ("Held for analyst review: auto-release score 62, releases at 80 — proposed Arrange cover borrow / partial release.") and "Case created from feed for trade TRD9DEMO01 (insufficient securities, desk EQ_FLOW)".
2. **A disposition on the hero,** Settled - Partial Release, with a note.
3. **The case screen again.** The agent card unchanged. The note in Activity under "Scott Thorn". The disposition entry reads "Disposition: Settled - Partial Release".
4. **The watchlist.** The order of Part 4, all desks. **The preview for the hero was read before step 2,** because a resolved case leaves the queue and cannot be selected. It showed the agent's assessment, and still did after a person's comment was added to the hero.
5. **The supervisor screen.** Error null. Two tooltips carry the note. No list of currencies anywhere in the render.

All three lanes ran live on both Prepares, with the three stories in place each time.

## Not verified

- **What `alex.analyst` and `sam.supervisor` see.** No sail session was live. Every render above is the design account's. `alex.analyst`'s rank for the hero is worked out from the security rule and the data, not seen.
- **Geometry:** how the longer Activity list and a long note wrap, the hover on the two tiles, the look of the queue.
- **The forms and the record header's actions.** The tests started the process models directly.
- **Three written paths that did not run live:** node 43's two other wordings (the score clears the gate and the reason has no straight-through disposition; the score clears the gate and the cutoff has passed), and node 4's failed-write path. The wordings were composed with test values and matched.
- **The hero's rank at 65 minutes** is worked out, not rendered at that time.

## Operator's browser checklist (Scott)

1. Demo Admin: press **Prepare the demo** and wait for "Ready to present".
2. Watchlist: the Needs your action caption reads "sorted by priority". **As `alex.analyst`,** SAP GY / Diamond Trust is the **2nd row**, below ULVR LN. **Under your own account,** it is the 3rd row if you pressed Prepare in the first half of the hour and the 4th if in the second half; above it are ULVR LN, GBPUSD 1M FWD, and in the second half of the hour GBPSEK 1M FWD.
3. Open that case. Press Record Disposition, choose Settled - Partial Release, type a note, submit.
4. The same case: the agent card still shows the agent's reasoning. Activity shows your note as an entry titled "Note" under your name. The disposition entry reads "Disposition: Settled - Partial Release" and does not end in "by" and a username. No entry shows a fail reason as a code, such as insufficient_securities; desk codes such as EQ_FLOW are expected. There is one "Agent Triage Complete" entry.
5. Supervisor, as `sam.supervisor`: hover the Value at risk tile. The note gives the conversion basis and lists no currencies. The Inside critical window tile has the same note.
6. Demo Admin: press **Prepare the demo** again.

## Ruled this session

- **The hero's place in the queue: "Leave it 3rd"** (Scott, 2026-11-13). Recorded in `.kiro/steering/project.md` (Working style, the priority order), with the rank under each account.

## Rulings still needed

1. **Add Comment and a person's Escalate show two entries for one act:** the event and the note. The escalation reason reads twice, and "Comment added" repeats its entry's title. Options: hide the Comment Added event on the screen, shorten the event text, or leave both.
2. **"Assigned to alex.analyst"** still shows the assignee as a username. I dropped the acting person's tail and left the assignee.
3. **The escalate and straight-through lanes** still write two triage entries with different titles and still say "confidence 0.30", where the analyst lane now says "auto-release score 68, releases at 80".
4. **One promotion candidate passes the five gates and was not written into the skill.** `getExpressionRule` returns 404 for a rule that does not exist and 403 for a UUID that is another kind of object, which contradicts the supplemental. The merge script the skill names, `.kiro/scripts/skill_merge.py`, is not in this repo, and the three copies of the skill are byte-identical today. Say how a promotion is to be written from this build.

## Decisions I made

- **The lane logic became a rule, `SO_triageLane`,** because two gateways now need it. Node 4 sends the analyst lane to the lane's first write, not to the Route gateway: the docs say only one path should enter a gateway.
- **The acting user's name left four event texts, not one.** The prompt names the disposition entry and says to list every write and fix each; three other models wrote the same tail.
- **The analyst lane's entry uses the screen's vocabulary,** "auto-release score N, releases at 80", and rounds as the screen does.
- **A note's title is "Note".**
- **Two things were left though their TODO triggers named these edits:** the watchlist's Value column sort and the case screen's inline risk-tier casing. The prompt kept the rest of both renders unchanged.

## Other findings

- **A demo document is behind the build.** `video-script-5min.md` line 47 narrates "sorted by time to cutoff"; the caption now reads "sorted by priority". Not changed: the prompt allowed one sentence per document. The planning chat's TODO item lists it for after your check.
- The agent's own assessment can hold a stored code: "Fail reason is insufficient_securities" (hero run of 18:23 UTC). It is the agent's text; its instructions were not in this session.
- The agent's score for the hero moved between runs: 0.62 at 16:04 and 18:23 UTC, 0.68 at 18:29 UTC. All below the gate.
- The resolved hero's case screen still shows a live countdown. Already a Phase 6.5 item.
- `SO_prepareRun` stored state STORY_OUT_OF_PLACE at 18:22 and 18:27 UTC, with the hero resolved by a test and inside the two-hour margin: the story test comes before the margin, as designed.
- Lint on `SO_triageLane`: no saved test cases, and "Duplicate role map entry detected". Not looked into.
- This session's tests left 12 more comments in the table, hidden, because their cases are gone. The open Reset item carries it.

## Throwaway objects

Created and deleted this session, on the prompt's yes: interfaces `zz_SO_caseDetail_005`, `zz_SO_analystWatchlist_005` and `zz_SO_analystWatchlist_005_old`, and rule `zz_SO_p005_openRows`. After the deletes both `zz` listings were empty and a get on each UUID returned HTTP 404. Nothing else was deleted.

## Promotion candidates

Three considered; none promoted; three listed. One passes the gate and waits on ruling 4. Two are new and staged on one observation each: `testProcessModel` passes a username to a User-typed parameter, and `updateProcessModelNode` publishes a model version on every call. Checkpoint: current through this session's second entry.

## TODO changes

Round one: added a section for this session with nine items; closed four (the supervisor tooltip, the watchlist's description of three queues, the stale `SO_triageCase` description, the escalate node's raw fail reason); annotated five (the Reset leftovers, the story-out-of-place check, the Value column sort, the risk-tier casing, the line numbers in the constants item). Round two: the hero item is struck through with a pointer to the ruling; step 2 of the browser check gives the rank under each account; the planning chat's item for the demo documents carries the hero's place for its line 3.

## BUILD_PLAN changes

Six Phase 6.5 items ticked in round one (the five under "Agent card and Activity panel" and the watchlist's sort). In round two the hero-rank item is ticked as checked and ruled. Five new items under "Found in session 1". The personas section says what each persona should see from today, with `alex.analyst`'s rank for the hero. Order item 3 notes that session 1 is built and Scott's check is owed.

## Files changed in the repo

`.work/SO_caseDetail.sail`, `.work/SO_analystWatchlist.sail`, `.work/SO_supervisorCommand.sail`, `.work/rule_SO_triageLane.sail` (new), `.work/pm_SO_triageCase.md`, the three demo documents, `.kiro/steering/project.md` (four rules, one carrying the ruling), `BUILD_PLAN.md`, `BUILD_LOG.md` (two entries), `TODO.md`, `Closeout.md`.
