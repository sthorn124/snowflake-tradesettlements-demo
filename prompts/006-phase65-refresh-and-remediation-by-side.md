# Phase 6.5, session 2: Activity without a refresh, and the remediation by side of the trade

This session has two rounds. You build Round 1. Then Scott changes the agent in Agent Studio, because agents are read-only over the Dev MCP. Then you run Round 2 in the same session.

Read the deployed source of an object before changing it. No sail: every check runs through the Dev MCP as the design account, and says so. Probes go on a throwaway copy whose name starts `zz`, never on the live object.

Scott's yes, given here: delete the `zz` design objects this session created, and the cases this session created under the session tag `ZZ-P006` with their comments and events. Nothing else.

## Ruled by Scott, 2026-11-13

Do not ask about these again.

- The remediation texts and codes in Part 2.
- Every Activity entry that states the agent's score says "auto-release score N, releases at 80".
- The promotion candidate from session 1 stays staged in `BUILD_LOG.md`. It is promoted from the template repo, not from this one.
- Not in this session: the resolution card, a "Missed cutoff" line, the penalty figure, hiding the Comment Added event, and the assignee's display name.

## Round 1

### Part 1: Activity shows the new entries without a refresh

**What Scott saw.** After Record Disposition on the hero case, the Disposition Recorded entry appeared in Activity only after he refreshed the page by hand. The demo scripts go from the submit straight to Activity, so this is on the demo path.

A session cannot watch a page redraw, so this cannot be reproduced through the Dev MCP. Work from evidence:

1. Read `SO_recordDispositionCase` from its start form to its end: the order of its writes, and which flows are activity-chained (the setting that keeps the user's page waiting for the next step). Compare the published version with the one before session 1.
2. Check the docs for when a record view redraws after a record action completes.
3. State the cause the evidence supports, and how sure you are. If nothing singles out a cause, change nothing and report.
4. If the same cause holds for `SO_addCommentCase`, `SO_escalateCase` and `SO_assignCase`, fix them the same way and say so.

Pass: Scott's browser check, below.

### Part 2: The remediation depends on the side of the trade

**What is wrong.** `SO_remediationForReason` reads only the fail reason. Every `insufficient_securities` case gets "Arrange cover borrow / partial release", buy or sell. On a buy the seller is the one short of shares, and we would borrow only to cover a delivery of our own.

1. A new rule, `SO_failSide`, answers whose fail it is. The case screen's penalty figure will read it in a later session.

| Fail reason | BUY | SELL |
|---|---|---|
| `insufficient_securities` | theirs | ours |
| `funding_gap` | ours | theirs |
| `operational_error` | ours | ours |
| `counterparty_default` | theirs | theirs |

2. `SO_remediationForReason` gains two optional inputs: the trade's direction and its count of onward deliveries (from `SO_onwardDeliveries`). With no direction it returns exactly what it returns today, so existing callers keep working.

| Fail reason | Direction | Onward deliveries | Remediation | Straight-through code |
|---|---|---|---|---|
| `insufficient_securities` | SELL | any | Arrange cover borrow / partial release | Settled - Borrow Executed |
| `insufficient_securities` | BUY | 1 or more | Arrange cover borrow for onward deliveries / accept partial delivery | Settled - Borrow Executed |
| `insufficient_securities` | BUY | 0 | Accept partial delivery / chase counterparty | Settled - Partial Release |
| `funding_gap` | BUY | any | Treasury funding chase | Settled - Funding Received |
| `funding_gap` | SELL | any | Chase counterparty for funding | Settled - Funding Received |
| `counterparty_default`, `operational_error`, anything else | any | any | as today | as today |

3. Urgency does not change.

Pass, by `testRule`: every row of the table returns its text and code. With no direction, all five branches return what they return today. Then run one triage on a `ZZ-P006` case to confirm the agent, still on version 6, works with the changed rule.

### Part 3: Every lane states the score the same way

The analyst lane's entry says "auto-release score N, releases at 80". The entries `SO_triageCase` writes on the other two lanes still say "confidence 0.30" (nodes 5, 23 and 33).

1. Before changing an entry's wording, find every screen that reads that entry's text and confirm none depends on the old wording.
2. Each of those entries states the score as "auto-release score N, releases at 80", rounded as the screen rounds it. Nothing else in them changes.

Pass: the three entries, composed with test values, quoted in the close-out.

### Part 4: The agent's two changes, written for Scott to apply

1. Write version 7 of the instructions in `agent/instructions.md`. Two changes, and every other line of version 6 stays word for word:
   - Step 5: the agent calls `propose_remediation` with the fail reason, the trade's direction and the number of onward deliveries, each copied from the caseContext.
   - In its assessment the agent writes the fail reason in plain words (insufficient securities, funding gap, counterparty default, operational error). The code is for the tool call only.
2. The agent must be able to copy each tool input from the caseContext as it stands. The onward-deliveries line is a sentence today. Change `SO_caseContext` as little as that needs.
3. Update `agent/tools.md` for the tool's new inputs.
4. Stop. Give Scott numbered steps for Agent Studio: the version 7 text to paste, and the two inputs to add to the `propose_remediation` tool. Say plainly what you cannot see in Agent Studio. Do not run a Prepare.

At this stop NY behaves as it did before the session, apart from Parts 1 and 3.

## Round 2, after Scott says the agent is changed

1. `SO_triageCase` node 11 passes the rule the trade's direction and the onward-delivery count it reads itself. The process is the authority for the text it stores; the agent's tool call gives the agent the same text to reason about.
2. Run the agent's three fixed test cases from `agent/eval.md` (version 6): the clean trade TRD016924 twice, the concerning trade TRD044567 once, and the hero from a Prepare. Create the first two as cases under the session tag `ZZ-P006`, with the fail reason and the hours to cutoff that file records for each. The pass conditions, stated before the run:
   - Clean: resolved straight through, both times.
   - Concerning: escalated, and the assessment states the confirmation lag against the hours remaining, number against number.
   - Hero: held for analyst review, score below 80.
   - Every assessment names the remediation its case stores, and holds no fail-reason code.
   Replicate a wrong-side result before acting on it. If a condition still fails, stop and report. Do not tune the instructions.
3. The 17 standing cases. List the ones whose stored remediation differs from what the rule now returns for their trade. For each, by id: update the stored remediation, and swap the old phrase for the new one in its assessment comment and its events. Do the same for a standing event that states the score as "confidence". Text only, and no deletes. Where an assessment argues for the old remediation in its own words, quote it and leave it.
4. Delete the `ZZ-P006` cases, then finish on a fresh Prepare.
5. Bring the records level: the remediation list in `.kiro/steering/project.md`, line 24 of `hero-trade-spec.md` ("the agent should propose a borrow"), and table B of `agent/eval.md`.

## Verification, on the final Prepare, as the design account

- Hero: the stored remediation is "Accept partial delivery / chase counterparty". The agent's assessment names it and holds no code. Its Activity entry reads "Held for analyst review: auto-release score N, releases at 80 — proposed Accept partial delivery / chase counterparty."
- The escalation story: "Treasury funding chase", and its entries say "auto-release score".
- The straight-through story: its remediation and code are unchanged, and its entries say "auto-release score".
- The console reads "Ready to present".

What each persona should see. A session cannot check these without sail, so they are Scott's:

- `alex.analyst`: the hero's case screen as above.
- `sam.supervisor`: the escalations card reads as it did, with the new wording where it shows an entry's text.

## Operator's browser checklist (Scott)

1. Demo Admin: press Prepare the demo and wait for "Ready to present".
2. Open the SAP GY / Diamond Trust case. Proposed remediation reads "Accept partial delivery / chase counterparty". The agent's text names the same remediation and shows no code such as insufficient_securities.
3. Press Record Disposition, choose Settled - Partial Release, type a note, submit. Do not refresh. Activity shows the Disposition Recorded entry and your note.
4. Open the BATS LN / Horizon Securities case from the Escalated queue. Its Activity entries say "auto-release score" and none says "confidence".
5. Demo Admin: press Prepare the demo again.

## Close-out

Core §10, after Round 2. If Round 2 does not happen in this session, close out Round 1 as partial and say exactly what NY does and does not do.
