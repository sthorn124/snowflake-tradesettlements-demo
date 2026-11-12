# SO_triageCase: outline

Read from NY on 2026-11-12 through the Dev MCP (`updateProcessModel` readback) as `scott.thorn@appian.com`. Published version 18.0, saved 2026-11-12 by `scott.thorn@appian.com` (Phase 11: node 14 added, node 10 re-pointed, description corrected). Version 14.0 was the model of 2026-09-22. UUID `0000f04e-ff8f-8000-2381-7f0000014e7a`.

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
| 8 | XOR "Triage write ok?" (4) | `errTriage` | Routes: ok to 5, failed to End |
| 9 | Write Records "Event: Agent Triage Complete" (5) | `failReason`, `remediation`, `confidence` | Event History row: type 2, no user, automation AI_AGENT, `recordId` = `caseId`, "Agent assessed … ; proposed … at confidence 0.00". Errors are not saved |
| 10 | XOR "Route" (12) | Escalate: `windowBreached`, or `failReason` = `counterparty_default`, or `escalate`. Straight-through: `confidence >= cons!SO_CONFIDENCE_THRESHOLD` and `stDisposition` present and `cutoffFuture`. Otherwise analyst | Routes to 20, 30 or 40 |

## The three lanes

Each lane is: write the case, write the assessment as a comment, check both writes, write the audit event, End.

| Lane | Case write | Comment write | Check | Event write |
|---|---|---|---|---|
| Escalate | 20: `{caseID, proposedRemediation, confidenceScore, status: "Escalated"}` | 21 | 22 | 23: type 7, "Escalated by policy: …" or "Escalated by agent: …" |
| Straight-through | 30: `{caseID, proposedRemediation, confidenceScore, disposition: stDisposition, resolvedOn: now(), status: "Resolved - Straight Through"}` | 31 | 32 | 33: type 3, "Straight-through: … \| confidence … >= threshold … \| disposition … " |
| Analyst | 40: `{caseID, proposedRemediation, confidenceScore, status: "Pending Analyst"}` | 41 | 42 | 43: type 2, "Referred to analyst: …" |

- Comment writes (21, 31, 41): SO Case Comment `{caseId, commentText: pv!assessment, author: null, createdOn: now()}`. They save `errComment`, `errCommentMsg`.
- Case writes (20, 30, 40) save `errCase`, `errCaseMsg`. The checks (22, 32, 42) route to the event only when neither write reported an error; otherwise to End.
- Event writes (23, 33, 43): Event History, no user, automation AI_AGENT, `recordId` = `caseId`. Errors are not saved.

Notes
- Every Write Records node has `PauseOnError` false and `CaptureEvents` false, and addresses the case by `caseID` = `pv!caseId` alone.
- Two checks that the case exists: node 8 before the agent runs (is `tradeID` present), and node 14 straight after it returns (does the row exist). Every read and write of the case below node 14 is behind it.
- Measured 2026-11-12 on version 14.0, before node 14: a case deleted during the agent call was re-created by node 3 under its own id with only a status; the analyst lane then wrote the remediation and score, one comment and two type-2 events. On version 18.0 the same test wrote nothing and the process completed.
- The first write to the case (node 3, status "Agent Triage") comes after the agent has returned. During the agent call the case still reads "New".
- The description was corrected on 2026-11-12; it no longer says "stub".
- Run time in the process history: 35 to 44 seconds per case on 2026-11-05 and 2026-11-09; 42 and 45 seconds on 2026-11-12, and 28 seconds for the run that ended at node 14.
