# Closeout — 2026-11-13 — Phase 6.5 session 2: Activity without a refresh, the remediation by side of the trade, agent version 7 (both rounds of `prompts/006`)

The session ran in Claude Code. The `credits.py` step was skipped, because `CREDITS.md` is built from Kiro's own records.

## Scope and identity

- Prompt: `prompts/006-phase65-refresh-and-remediation-by-side.md`, round 1, Scott's Agent Studio step, then round 2, in one session.
- Every Appian call went through the Dev MCP (server `appian`, 218 tools, plugin and server 26.9.5, build `20261026-140102`) as `scott.thorn@appian.com`. `loggedInUser()` was asserted equal to that account, and the control with another name failed. The account is a direct member of `SO Supervisors` (full scope), `SO Demo Admins` and `SO Users`, read back this session.
- No sail, by the prompt. Every persona session on the machine is expired. Nothing was read as `alex.analyst` or `sam.supervisor`.
- The runtime server's tools were never loaded or called. Two helper agents made read-only calls under the same account (two process models' nodes; one render of the console).
- Preflight flags, both already open in `TODO.md`: the Dev MCP is 26.9.5 against the pin 26.6.105 (26.9.15 is on the App Market), and sail is 26.9.5 against its pin.
- Round 1 ran no Prepare. Round 2 ran one, at 23:23:12 UTC, which also re-dated the standing cases.

## Where NY stands

- **Loaded run:** cases 179 (hero), 180 (escalation), 181 (straight-through), loaded 23:23:39 UTC. The console read "Ready to present. Loaded today at 6:23 PM by Scott Thorn."
- **Ready ends at 00:28:45 UTC (7:28 PM Eastern)**, two hours before the hero's cutoff. After that, press Prepare before presenting.
- No test case and no throwaway object is left on NY.

## What changed, by object (versions from readback)

| Object | UUID | Version |
|---|---|---|
| `SO_recordDispositionCase` | `0000f04e-7fcc-8000-233d-7f0000014e7a` | 6.0 → 11.0 |
| `SO_addCommentCase` | `0000f04e-7fca-8000-233c-7f0000014e7a` | 7.0 → 10.0 |
| `SO_escalateCase` | `0000f04e-7fce-8000-233f-7f0000014e7a` | 6.0 → 10.0 |
| `SO_assignCase` | `0000f04e-7ef7-8000-2336-7f0000014e7a` | 9.0 → 13.0 |
| `SO_triageCase` | `0000f04e-ff8f-8000-2381-7f0000014e7a` | 22.0 → 26.0 (nodes 5, 23, 33, then 11) |
| `SO_remediationForReason` | `_a-0000f04a-c437-8000-9c47-011c48011c48_561387` | 3 → 4 |
| `SO_failSide` (new rule) | `_a-0000f0af-7210-8000-9c5d-011c48011c48_614312` | 1 |
| `SO_remediationForCase` (new rule) | `_a-0000f0af-7210-8000-9c5d-011c48011c48_614429` | 1 |
| `SO_caseContext` | `_a-0000f04a-c437-8000-9c47-011c48011c48_561804` | 4 → 5 |
| `SO_TriageAgent` instructions | `126a096b-787c-400c-ba21-6498d3ba0a0e` | version 7, pasted by Scott in Agent Studio; a session cannot read it back |
| SO Settlement Case rows 45 and 46 | standing cases | `proposedRemediation` only |

Each node update publishes a model version, which is why the models moved several versions.

Not changed on NY: every interface, every record type and group, the other 15 standing cases, every standing comment and event.

In the repo: `.work/rule_SO_failSide.sail`, `.work/rule_SO_remediationForCase.sail` (both new), `.work/rule_SO_remediationForReason.sail`, `.work/rule_SO_caseContext.sail`, `.work/pm_SO_triageCase.md`, `.work/gen/triage_event_text.py` and `.work/gen/triage_node11.py` (new: they generate the node payloads), `.work/gen/zz_caseRows.sail` and `.work/gen/zz_remediationCheck.sail` (new: sources of two throwaway rules, kept for the next session), `agent/instructions.md`, `agent/tools.md`, `agent/eval.md`, `.kiro/steering/project.md`, `hero-trade-spec.md`, the three demo documents, `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`, this file.

## Part 1: Activity without a refresh

**Cause.** In `SO_recordDispositionCase` only the flow from Start to the first write was activity-chained. The page is released when the chain ends, so it was drawn before the note and the Disposition Recorded event were written.

**Evidence.**

1. The model on NY: one chained flow, six that were not. The writes run in the order case, note, event.
2. The version before session 1 (5.0) has the same flows with the same flags. Session 1 did not cause it.
3. The Dev MCP's own description of the flag: the engine runs the next node "while the user waits … until the process ends, a non-chained connection is reached, or another attended node is encountered".
4. The Appian docs say a user who starts a process from a record action is held "until the end of all configured activity chains from the start node".

**Fix.** Every flow in the four action models is chained, through to End. `SO_addCommentCase`, `SO_escalateCase` and `SO_assignCase` had the same shape. `SO_assignCase` had been releasing the page before the assignment itself was written.

**Result.** Scott, on the hero, before round 2: "the entries showed without a refresh". The other cause named in round 1, that the case screen reads its data in local variables, was not tested: nothing was left to explain.

## Part 2: the remediation by side of the trade

`SO_failSide` says whose fail it is. `SO_remediationForReason` returns, as ruled:

| Fail reason | Direction | Onward | Remediation | Code |
|---|---|---|---|---|
| insufficient_securities | SELL, or none | any | Arrange cover borrow / partial release | Settled - Borrow Executed |
| insufficient_securities | BUY | 1 or more | Arrange cover borrow for onward deliveries / accept partial delivery | Settled - Borrow Executed |
| insufficient_securities | BUY | 0, or none | Accept partial delivery / chase counterparty | Settled - Partial Release |
| funding_gap | BUY, or none | any | Treasury funding chase | Settled - Funding Received |
| funding_gap | SELL | any | Chase counterparty for funding | Settled - Funding Received |
| the rest | any | any | as before | as before |

Urgency is unchanged.

**The process decides what a case stores.** `SO_triageCase` node 11 takes the text and the code from `SO_remediationForCase`, which reads the case's trade and calls the rule. Before, the node stored the text the agent returned.

## Part 3: one wording for the score

`SO_triageCase` nodes 5, 23 and 33. No screen reads these texts for anything but display. Composed with test values in round 1; on the final run they read:

- "Agent assessed funding gap; proposed Treasury funding chase at auto-release score 45, releases at 80"
- "Escalated by policy: funding gap — broker confirmation lag 26.0h against 2.4h remaining, so the remediation cannot complete inside the window. Auto-release score 45, releases at 80; the breached window decides this case whatever the score."
- "Straight-through: Correct & resubmit | auto-release score 88, releases at 80 | disposition Settled - Corrected | resolved before cutoff without analyst review"

The escalation sentence begins "Auto-release score" with a capital, because the sentence starts there.

## Part 4: the agent

- Version 7 is two changes against version 6: step 5 passes the fail reason, the direction and the count of onward deliveries; and a new paragraph has the agent write the fail reason in plain words in its assessment.
- `SO_caseContext` begins its onward-deliveries line with a number: "0 onward deliveries …" where it said "no onward deliveries …".
- Scott pasted version 7 and reported: "The two inputs were already on the tool."

## Scott's rulings in this session

1. **"No. Do not add the sentence. Version 7 stays at the two changes."** The agent is not asked to name the remediation in its assessment.
2. **The pass condition is replaced:** "every case stores the remediation the rule returns for its trade, and no assessment holds a fail-reason code or argues for a different remediation."
3. **Checklist step 2 is replaced:** "Proposed remediation reads "Accept partial delivery / chase counterparty". The agent's text shows no code such as insufficient_securities and does not argue for a borrow."

## The agent's three test cases, on version 7

Pass conditions were stated before the run.

| Case | Trade | Result | Stored remediation |
|---|---|---|---|
| Clean, run 1 | TRD016924, a BUY, funding gap, lag 1.71h against 23 hours | 0.87, resolved straight through | Treasury funding chase |
| Clean, run 2 | the same | 0.87, resolved straight through | Treasury funding chase |
| Concerning | TRD044567, a SELL, funding gap, lag 26.07h against 23 hours | 0.42, escalated | Chase counterparty for funding |
| Hero, from the Prepare | TRD9DEMO01, a BUY, insufficient securities, lag 1.15h against 3 hours | 0.65, held for analyst review | Accept partial delivery / chase counterparty |

- Every condition was met on the first run of each. There was no wrong-side result to replicate.
- The concerning assessment states the arithmetic: "23 hours to cutoff, but the broker confirmation lag is 26.07 hours — exceeding the available window by roughly 3 hours".
- All six version 7 assessments were read in full. None holds a code. None mentions a borrow or argues for another remediation. None names the remediation.
- The agent passed the direction on its own: its output read "Chase counterparty for funding" for the SELL and "Accept partial delivery / chase counterparty" for the hero.

## The standing cases

- All 17 were read against what the rule returns for each trade.
- **Two differed, both funding gaps on a SELL:** case 45 (TRD005533, held by `sam.supervisor`) and case 46 (TRD040366, New). Both now store "Chase counterparty for funding".
- **The five insufficient-securities standing cases are all SELLs**, so they keep "Arrange cover borrow / partial release".
- **No standing event says "confidence".** Four state the score in their own older wording ("auto-release score 68 vs 80", "auto-release score 62 below gate 80"). Left.
- **One assessment argues for the old remediation in its own words, and was left as the prompt says.** Case 45, comment 49: "Broker confirmation lag is 0.5 hours against roughly 3.0 hours remaining to cutoff, so a treasury chase has time to complete even inside this short window." See Rulings needed.
- No comment or event was edited. Nothing was deleted from the standing set.

## Verified on the final Prepare, as `scott.thorn@appian.com` (full scope)

- **Hero, case 179:** Pending Analyst, 0.65. Stored remediation "Accept partial delivery / chase counterparty". Activity entry: "Held for analyst review: auto-release score 65, releases at 80 — proposed Accept partial delivery / chase counterparty." The assessment says "fail reason insufficient securities" and holds no code.
- **The hero's case screen, rendered** (error null): "Proposed remediation" over "Accept partial delivery / chase counterparty"; the agent card over the assessment; both Activity entries. No text on the page holds "borrow", "confidence" or a code.
- **Escalation story, case 180:** Escalated, 0.45, "Treasury funding chase". Both entries say "auto-release score".
- **Straight-through story, case 181:** Resolved - Straight Through, 0.88, "Correct & resubmit", Settled - Corrected, as before. Both entries say "auto-release score".
- **The console, rendered** (error null): "Environment OK · data 50,000/50,000 · 9/9 connections" and "Ready to present. Loaded today at 6:23 PM by Scott Thorn." in green, with the button enabled.

Also verified earlier in the session:

- The rule's table: 41 rows through `testRule`, on a throwaway copy and then on the live rule, 0 fails; 1 fail with an expectation made wrong on purpose.
- The four action models still write everything when run, each in about half a second.
- `validateDesignObjects`: no error and no warning on the five process models and on `SO_remediationForReason`, `SO_failSide` and `SO_remediationForCase`. The live rules read back byte-identical to the saved files.
- Cleanup: 5 test cases, 8 comments and 19 events were created under `ZZ-P006` and deleted, children first, each read as absent. Five throwaway rules were deleted; the listing for "zz" is empty and each UUID returns HTTP 404.

## Not verified

- **What each persona sees.** Every read and both renders are the design account's.
- **Add Comment, Escalate and Assign in a browser.** Scott's check was Record Disposition. The other three models were changed the same way and write everything when run.
- **Geometry**, and the forms themselves.
- **A run where the agent leaves the direction out.** The process no longer depends on it; that case was not forced.

## Findings

1. **The agent's tool takes its inputs from the rule as it stands.** In round 1 the agent, still on version 6, returned "Chase counterparty for funding" for a SELL with nothing changed in Agent Studio, and Scott then found both inputs already on the tool. A change to that rule's inputs is a change to the agent. The prompt's statement that NY would behave as before at the stop did not hold for that reason.
2. **Assessments never name the remediation**, on version 6 or 7. Ruled: they are not asked to.
3. **Standing case 45's assessment and its stored remediation now disagree.**
4. **`hero-trade-spec.md` says the hero is held "because of position size".** On every run read today the agent held it for the counterparty's risk tier and fail rate.
5. **`SO_caseContext` shows an error under the validator** when it is checked with no case id. Its saved test passes. Not caused by this session.
6. **`SO_triageCase` node 23 truncates its two numbers:** a lag of 26.07 prints "26.0".
7. **The Prepare left four comments in the table, hidden**, as every Reset does: three assessments and the note Scott typed in his check.

## Rulings needed

1. **Standing case SO-45's assessment.** It says "a treasury chase has time to complete" beside a stored remediation of "Chase counterparty for funding". Rewrite that clause, or leave it.

## Operator's browser checklist (Scott)

Run it before 7:28 PM Eastern, or press Prepare first.

1. Open the SAP GY / Diamond Trust case. Proposed remediation reads "Accept partial delivery / chase counterparty". The agent's text shows no code such as insufficient_securities and does not argue for a borrow.
2. Press Record Disposition, choose Settled - Partial Release, type a note, submit. Do not refresh. Activity shows the Disposition Recorded entry and your note. (Seen once already, before round 2.)
3. Open the BATS LN / Horizon Securities case from the Escalated queue. Its Activity entries say "auto-release score" and none says "confidence". One sentence begins "Auto-release score" with a capital.
4. On any open case, try Add Comment, and Assign or Escalate: the new entry shows without a refresh.
5. As `sam.supervisor`: the escalations card reads as it did. Her FX case SO-45 reads "Chase counterparty for funding".
6. Demo Admin: press Prepare the demo again.

## Promotion candidates

4 found; 0 promoted into the skill; 2 ruled as passing the five gates and listed for the template repo; 2 left staged.

- Passes, listed: an agent's rule tool takes its inputs from the rule as it stands.
- Passes, listed: a record action's page is released when its activity chain ends, so chain every flow through the last write.
- Staged: `testRule` honours `maxResponseSizeBytes`; a node input expression is stored with or without a leading "=" and both run.

They are not written into `appian-supplemental` from this repo, for the reason Scott ruled on session 1's candidate: promotion is made from the template repo.

## TODO changes

Added: the browser checks for this prompt; the ruling on case SO-45's assessment; the Project's copies of the three demo documents; the hold reason in `hero-trade-spec.md`; saved test cases for `SO_remediationForCase`; and from round 1, the validator error on `SO_caseContext`, node 23's truncation, and saved test cases for the two rules. Closed: Activity after Record Disposition; the lanes' wording; the code in the agent's assessment; round 2; Scott's Agent Studio step; what a case stores before round 2; the ruling on naming the remediation; the "refresh the page" clauses in the repo. Updated: the Reset item, with the four comments this Prepare left.

## BUILD_PLAN changes

Ticked in Phase 6.5: Activity after Record Disposition; one wording for the score; the code in the agent's assessment; the hero story's borrow on a buy. The plan's Phase 6.5 line says session 2 is built and the browser checklist is owed. The personas section gains what each persona should see from this session.
