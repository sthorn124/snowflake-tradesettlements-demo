# SO_triageCase: outline

Read from NY on 2026-11-12 through the Dev MCP (`updateProcessModel` readback) as `scott.thorn@appian.com`; nodes 4, 5, 12 and 43 changed on 2026-11-13 (prompt 005) and were read back node by node through `updateProcessModelNode`. Published version 18.0, saved 2026-11-12 by `scott.thorn@appian.com` (Phase 11: node 14 added, node 10 re-pointed, description corrected). Version 14.0 was the model of 2026-09-22. UUID `0000f04e-ff8f-8000-2381-7f0000014e7a`.

Started asynchronously by `SO_intakeRun`, once per newly written case, with `caseId`. Every node runs as the initiator.

Variables: `caseId` (Integer, parameter, required), `caseContext`, `agentOutputs` (Map), `runSummary`, `runId`, `assessment`, `remediation`, `urgency`, `confidence`, `escalate`, `failReason`, `stDisposition`, `cutoffFuture`, `lagHrs`, `hoursRemaining`, `windowBreached`, and three error pairs: `errTriage`, `errCase`, `errComment` (each with a `…Msg`).

Node ids are not in flow order. The order below is the flow.

## Before the lanes

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Script "Assemble case context" (9) | `rule!SO_caseContext(caseId)`: the case, its trade, instrument, prediction, counterparty and onward deliveries | `pv!caseContext` |
| 3 | XOR "Context resolved?" (8) | The case by id: is `tradeID` present | Routes: yes to 10; no (no `caseId`, no such case, or no trade) to End |
| 4 | Execute AI Agent "Execute SO_TriageAgent" (10) | `pv!caseContext`; agent `126a096b-787c-400c-ba21-6498d3ba0a0e`, synchronous | `agentOutputs`, `runSummary`, `runId`. The node has no error output. Its one flow goes to node 14 |
| 4a | XOR "Case still exists?" (14), added 2026-11-12 | SO Settlement Case by `caseID` = `pv!caseId` (`a!queryRecordType`, one row) | Routes: a row came back, to 11; no row (or no `caseId`), to End. Nothing below runs for a case deleted while the agent ran |
| 5 | Script "Unpack agent output + derive routing" (11) | `agentOutputs`; the case again by id (`failReason`, `cutoffTs`, the trade's `brokerConfirmationLagHrs`); `rule!SO_remediationForReason`; `rule!SO_cutoffDisplay` | `assessment`, `remediation`, `urgency`, `confidence`, `escalate`, `failReason`, `stDisposition`, `cutoffFuture`, `lagHrs`, `hoursRemaining` |
| 6 | Script "Escalation policy: window breached?" (13) | `lagHrs`, `hoursRemaining` | `windowBreached` = lag above 0 and hours remaining at or below the lag |
| 7 | Write Records "Set status Agent Triage" (3) | `pv!caseId` | SO Settlement Case `{caseID, status: "Agent Triage"}`. Saves `errTriage`, `errTriageMsg` |
| 8 | XOR "Triage write ok?" (4) | `errTriage`; `rule!SO_triageLane` on the six routing variables | Three ways out (2026-11-13): failed, to End; written and the lane is ANALYST, straight to 40, past node 5; written and any other lane, to 5 |
| 9 | Write Records "Event: Agent Triage Complete" (5) | `failReason`, `remediation`, `confidence` | Escalate and straight-through lanes only, from 2026-11-13. Event History row: type 2, no user, automation AI_AGENT, `recordId` = `caseId`, "Agent assessed <fail reason label, lower case>; proposed … at auto-release score N, releases at G" (2026-11-13, `prompts/006`; it said "at confidence 0.00" until then). The label comes from `SO_failReasonDisplay`. Errors are not saved |
| 10 | XOR "Route" (12) | `rule!SO_triageLane` (2026-11-13; the conditions were inline before and are unchanged in meaning). Escalate: `windowBreached`, or `failReason` = `counterparty_default`, or `escalate`. Straight-through: `confidence >= cons!SO_CONFIDENCE_THRESHOLD` and `stDisposition` present and `cutoffFuture`. Otherwise analyst | Routes to 20, 30 or 40. An analyst-lane case no longer reaches this node: node 4 sends it to 40 |

## The three lanes

Each lane is: write the case, write the assessment as a comment, check both writes, write the audit event, End.

| Lane | Case write | Comment write | Check | Event write |
|---|---|---|---|---|
| Escalate | 20: `{caseID, proposedRemediation, confidenceScore, status: "Escalated"}` | 21 | 22 | 23: type 7, "Escalated by policy: …" or "Escalated by agent: …". The breached-window sentence ends "Auto-release score N, releases at G; the breached window decides this case whatever the score." (2026-11-13; it said "Agent confidence 0.00" until then) |
| Straight-through | 30: `{caseID, proposedRemediation, confidenceScore, disposition: stDisposition, resolvedOn: now(), status: "Resolved - Straight Through"}` | 31 | 32 | 33: type 3, "Straight-through: … \| auto-release score N, releases at G \| disposition … \| resolved before cutoff without analyst review" (2026-11-13; it said "confidence … >= threshold …" until then) |
| Analyst | 40: `{caseID, proposedRemediation, confidenceScore, status: "Pending Analyst"}` | 41 | 42 | 43: type 2, "Held for analyst review: auto-release score N, releases at G — proposed ….", with "; held because …" when the score clears the gate. The lane's only "Agent Triage Complete" entry |

- Comment writes (21, 31, 41): SO Case Comment `{caseId, commentText: pv!assessment, author: null, createdOn: now()}`. They save `errComment`, `errCommentMsg`.
- Case writes (20, 30, 40) save `errCase`, `errCaseMsg`. The checks (22, 32, 42) route to the event only when neither write reported an error; otherwise to End.
- Event writes (23, 33, 43): Event History, no user, automation AI_AGENT, `recordId` = `caseId`. Errors are not saved.

Notes
- Every Write Records node has `PauseOnError` false and `CaptureEvents` false, and addresses the case by `caseID` = `pv!caseId` alone.
- Two checks that the case exists: node 8 before the agent runs (is `tradeID` present), and node 14 straight after it returns (does the row exist). Every read and write of the case below node 14 is behind it.
- Measured 2026-11-12 on version 14.0, before node 14: a case deleted during the agent call was re-created by node 3 under its own id with only a status; the analyst lane then wrote the remediation and score, one comment and two type-2 events. On version 18.0 the same test wrote nothing and the process completed.
- The first write to the case (node 3, status "Agent Triage") comes after the agent has returned. During the agent call the case still reads "New".
- The description was corrected on 2026-11-12; it no longer says "stub".
- 2026-11-13: the analyst lane wrote two type-2 entries in the same minute (node 5, then node 43). Node 4 now sends an analyst-lane case past node 5, and node 43 states the decision, the score against the gate and the proposed fix. Node 43 stays behind check 42, so the entry is written only when the case and comment writes succeeded. The escalate and straight-through lanes still write two entries with different titles (node 5, then 23 or 33); left as they are.
- Node 40 has two incoming flows (from 4 and from 12). It is a Write Records node, not a gateway, and one token reaches it per instance.
- Run time in the process history: 35 to 44 seconds per case on 2026-11-05 and 2026-11-09; 42 and 45 seconds on 2026-11-12, and 28 seconds for the run that ended at node 14.
- 2026-11-13 (`prompts/006`, round 1): every lane states the score the same way, "auto-release score N, releases at G", with N and G computed as `SO_autoReleaseDisplay` and node 43 compute them (`tointeger(round(100 * x, 0))`). Nodes 5, 23 and 33 changed; node 43 already said it. The three texts are generated by `.work/gen/triage_event_text.py`, which also writes the same expressions onto rule inputs for a throwaway test rule. Published version 25.0 (one version per node update). The lag and the hours in node 23 are still printed with `text(x, "0.0")`, which truncates: a lag of 26.07 prints "26.0".
- Node 11 takes `pv!remediation` and `pv!urgency` from the agent's output and calls `SO_remediationForReason` only for `pv!stDisposition`, with the fail reason alone. Round 2 of `prompts/006` changes that: the process reads the trade's direction and its onward deliveries and takes the remediation text from the rule.
