# Phase 6.5, session 1: the case's record reads correctly

Four fixes and two one-line riders. No new layout in this session. Read the deployed source of an object before changing it. No sail this session: every check runs through the Dev MCP as the design account, and says so.

Probes go on a throwaway copy whose name starts `zz`, never on the live object. Scott's yes, given here: delete the `zz` objects this session created, and nothing else.

The saved copy of `SO_caseDetail` is from 2026-09-24. Save the deployed source over it before editing and note what differed.

## Part 1: The agent card shows only the agent's text

**What Scott saw (2026-09-25).** After Record Disposition with a note, the note appeared in the case screen's agent card, under "SO Triage Agent", in place of the agent's reasoning. In the saved source the card takes the newest comment on the case, whoever wrote it. `SO_triageCase` writes the agent's comment with `author` null.

1. Reproduce first. With a demo loaded (run `SO_prepareRun` through `testProcessModel` if none is), record a disposition with a note on the hero case through `SO_recordDispositionCase`, render the case screen, and confirm the note is in the agent card.
2. Read on NY what `SO_recordDispositionCase` and `SO_addCommentCase` write to `author`. If nothing reliable tells a person's comment from the agent's, stop and report.
3. The agent card shows the newest comment the agent wrote, and no other. Apply the same fix wherever a screen takes the newest comment as the assessment. The watchlist's preview panel does.

Pass: on a case with an agent assessment and a later note from a person, the agent card and the watchlist's preview show the agent's assessment with the agent's run time. A case with no agent comment renders as it did before.

## Part 2: A person's note shows in Activity

**What Scott saw.** The note is saved as a case comment and never appears in the Activity panel, which reads case events only.

1. Activity shows the comments people wrote, in time order with the events, each under the writer's display name and time.
2. The agent's comments stay out of Activity. They are in the agent card.
3. A note is one more entry in the existing list, built the way an event entry is.

Pass: after Record Disposition with a note, and after Add Comment, the note is in Activity at its time under the writer's name. Say which standing cases gained entries, and how many.

## Part 3: The text of Activity entries

Three defects in the text the process models write to the case's events:

- **Stored codes.** "Case created from feed for trade … (insufficient_securities, desk EQ_FLOW)" and the "Agent assessed …" entry show the stored fail reason. The project rule: event text uses the display label from `SO_failReasonDisplay`, lower-cased into the sentence. Desk codes stay as they are.
- **Username tail.** "Disposition: … by scott.thorn@appian.com". The entry's header already names the person. Drop the tail.
- **Duplicate entry.** On the analyst lane, `SO_triageCase` writes two entries titled "Agent Triage Complete" in the same minute: "Agent assessed …" (node 9) and "Referred to analyst: …" (node 43). Make it one entry that states the decision (held for analyst review), the score against the gate, and the proposed fix. If the escalate or straight-through lane has the same duplication, report it and leave it.

1. List every process model that writes event text, with the text each writes.
2. Fix each at the write.
3. The 17 standing cases' stored events: list the ones that hold a stored code or a username tail, and update the text of those by id to read as the process now writes it. Text only. Do not delete a standing-case event: `SO_redateStandingCases` checks all 14 event ids before it writes and stops if one is missing.

Pass: on a freshly prepared demo, the three demo cases' Activity entries hold no stored fail-reason code and no username tail, and the hero has one "Agent Triage Complete" entry. Quote the entries in the close-out.

## Part 4: Needs your action sorts by priority

**What Scott saw.** The queue sorts on time to cutoff alone, so low-risk rows with earlier cutoffs, and rows already past cutoff, sit above the hero. Each row already carries `priority` (from `SO_casePriority`, risk times time to cutoff) and `isPast`. `SO_casePriority` gives a row past its cutoff the highest urgency, so a plain priority sort would put those rows first.

1. Order: rows still inside their window first, highest priority first, ties by earliest cutoff. Rows past cutoff come after them.
2. The caption "sorted by time to cutoff" becomes "sorted by priority". The "nearest cutoffs" wording on the short view follows the new order. Check that the short view's cut and the preview's default row still do what their labels say.
3. The Escalated queue's order does not change. `SO_casePriority` is not edited.
4. Report where the hero ranks with a demo loaded, at the load and 65 minutes after it. Work the second one out from the cutoffs. If the hero is not first, list the rows above it with their priority and stop there. Do not change the rule or the standing cases to move it.

Pass: the rendered queue is in the order of step 1. Apart from order, caption and that wording, the watchlist renders as it did before: the same queues, counts, rows and tiles.

## Part 5: Two riders

1. `SO_supervisorCommand`: the Value at risk tooltip names four currencies. The project rule is that a tooltip states the conversion basis and names no list of currencies. Give it the watchlist's conversion note, and give the critical-window tile the same note. Nothing else on that screen changes.
2. The three demo documents in the repo root: in each one's prep step, add one short sentence telling the presenter to refresh the Demo Admin page before reading the status line. Change no other line in them. The planning chat removes their workaround lines after Scott's check.

## Not in this session

The resolution card, a "Missed cutoff" line, the remediation rule, the agent's instructions, and the Snowflake packet.

## Verification

One run, on a fresh Prepare, as the design account:

1. The hero's case screen: the agent card shows the agent's assessment, and the Activity entries read as Part 3 requires.
2. Record a disposition on the hero, Settled - Partial Release, with a note.
3. The case screen again: the agent card is unchanged; the note is in Activity under the writer's name; the disposition entry has no username tail.
4. The watchlist: the order of Part 4, and the preview for the hero shows the agent's assessment.
5. The supervisor screen renders with no error and the two tiles carry the note.

What each persona should see after this build. A session cannot check these without sail, so they are Scott's, below:

- `alex.analyst`: the watchlist's new order, and the hero's case screen as in steps 1 to 3.
- `sam.supervisor`: the supervisor screen's tooltip.
- The presenter's own account: the Demo Admin console is unchanged.

## Operator's browser checklist (Scott)

1. Demo Admin: press Prepare the demo and wait for "Ready to present".
2. Watchlist: the Needs your action caption reads "sorted by priority", and SAP GY / Diamond Trust sits where the close-out says it will.
3. Open that case. Press Record Disposition, choose Settled - Partial Release, type a note, submit.
4. The same case: the agent card still shows the agent's reasoning. Activity shows your note under your name, and the disposition entry does not end in "by" and a username. No entry shows a code with an underscore in it. There is one "Agent Triage Complete" entry.
5. Supervisor: hover the Value at risk tile. The note gives the conversion basis and lists no currencies.
6. Demo Admin: press Prepare the demo again.

## Close-out

Core §10. Update the plan's personas section if what a persona sees changed. Finish on a fresh Prepare, so the hero is back in Awaiting review, and say when Ready ends.
