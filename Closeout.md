# Closeout — 2026-11-12 — Phase 10 read-only audit of NY (read 2026-11-11): no trade-less case found; Phase 11 blank-cases line closed by ruling

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/001-phase10-read-only-audit.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. Every read was made on 2026-11-11, and the session was first closed out that day (commit `b2fee15`). On 2026-11-12, in the same session, Scott ruled on one open question (see "Rulings given"), and this file was rewritten whole to carry it. No Appian call was made on 2026-11-12.

**Scope and identity.** Read-only. Nothing was created, updated or deleted in Appian. No `testProcessModel`, no record write. Snowflake was not read. Every read went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`, a direct member of `SO Supervisors`, `SO Demo Admins` and `SO Users`. The `SO Settlement Case` security rule for `SO Supervisors` has no condition, so the case reads below are full-scope. No sail session was used. The runtime server's ten tools were present in the session and were never loaded or called.

**Rules loaded.** Yes. Before its first tool call the session listed the seven steps of core §10 from context, without opening a file.

## Preflight

- **Plan:** populated.
- **Dev MCP:** design surface present. `listRecordTypes` on the application returned its 11 record types and User.
- **Versions have drifted from the pins.** NY's plugin and the local server are both 26.9.5 (build `20261026-140102`). `reference/toolchain.md` §1 describes 26.6.105 (build `20260930-110421`). sail is 26.9.5 against a pin of 26.6.105. The App Market has 26.9.15, so the site admin updates the plugin before a new bundle is worth downloading. To bring it level, say "run the update procedure". Bundle paths: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads`, and the link the version tool prints, `https://ny.appiancloud.com/suite/plugins/servlet/stateless/dev-mcp-bundle`.
- **Skills differ three ways.** The session loaded `~/.claude/skills/appian-supplemental`, Version 2026-10-28. `~/.kiro/skills/appian-supplemental` is Version 2026-11-10.4. The repo copy is Version 2026-10-05.2. Nothing was overwritten; Scott rules the direction. `~/.claude/skills/appian` is one bundle behind the server; the `~/.kiro` copy matches it.
- **Identity:** the username on NY is `scott.thorn@appian.com`. The build parameter records `scott.thorn`.
- **Groups, by membership readback:** `SO Users` holds `SO Administrators`, `SO Analysts` and `SO Supervisors`. `SO Supervisors` holds 11 users. `SO Analysts` holds `alex.analyst` and no group. `SO Demo Admins` holds nine users and sits outside `SO Users`. `SO Supervisors` is **not** a member of `SO Analysts`; the build parameter says it is.
- **Per-session ritual:** not run. No Phase 4 screen was rendered, and the ritual writes records. The standing cases are still dated 2026-10-23.
- **Personas:** every sail session on this machine is expired, `alex.analyst` and `sam.supervisor` included. None was needed.
- **Git:** the local folder was two commits behind `origin/main` (the two prompt commits). It was fast-forwarded before any work.

## What was read

| Object | Version | Last saved (UTC) |
|---|---|---|
| `SO_demoAdminConsole` | 12 | 2026-09-24 16:24 |
| `SO_simulateRun` | 3.0 | 2026-09-11 15:47 |
| `SO_intakeRun` | 4.0 | 2026-09-22 22:15 |
| `SO_resetRun` | 3.0 | 2026-09-11 15:48 |
| `SO_triageCase` | 14.0 | 2026-09-22 23:45 |

None of the five has changed since the last recorded build session on 2026-09-24. No process model has unpublished work. Also read, to make the outlines and answers accurate: `SO_createTriageCase`, the rules `SO_intakePlan` and `SO_remediationForReason` (both identical to their `.work` copies), the application's constants, the case, comment and event tables, and the process history of the four models.

## What changed

Nothing in Appian. In the repo:
- `.work/SO_demoAdminConsole.sail`: saved from the deployed version 12. No diff; the repo copy was already identical.
- `.work/pm_SO_simulateRun.md`, `.work/pm_SO_intakeRun.md`, `.work/pm_SO_resetRun.md`, `.work/pm_SO_triageCase.md`: new outlines, nodes in flow order with what each reads and writes.
- `BUILD_PLAN.md`, `TODO.md`, `BUILD_LOG.md`, this file.

## Inputs for Phase 11

Answers 1 to 3 come from the sources, the process history and the docs. Nothing was run to produce them.

### 1. Where `SO_triageCase` writes the agent's result, and what that write does to a deleted case

**Where.** The flow is: assemble context (node 9), "Context resolved?" (8), Execute SO_TriageAgent (10), unpack and derive routing (11), window policy (13), then the writes. Every write comes after the agent returns, and every one addresses the case by `pv!caseId` alone:

| Step | Node | Writes |
|---|---|---|
| First write | 3, "Set status Agent Triage" | case: `status` = "Agent Triage" |
| | 5 | audit event, type 2 |
| The agent's result | 20, 30 or 40 (one per lane) | case: `proposedRemediation`, `confidenceScore`, `status`; the straight-through lane adds `disposition` and `resolvedOn` |
| The assessment text | 21, 31 or 41 | one `SO Case Comment` row |
| | 23, 33 or 43 | audit event, type 7, 3 or 2 |

**The only existence check is node 8, and it runs before the agent.** The agent call takes 35 to 44 seconds. A Reset inside that window deletes the case, and nothing looks again.

**What the write does if the case is gone.**
- *From the model:* nothing stops it. Node 3 hands Write Records a case record holding only `caseID` and `status`. `PauseOnError` is false on every write node.
- *From the docs* (Write Records smart service, 26.6, "Writing records and related records"): a record that includes its primary key is an update. A new record is created when the key is left out on an auto-generated-key table, or when a manually keyed value does not already exist. The page does not say what happens to a supplied key that no longer exists on an auto-increment table, which is this case.
- *From the 2026-10-22 report:* a row was created. The reported ids fit a row re-created under the deleted case's own id. Case 105 was the hero case of a Load that evening, and its triage never wrote (see "Other findings"). The blank cases were reported as 106 to 110, the ids the remaining cases of two Loads would have had.
- *What the row would hold, by the Route conditions:* with the case gone, node 11 reads no fail reason, no cutoff and no confirmation lag. The straight-through lane needs a disposition and a future cutoff, so it cannot be taken. The case goes to the analyst lane, or to the escalate lane if the agent set its flag. The re-created row holds `caseID`, `status` ("Pending Analyst" or "Escalated"), `proposedRemediation` and `confidenceScore`, and no trade, session, fail reason, desk or cutoff. One comment and two events hang off the same id.
- *Not measured.* The session was read-only and no blank case is left to read. That node 11's reads come back empty for a missing case, instead of stopping the process, is inferred from the reported outcome.

**Where a guard has to sit.** Between the agent's return and node 3. Node 3, node 5 and the lane's three writes all write by id, so a check placed later is too late.

### 2. What the console's status line counts

`local!statusLoaded: or(local!tradeReserved > 0, local!otherCases > 0)`

- **`tradeReserved`**: the number of `SO Trade` rows whose trade id starts with `TRD9`, read live from Snowflake. Any run's packet counts, not only `DEMO`.
- **`otherCases`**: all cases minus the cases whose session id is exactly `P4-VERIFY`. "All cases" is the first 500 `SO Settlement Case` rows with no filter. So a case counts as a demo case when its session id is anything else: `DEMO`, another run name, or empty. The count does not look at the trade id, the status, or whether the trade exists.

That is the 2026-10-23 reading of "Demo loaded" with 0 trades and 5 cases: five cases with an empty session id. Two more things follow from the same source:
- **Reset could not clear that state.** The same boolean enables the Reset button, but `SO_resetRun` selects cases where the session id equals `DEMO`. Cases with no session id are never selected.
- **The count the fix needs is already on the screen.** `local!resetRows` is the cases whose session id equals `cons!SO_DEMO_RUN_NAME`.

The status text is "Demo loaded", then the newest `scoredAt` among predictions whose trade id starts with `TRD9`, then the two counts. The amber "Loaded before today" line compares that stamp's date with today's.

### 3. What a screen could read to tell "run in progress" from "run finished"

**Nothing records run state today.** `SO_simulateRun` returns its message to a local variable on the console, which a page refresh loses. `SO_intakeRun` and `SO_triageCase` are started asynchronously and write no run-level marker. Intake ends when the last triage has been *started*.

What a screen can query, all of it already written by the processes:

| Read | What it tells |
|---|---|
| `SO Settlement Case` where session id = `cons!SO_DEMO_RUN_NAME`: the `status` of each | A case is created as "New". Triage moves it to "Agent Triage" and at once to "Pending Analyst", "Escalated" or "Resolved - Straight Through". A case has its agent decision when its status is none of "New" and "Agent Triage". `confidenceScore` is filled by the same write |
| `rule!SO_intakePlan(runName)` | How many cases the run should have. `atRiskTradeIds` minus `noStory` is the expected number (3 on the scripted packet). An empty `toCreate` means intake has created them all |
| The newest `scoredAt` among `TRD9` predictions (the console's `local!loadStamp`) | When the Load ran, in UTC. `SIMULATE_FEED` writes it at call time. This is the clock for "no finish after N minutes" |
| The count of `TRD9` trades (the console's `local!tradeReserved`) | Whether Snowflake holds a packet |

Put together:
- **Nothing loaded:** no `TRD9` trades and no `DEMO` cases.
- **Running:** a packet is present, and fewer cases have a decision than the plan expects.
- **Ready:** every expected case has a decision, and the stamp is today's.
- **Loaded before today:** the stamp's date is not today.
- **Stuck:** Running, with the stamp more than N minutes old.

Four cautions from the sources:
- **"Agent Triage" is not a progress signal.** Node 3 writes it after the agent returns. For the whole agent call the case still reads "New".
- **`createdOn` and `modifiedOn` are empty on process-written cases** (project sections, measured 2026-09-23). They cannot time a run.
- **The first seconds of Prepare leave no trace in the data.** While the last run is being cleared and the standing cases re-dated, there are no packet trades and no stamp. A screen reading data alone sees "Nothing loaded". Today the Load button starts its process synchronously, so the page is held for that part; the console's own text gives 30 seconds as the limit. If Prepare's synchronous part outlasts that, the screen has nothing to read until the stamp lands.
- **Several failures leave a run "Running" for good, which is what the timeout is for.** A failed agent run stops triage at the agent node and the case stays "New" (observed, below). A case that fails "Context resolved?" or the node 3 write also stays "New". A failed lane write leaves "Agent Triage". A case that could not be created is skipped by intake, so the expected number is never reached.

Timings from the process history, two runs (2026-11-05 and 2026-11-09):
- Load press to the third agent decision: 73 seconds and 78 seconds.
- `SO_simulateRun` 8 seconds; `SO_resetRun` 8 seconds; `SO_intakeRun` 32 seconds; `SO_triageCase` 35 to 44 seconds per case, the three overlapping.

### 4. Cases that have no trade

**None.** There is no row to list. On 2026-11-12 Scott closed the Phase 11 line that would have deleted them (see "Rulings given").

- Read on 2026-11-11 as `scott.thorn@appian.com`, member of `SO Supervisors`, whose record security rule has no condition.
- `SO Settlement Case` holds 17 rows: ids 36 to 52, all session `P4-VERIFY`, every one with a trade id.
- Confirmed a second way, by query: "no case with an id above 52" held, the control "no case with an id above 51" failed as it should, and "no case with an empty trade id" held.
- Comments (12 rows) and audit events (14 rows) all belong to cases 36 to 50. No orphans.
- SO-106 to SO-110 are not on NY. Case ids have since reached at least 134. The repo does not record who removed the five, or when. By reading `SO_resetRun`, Reset could not have.

### Other findings from the same reads

- **Two `SO_triageCase` instances are stuck ACTIVE.**
  - Process `536912644`, started 2026-10-22 8:07 PM EDT, model version 14.0, case 105, the hero trade `TRD9DEMO01`. Error: `Execute SO_TriageAgent: Agent run failed`. It assembled the context and stopped at the agent node. It has written nothing. Case 105 no longer exists, so if the instance were ever resumed, its writes would land on a case id that is gone.
  - Process `536908653`, started 2026-08-28, model version 2.0, case 5. It stopped on the old `a!automationId("AI AGENT")` spelling. A Phase 3 leftover.
- **A failed agent run has no error path.** The agent node saves its three outputs and nothing else. The first instance above is what a failed run looks like: the process sits at the node and the case stays "New".
- **The hero in Escalated.** By the Route node's conditions, the hero (confirmation lag 1.15 hours, cutoff 185 minutes out, reason `insufficient_securities`) reaches Escalated on a normal run only if the agent sets its own `escalate` flag. The Escalated event says which path was taken ("by policy" or "by agent"), and the triage instance keeps `agentOutputs` for seven days. Neither survives from 2026-10-22.
- **The console's "agent OK" check is met by the standing cases.** It reads the newest event with no user and a machine event type. The fixture events qualify, so the check passes whether or not the agent has run.
- **A second presenter's account ran the demo on 2026-11-05 and 2026-11-09.** The last Reset completed on 2026-11-09 at 20:54 UTC. Appian holds no demo case now.
- **`SO_triageCase`'s description still calls it a stub.** The model runs the real agent node.
- **Two usernames that look like one presenter are split across the groups**: one is in `SO Demo Admins` and not in `SO Supervisors`, the other the reverse. Neither account can run the console on its own.

## Verified

- **Identity:** an assertion through `validateExpression` held for `scott.thorn@appian.com` and failed for `scott.thorn` and for `alex.analyst`. No object was created.
- **Membership:** the same assertion against the two group constants held, and `listGroupMembers` lists the account in both groups.
- **No trade-less case:** two read paths as a full-scope account, with a control (section 4).
- **Sources and versions:** each object's `get` tool and `listObjectVersions`.
- **Stuck instances:** `getProcessInstance` and `listProcessEvents`.
- **Push:** checked after this file is committed, by `HEAD` equal to `origin/main` with a clean tree. The result is in the session's closing message; this file being on `origin/main` is the evidence.

## Not verified

- **What a late triage write does to a deleted case.** Reported, and consistent with the ids, but not measured.
- **The case table on 2026-11-12.** It was not re-read before the ruling was recorded. The ruling rests on the 2026-11-11 reads.
- **Snowflake.** Whether packet trades are present was not read.
- **The `SO_SETTLEMENT` table itself.** The record layer was read; no Dev MCP tool reads table rows.
- **The hand changes of 2026-10-22 and 2026-10-23** to the watchlist and supervisor screens. The prompt was cut to the console and the four models, and those five are unchanged.
- **The header checkpoint line in `BUILD_LOG.md`** is still stale. This session did not reconcile it.

**Browser checklist.** None owed. Nothing was rendered or changed.

## Rulings given

- **The "Delete the blank cases" line in Phase 11 is closed** (Scott, 2026-11-12). Nothing was left to delete, and this session deleted nothing. The line is ticked in `BUILD_PLAN.md`. Who removed the five cases stays an open `TODO.md` item.

## Rulings needed

- **Cancel the two stuck `SO_triageCase` instances?** It is a change to NY, so it waits for Scott's word.
- **Which copy of `appian-supplemental` is the master**, and whether the two skills under `~/.claude/skills/` are brought up to it.
- **Run the Dev MCP update procedure before Phase 11?** The pins describe 26.6.105; the server is 26.9.5.
- **Does Phase 11 touch the console's "agent OK" check?**
- The rulings left open by the previous close-out are unchanged and are listed in `BUILD_PLAN.md`.

**Promotion candidates:** 4 found; 0 promoted; 4 listed in `BUILD_LOG.md` with triggers. They are: the `validateExpression` assertion as a read-only identity check; a group named by text evaluating false inside that assertion; a failed Execute AI Agent run stopping the process with no fail-forward; Write Records creating a row for a key that no longer exists.

**TODO changes:** added a "Phase 10 audit, found 2026-11-11" section with eight items (stuck triage instances; Dev MCP version drift; three skill copies; two build parameters; a presenter under two usernames; the stale `SO_triageCase` description; the "agent OK" check; the unrecorded removal of the blank cases). Closed: confirm `CLAUDE.md` loads the rules. Annotated: persona sail sessions, all expired. Unchanged and still open: the stale `BUILD_LOG.md` header checkpoint, under Blocking. `TODO.md` was not touched on 2026-11-12.

**BUILD_PLAN.md changes:** the Phase 10 audit item ticked. Three Phase 10 items added (Dev MCP update, skill master copy, two build parameters). In Phase 11: the blank-cases line ticked on 2026-11-12 by Scott's ruling, with nothing to delete; the hero-in-Escalated line annotated with the audit's findings; and two items added (cancel the stuck instances; decide what a failed agent run leaves behind).

**Credits.** Not recorded. This session ran in Claude Code.
