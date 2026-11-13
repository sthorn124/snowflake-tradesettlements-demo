# Closeout — 2026-11-13 — Phase 6.5 session 2, round 1 of 2 (partial): built and stopped for Scott's Agent Studio step; round 2 is owed

This is a partial close-out. `prompts/006` has two rounds with Scott's Agent Studio step between them. Round 1 is built, tested and pushed. Round 2 has not started. If round 2 runs in the same session, this file is rewritten whole at its end.

The session ran in Claude Code. The `credits.py` step was skipped, because `CREDITS.md` is built from Kiro's own records.

## Scope and identity

- Prompt: `prompts/006-phase65-refresh-and-remediation-by-side.md`, round 1 (Parts 1 to 4).
- Every Appian call went through the Dev MCP (server `appian`, 218 tools, plugin and server 26.9.5, build `20261026-140102`) as `scott.thorn@appian.com`. `loggedInUser()` was asserted equal to that account, and the control with another name failed. The account is a direct member of `SO Supervisors` (full scope), `SO Demo Admins` and `SO Users`, read back this session.
- No sail, by the prompt. Every persona session on the machine is expired. Nothing was read as `alex.analyst` or `sam.supervisor`.
- The runtime server's tools were never loaded or called.
- Prepare had run today (Scott, 22:00:38 UTC, cases 171 to 173). This round ran no Prepare. That run's Ready line ends at 23:05:45 UTC, two hours before the hero's cutoff.
- Preflight flags, both already open in `TODO.md`: the Dev MCP is 26.9.5 against the pin 26.6.105 (26.9.15 is on the App Market), and sail is 26.9.5 against its pin.

## What NY does now, and what it does not

**Does:**

1. **Record Disposition, Add Comment, Escalate and Assign hold the page until their last write.** Every flow in the four process models is activity-chained through to End. Before, only the first flow was.
2. **`SO_remediationForReason` reads the side of the trade.** It takes two optional inputs, the direction and the count of onward deliveries, and asks the new rule `SO_failSide` whose fail it is. With no direction it returns what it returned before.
3. **Every lane's Activity entry states the score as "auto-release score N, releases at 80"** on any triage that runs from now. `SO_triageCase` nodes 5, 23 and 33.
4. **The context the agent reads begins its onward-deliveries line with a number**, "0 onward deliveries …" where it said "no onward deliveries …".
5. **The agent already receives the rule's two new inputs**, with nothing changed in Agent Studio. See Findings.

**Does not, until round 2:**

1. **`SO_triageCase` node 11 is unchanged.** It stores the remediation text the agent returns and takes the straight-through code from the fail reason alone. So what a new case stores depends on whether the agent passed the direction.
2. **The agent's instructions are version 6.** Its assessments still hold codes such as funding_gap, and do not name the remediation.
3. **The loaded demo run is as Scott's Prepare left it.** The hero (case 171) stores "Arrange cover borrow / partial release". The other two cases' entries say "confidence".
4. **The 17 standing cases are unchanged.** Which of them store a text the rule no longer returns has not been listed yet.
5. **The records are not level:** the remediation list in `project.md`, `hero-trade-spec.md` line 24 and table B of `agent/eval.md` still describe the old rule. The three demo documents still say "refresh the page" before Activity.

## What changed, by object (versions from readback)

| Object | UUID | Version |
|---|---|---|
| `SO_recordDispositionCase` | `0000f04e-7fcc-8000-233d-7f0000014e7a` | 6.0 → 11.0 |
| `SO_addCommentCase` | `0000f04e-7fca-8000-233c-7f0000014e7a` | 7.0 → 10.0 |
| `SO_escalateCase` | `0000f04e-7fce-8000-233f-7f0000014e7a` | 6.0 → 10.0 |
| `SO_assignCase` | `0000f04e-7ef7-8000-2336-7f0000014e7a` | 9.0 → 13.0 |
| `SO_triageCase` | `0000f04e-ff8f-8000-2381-7f0000014e7a` | 22.0 → 25.0 (nodes 5, 23, 33) |
| `SO_remediationForReason` | `_a-0000f04a-c437-8000-9c47-011c48011c48_561387` | 3 → 4 |
| `SO_failSide` (new rule) | `_a-0000f0af-7210-8000-9c5d-011c48011c48_614312` | 1 |
| `SO_caseContext` | `_a-0000f04a-c437-8000-9c47-011c48011c48_561804` | 4 → 5 |

Each node update publishes a model version, which is why the models moved several versions.

Not changed on NY: every interface, the agent, every record type and group, the standing cases, the loaded run.

In the repo: `.work/rule_SO_failSide.sail` (new), `.work/rule_SO_remediationForReason.sail`, `.work/rule_SO_caseContext.sail`, `.work/pm_SO_triageCase.md`, `.work/gen/triage_event_text.py` (new: generates the three event texts), `.work/gen/zz_caseRows.sail` and `.work/gen/zz_remediationCheck.sail` (new: sources of two throwaway rules, kept for round 2), `agent/instructions.md` (version 7), `agent/instructions-v7-paste.txt` (new: the text to paste), `agent/tools.md`, `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`, this file.

## Part 1: why Activity needed a refresh

**The cause the evidence supports.** In `SO_recordDispositionCase` only the flow from Start to the first write was activity-chained. The page gets control back when the chain ends. The note and the Disposition Recorded event are written by nodes after that point, so the page that followed the submit was drawn before those two rows existed.

**The evidence.**

1. The model on NY: one chained flow, six that were not. The writes run in the order case, note, event.
2. The version before session 1 (5.0) has the same flows with the same flags. Session 1 changed one text in node 4 and nothing in the flow. It did not cause this.
3. The Dev MCP's own description of the flag: the engine runs the next node "while the user waits … until the process ends, a non-chained connection is reached, or another attended node is encountered".
4. The Appian docs say a user who starts a process from a record action is held "until the end of all configured activity chains from the start node". Four accepted community answers give the same remedy for data that shows only after a refresh.

**How sure.** That the chain ended before the two writes is certain. That this is why the entry was missing is likely and not proven, because a session cannot watch a page redraw. One other reading fits the docs: the case screen reads its data in local variables, and the docs say a record view's automatic refresh covers only data supplied by `rv!record`. If that were the whole cause the status would have stayed stale too, and Scott reported only the Activity entry. If his check still fails, that is the next thing to test.

**The same cause held for the other three models**, so they were fixed the same way. `SO_assignCase` was the worst: its chain ended before the assignment itself was written.

## Part 2: the remediation by side of the trade

`SO_failSide` returns "ours", "theirs" or null. `SO_remediationForReason` returns, as ruled:

| Fail reason | Direction | Onward | Remediation | Code |
|---|---|---|---|---|
| insufficient_securities | SELL, or none | any | Arrange cover borrow / partial release | Settled - Borrow Executed |
| insufficient_securities | BUY | 1 or more | Arrange cover borrow for onward deliveries / accept partial delivery | Settled - Borrow Executed |
| insufficient_securities | BUY | 0, or none | Accept partial delivery / chase counterparty | Settled - Partial Release |
| funding_gap | BUY, or none | any | Treasury funding chase | Settled - Funding Received |
| funding_gap | SELL | any | Chase counterparty for funding | Settled - Funding Received |
| the rest | any | any | as before | as before |

Urgency is unchanged. A direction that is not BUY or SELL is treated as none.

## Part 3: the three entries, composed with test values

- "Agent assessed funding gap; proposed Treasury funding chase at auto-release score 35, releases at 80"
- "Escalated by policy: funding gap — broker confirmation lag 26.0h against 2.4h remaining, so the remediation cannot complete inside the window. Auto-release score 35, releases at 80; the breached window decides this case whatever the score."
- "Straight-through: Correct & resubmit | auto-release score 88, releases at 80 | disposition Settled - Corrected | resolved before cutoff without analyst review"

The escalation sentence begins "Auto-release score" with a capital, because the sentence starts there. No screen reads these texts for anything but display: the case screen prints them as stored, and the watchlist, the preview and the supervisor screen do not read them.

## Part 4: for Scott, in Agent Studio

What a session cannot see: the instructions that are deployed, the tool's configured inputs and their descriptions, the outputs and their descriptions, the model, any saved test, and whether a publish step exists. `getAgent` returns HTTP 401.

1. Open the agent `SO_TriageAgent` in Agent Studio.
2. Replace its instructions with the whole of `agent/instructions-v7-paste.txt`. Against version 6 it differs in two places: a paragraph added after "Fail reasons are exactly: …", and step 5.
3. Open the `propose_remediation` tool. It should list three inputs: `failReason` (Text), `direction` (Text) and `onwardDeliveries` (Number (Integer)). A run today shows the agent already receives `direction`, so the two new ones may be there already. If they are not, select the rule `SO_remediationForReason` again so the tool picks them up.
4. If the tool lets you describe each input, use: `direction`: "BUY or SELL, copied from the TRADE line of the caseContext"; `onwardDeliveries`: "The whole number that begins the ONWARD DELIVERIES line of the caseContext; 0 when there are none".
5. Save, and publish if Agent Studio asks.
6. Say the agent is changed, and whether the two inputs were already on the tool.

Do not press Prepare for round 2; the session does that.

## Verified, as `scott.thorn@appian.com` (full scope)

- **The four action models still write everything.** Started through `testProcessModel` on two test cases, each finished in about half a second: the comment and its event; the assignee and its event; the escalated status, its reason and its event; the disposition, its note and its event. `validateDesignObjects` reports no error and no warning on the four and on `SO_triageCase`.
- **The rule's table:** 41 rows through `testRule`, on a throwaway copy first and then on the live rule. 0 fails. With one expectation made wrong on purpose, 1 fail. The no-direction rows were compared key for key with the rule as it was before.
- **Two live triage runs on `ZZ-P006` cases, the agent on version 6:**
  - TRD016924, the clean specimen: 0.88, resolved straight through, "Treasury funding chase". Its two entries read "… at auto-release score 88, releases at 80" and "Straight-through: Treasury funding chase | auto-release score 88, releases at 80 | disposition Settled - Funding Received | resolved before cutoff without analyst review".
  - TRD044567, the concerning specimen: 0.38, escalated. Its entries read "Agent assessed funding gap; proposed Chase counterparty for funding at auto-release score 38, releases at 80" and "Escalated by policy: funding gap — broker confirmation lag 26.0h against 23.9h remaining, so the remediation cannot complete inside the window. Auto-release score 38, releases at 80; the breached window decides this case whatever the score."
- **The demo run was not touched.** Cases 171 to 173 read the same after the tests.
- **Cleanup.** The two test cases, their 5 comments and 10 events are deleted: the children read as absent while the cases still existed, then the cases read NOT FOUND. The four throwaway rules are deleted: the listing for "zz" is empty and each UUID returns HTTP 404.

## Not verified

- **Whether Activity shows the new entries without a refresh.** A session cannot see it. It is step 3 of the checklist below.
- **What each persona sees.** Every read was the design account's.
- **The forms.** The models were started without their start forms.
- **The new wording on a demo case.** It ran on test cases; the loaded run predates it.

## Findings

1. **The agent's tool takes its inputs from the rule as it stands.** The two inputs were added to the rule and nothing was touched in Agent Studio. On the next run the agent, on version 6, returned "Chase counterparty for funding" for a SELL. Only a call that passed the direction returns that text. **So the prompt's statement that NY behaves as before apart from Parts 1 and 3 does not hold.** A Prepare before round 2 can already store the new text on the hero. No packet case would get a wrong code.
2. **`SO_triageCase` node 11 stores the agent's text, not the rule's.** The rule is called there only for the code. Round 2 changes it.
3. **Version 6 assessments do not name the remediation.** Four read today say "the remediation" and never its text. Round 2's pass condition expects the name. See Rulings.
4. **`SO_caseContext` shows an error under the validator** when it is checked with no case id. Its saved test passes. Not caused by this session.
5. **Node 23 truncates its two numbers:** a lag of 26.07 prints "26.0". Left as it is.
6. **The three demo scripts say "a partial release" for the hero's fix**, which fits the new text. None says "borrow".

## Rulings needed

1. **Should version 7 also tell the agent to name the remediation in its assessment?** The checklist and round 2's pass condition expect the assessment to name it. Version 6 does not, and the two ruled changes do not ask for it. One sentence would do it: "In your assessment, name the proposed remediation exactly as the propose_remediation tool returned it." It is not in the paste file. Without it, expect that condition to fail in round 2.

## Operator's browser checklist (Scott), after round 2

1. Demo Admin: press Prepare the demo and wait for "Ready to present".
2. Open the SAP GY / Diamond Trust case. Proposed remediation reads "Accept partial delivery / chase counterparty". The agent's text names the same remediation and shows no code such as insufficient_securities.
3. Press Record Disposition, choose Settled - Partial Release, type a note, submit. Do not refresh. Activity shows the Disposition Recorded entry and your note.
4. Open the BATS LN / Horizon Securities case from the Escalated queue. Its Activity entries say "auto-release score" and none says "confidence". One sentence begins "Auto-release score" with a capital.
5. Demo Admin: press Prepare the demo again.

Step 3 can be tried now, before round 2, on any open case: Part 1 does not depend on the agent.

## Promotion candidates

4 found; 0 promoted; 4 listed in `BUILD_LOG.md`, each with its trigger: the agent's rule tool takes its inputs from the rule as it stands; a related action's page waits only as far as the flows are chained; `testRule` honours `maxResponseSizeBytes`; a node input expression is stored with or without a leading "=" and both run. The candidate ruled in session 1 stays staged, as Scott ruled.

## TODO changes

Added a section for this round with nine items: round 2 owed; Scott's Agent Studio step; what a new case stores until round 2; the ruling on naming the remediation; the browser check for Activity, with the next cause to test if it fails; the three "refresh the page" clauses; the validator error on `SO_caseContext`; node 23's truncation; saved test cases for the two rules. Closed: the lanes' wording. Updated with today's state: the refresh hitch and the code in the agent's assessment.

## BUILD_PLAN changes

The plan's Phase 6.5 line says round 1 is built and round 2 is owed. Ticked: one wording for the score on every lane. Updated and left open: the refresh hitch (fix built, check owed), the code in the assessment (version 7 written, not applied), the hero story (rule built, node 11 and the standing cases owed).
