# Replicating the Appian + Snowflake demo for a new use case

*Written 2026-10-22 for the Boston Scientific complaint-classification build (hazard / harm / severity with human review). Checked against the source repository, the NY environment and Appian's deployment documentation on that date. Scott owns the original; questions about it go to him.*

**Source repository:** https://github.com/sthorn124/snowflake-tradesettlements-demo. Every file path in this guide (`snowflake/…`, `agent/…`, `.work/…`, `mockups/…`, `packet-spec.md`, the talk-track files) is a path in that repository. It is public as of this writing; if that changes, Scott grants read access.

The settlements demo is a pattern, and the pattern is what you are copying: Snowflake holds the data and scores it, Appian turns each score into a case with an owner and a deadline, an AI agent handles the confident cases, people handle the rest, policy overrides the agent when a window is breached, and every decision is on the record. The complaint use case fits that pattern closely. This guide says what to copy, what to recreate, what to author, and how to keep the two builds apart.

---

## 1. The first decision: where the Appian copy lives

How much of the Appian side you can copy depends on one thing: whether you have an Appian environment other than NY.

**What Appian documents.** Package import matches objects by UUID, not by name: "If a UUID match is found in the target environment, the existing object is updated rather than creating a new object." Objects can be exported and re-imported on the same server, but only "for backup and restoration purposes" ([Application Deployment Guidelines](https://docs.appian.com/suite/help/26.9/Application_Deployment_Guidelines.html)). So:

- **On a different environment**, export and import is the normal deployment and lands the whole application as a working copy: record types, interfaces, rules, process models, integrations, connected systems, groups, sites, constants. This is Path A below, and it is by far the least work.
- **On NY itself**, importing the Settlement Operations package updates Scott's objects in place. It cannot produce a second copy, and renaming the application before import does not change that. Appian Community threads on cloning an application in the same environment land in the same place: build a new application and duplicate the objects ([clone an application](https://community.appian.com/discussions/f/general/38599/clone-an-application)). This is Path B.

A personal Appian cloud sandbox, a second demo cluster environment, or any environment you can import into makes Path A available. Ask Scott and the SC leads before assuming you are stuck on NY.

**Recommendation for a reusable life sciences asset: Path A, treated as a starting point, not a reskin.** The import gives you working screens, process models, the agent and the console in a day, and the view layer keeps the settlements names out of your real tables. What makes the result an LS asset rather than a settlements demo with new labels is the pass after import: rename the objects and the record fields so the next LS SC never meets `SO_` or `notional`; replace the rules that only mean something on a settlements desk (`SO_fxToUsd`, `SO_penaltyAccrual`, `SO_onwardDeliveries`, `SO_quantityDisplay`, the hours-to-cutoff runway) with their complaint equivalents (units at risk, days to reporting deadline, related complaints on the lot); and rewrite the agent's timing arithmetic from hours to days. That work is the same on either path. Path B only adds the port on top of it. The one condition on Path A is step 5.4 in §6: confirm on day one that the imported record types resolve through your connected system; if they do not, the five Snowflake record types take Path B's wizard step and the port that follows.

---

## 2. Isolation rules

Both builds share the Snowflake account. Whatever path you take on Appian, these keep yours from touching Scott's.

**Snowflake**

- Build in your own database, not a schema under `FINSERV`. Daniel Mackenthun administers the partner account: he sets up your user, your role grants, your default warehouse and your database (`FINSERVADMIN` cannot create databases). This guide uses `LIFESCI`. A separate database is what makes Path A work with no record type changes, and it is the cleanest isolation either way. Never write to `FINSERV`.
- Every procedure, view and agent you create names your database and schema explicitly. Copy Scott's scripts and change the `USE DATABASE` and `USE SCHEMA` lines and every qualified name; a procedure that inherits the session context is one worksheet mistake away from the wrong table.
- Use your own Snowflake user and your own PAT, restricted to role `FINSERVADMIN`. Your default warehouse must be `COMPUTE_WH` (`ALTER USER <you> SET DEFAULT_WAREHOUSE = COMPUTE_WH;`, which Daniel can set) or record types fail with "no active warehouse".
- `COMPUTE_WH` is shared and X-Small. Two demos at the same time will contend. If you present often, ask Scott about a second warehouse.
- Your demo run ids use a different reserved prefix. Scott's packet rows are `TRD9…`; use `CMP9…` so a stray query can never confuse the two, even though they live in different databases.

**Appian, Path A (your own environment)**

- Import into your environment only. Never import your modified package back into NY: the UUIDs are Scott's, and NY would treat it as an update to his application.
- Your own Snowflake credentials go in through the import customization file, never his PAT.

**Appian, Path B (NY)**

- Create a new application with a new prefix. This guide uses `CQ` (Complaint Quality); pick any two letters no other NY application uses. Object names are unique across the environment for rules, constants, integrations, connected systems and groups, so the prefix is what separates the builds.
- Do not import the Settlement Operations package into NY (§1).
- Do not Save As over an `SO_` object, and do not edit any `SO_` object "just to see". Save As from an `SO_` object into a new `CQ_` name is fine; that is how you copy process models.
- Your own groups, connected systems, sites and constants. Do not add yourself to the `SO` groups to test; test as your own personas.
- The record type wizard will show `FINSERV` beside your database. Always pick yours.

---

## 3. What transfers, and how

| Layer | Path A (own environment) | Path B (NY) | You author either way |
|---|---|---|---|
| Snowflake tables | Your own tables and names in `LIFESCI`, plus a `TRADE_SETTLEMENT` schema of five views shaped like Scott's tables (§4 Naming); `GET_DDL` on his schema gives the column names and types | Your own tables and names; `GET_DDL` as the column reference | The data |
| `SIMULATE_FEED` / `RESET_SESSION` | Copy `snowflake/simulate-reset-procedures.sql`, change database and id prefix, replace the 15 `VALUES` rows | Same | Your 15-row packet |
| Semantic view | `DESC SEMANTIC VIEW` on Scott's, rewrite names, synonyms and verified queries, create from YAML | Same | Business vocabulary, 5 verified queries |
| Cortex agent | `DESCRIBE AGENT`, then `snowflake/agent-instructions-v2.sql` adapted | Same | Domain instructions |
| Scoring | Heuristic SQL (Scott has `run_inference.sql` from the Snowflake kit) or Cortex `AI_CLASSIFY` over the narrative | Same | Thresholds, tier bands |
| Whole Appian application | Export from NY, import once, set credentials in the import customization file | Not available | |
| Record types on Snowflake (5) | Come across in the import; the connected system's Database setting is what should point them at your tables (confirm on `SO Trade` first, §6 step 5) | Wizard regenerates them from your tables; same column names give the same field names | Row security rule (your persona's product line) |
| Record types, Appian-native (2 plus events) | Come across; their cloud-database tables are created from NY's DDL before the import | Recreate from the field list in §7 | Nothing |
| Interfaces (18) and rules (20) | Come across | Port `.work/*.sail` by UUID and prefix substitution | Labels and vocabulary |
| Process models (4) | Come across | Save As from `SO_`, re-point every node | Nothing |
| Agent Studio agent | Confirm it came across; recreate from `agent/instructions.md` if not | Recreate from `agent/instructions.md` and `agent/tools.md` | Domain instructions |
| Demo Admin console and site | Come across | Ported with the interfaces | Nothing |
| Packet stories | `packet-spec.md` and `hero-trade-spec.md` as templates | Same | Your 3 stories |
| Talk track and scripts | `talk-track-10min-internal.md`, `demo-script-15min-client-awareness.md` as templates | Same | Every line |

---

## 4. Use-case mapping

**Naming.** Your data is yours: your own database, your own tables, your own column names, not one trade row anywhere. What the Appian side pins is the shape it reads. An imported record type stores its schema, table and source column names, and Appian warns that a schema name that differs between environments causes a schema mismatch error ([Create a Record Type for Snowflake](https://docs.appian.com/suite/help/26.6/connect-record-type-to-snowflake.html)). So on Path A the record types expect to find `TRADE_SETTLEMENT.TRADES` and the other four, with Scott's column names and types, in whatever database the connected system names.

The clean way to give them that without naming a complaint table `TRADES`: a compatibility schema of views. Your real tables live in `LIFESCI.COMPLAINT_QUALITY` under your own names (`COMPLAINTS`, `COMPLAINT_PREDICTIONS`, `DEVICES`, `SITES`, `COMPLAINT_HISTORY`, columns named for your domain). A second schema, `LIFESCI.TRADE_SETTLEMENT`, holds five views named like Scott's tables that select from yours with his column names and types (`SELECT COMPLAINT_ID AS TRADE_ID, …`). The record type wizard lists views beside tables, Appian never writes to these record types (every Snowflake write goes through your procedures over the SQL API), and nothing on screen shows a column name. Your semantic view, agent and procedures all point at the real tables. The views are the only place the settlements names survive, and they exist to make the Appian import land untouched.

On Path B the wizard builds record types from whatever you name, so no views are needed; identical column names only save the port a mapping file.

| Settlements | Complaints | Column(s) | Powers this demo beat |
|---|---|---|---|
| `TRADES` | Complaints | Table | Everything |
| Trade id | Complaint id | `TRADE_ID` | Row identity, packet ids `CMP9<run>01..15` |
| Trade date | Date received | `TRADE_DATE` | Batch band |
| Expected settlement date | Regulatory reporting deadline (FDA MDR 30 days from awareness; EU MDR 15 days for a serious incident) | `EXPECTED_SETTLEMENT_DATE` | The cutoff clock on every screen |
| Instrument | Device model / catalog number | `INSTRUMENT_ID` → `INSTRUMENTS` | Device card, "by product family" questions |
| Counterparty | Reporting site or facility | `COUNTERPARTY_ID` → `COUNTERPARTIES` | The history card ("recent incidents from this site") and the agent's confidence |
| Direction (BUY/SELL) | Complaint source (patient, HCP, sales rep, field) | `DIRECTION` | Display only |
| Notional | Units affected (lot size) | `NOTIONAL` | "Value at risk" becomes "units at risk" |
| Currency | Country of origin | `CURRENCY` | Display; the "by currency" chip becomes "by country" |
| Broker confirmation lag | Days since awareness | `BROKER_CONFIRMATION_LAG_HRS` | The policy escalation: lag against the window |
| Desk | Product line | `DESK` | Row-level security: investigators scoped by product line |
| Matched / matched at | Narrative validated / validated at | `IS_MATCHED`, `MATCHED_AT` | Stage 1 validation, shown as a stamp |
| `TRADE_PREDICTIONS` | Complaint predictions | Table | |
| Fail probability | Model confidence that the complaint is serious or reportable | `FAIL_PROBABILITY` | The score on every row |
| Risk tier (4) | Predicted severity (keep 4: Minor, Serious, Critical, Catastrophic; a 5th tier means touching the tier rules) | `RISK_TIER` | Case creation: Critical and Catastrophic open cases |
| Top risk factors | Predicted hazard and harm, as `{factor, contribution}` | `TOP_RISK_FACTORS` | Agent context; optional columns `PREDICTED_HAZARD`, `PREDICTED_HARM` are cleaner |
| Fail reason (4 codes) | Hazard category (4 codes, e.g. `mechanical_fracture`, `electrical_fault`, `contamination`, `labeling_use_error`) | `FAIL_REASON` on history and cases | Reason → action rule, display rule |
| Remediation per reason | Investigation action per hazard (engineering failure analysis, electrical safety test, sterility review, IFU review) | Rule `SO_remediationForReason` (or `CQ_actionForHazard`) | The agent's proposal |
| Disposition codes | Final classification outcome (`Classified - Accepted as Proposed`, `Classified - Severity Raised`, `Classified - Severity Lowered`, `Reportable - MDR Filed`, `Not Reportable`, `Escalated - Safety Board`, `Deadline Missed`) | Constant | Record Disposition action |
| `SETTLEMENT_HISTORY` | Complaint history (prior complaints per device or site, final severity, days to close) | `FAIL_REASON`, `STATUS`, `DAYS_LATE`, `ACTUAL_SETTLEMENT_DATE` | The history card |
| Confidence gate at 0.80 | Accept-all above the gate; human adjudication below | `SO_CONFIDENCE_THRESHOLD` | Act 3 governance |
| Window breached escalates by policy | Reporting deadline inside the elapsed window escalates to the safety board by policy | `SO_triageCase` | The "AI advises, rules decide" beat |

Two things in the Boston Scientific document do not become demo beats. Stages 2 and 3 (async dispatch, webhooks, retries, backoff) are plumbing; the demo opens on a scored batch and Load simulates the intake, exactly as Scott's does. Stage 5's e-signature is a talk-track line on the disposition action, not a build item for v1.

---

## 5. Snowflake, step by step (both paths)

**Step 1. Access.** From Daniel Mackenthun: your own user on the partner account, `FINSERVADMIN` granted, default warehouse `COMPUTE_WH`. You generate your own PAT, restricted to `FINSERVADMIN`, and write the expiry down. Never work as `ACCOUNTADMIN`.

**Step 2. Database.** From Daniel: `CREATE DATABASE LIFESCI; GRANT OWNERSHIP ON DATABASE LIFESCI TO ROLE FINSERVADMIN;` Then you, as `FINSERVADMIN`: `CREATE SCHEMA LIFESCI.COMPLAINT_QUALITY;` for your tables, and on Path A also `CREATE SCHEMA LIFESCI.TRADE_SETTLEMENT;` for the compatibility views.

**Step 3. Structure.** In Snowsight: `SELECT GET_DDL('SCHEMA', 'FINSERV.TRADE_SETTLEMENT');` and keep the output as the column reference: every column the screens read, with its type. It copies no data. Write your own DDL for the five tables in `LIFESCI.COMPLAINT_QUALITY` with your names; §4's mapping table says which of Scott's columns each of yours stands in for, and the types must match his (`FAIL_PROBABILITY` is a float in 0 to 1, `RISK_TIER` text, `SCORED_AT` and `MATCHED_AT` `TIMESTAMP_NTZ`, the ids `VARCHAR(20)`). `TRADES` has three columns Scott added later (`QUANTITY`, `IS_MATCHED`, `MATCHED_AT`); `INSTRUMENTS` has four (`ISIN`, `CSD`, `TICKER_ORIG`, `NAME_ORIG`); `COUNTERPARTIES` two (`OPS_CONTACT_NAME`, `OPS_CONTACT_PHONE`); `SETTLEMENT_HISTORY` one (`COUNTERPARTY_ID`); every one of them is read by a screen, so each needs a stand-in.

Then, on Path A, the five views in `LIFESCI.TRADE_SETTLEMENT`, one per table, named `TRADES`, `TRADE_PREDICTIONS`, `COUNTERPARTIES`, `INSTRUMENTS`, `SETTLEMENT_HISTORY`, each `SELECT <your column> AS <his column>, …` over your table. A view must supply every column its record type mapped, whether or not a screen reads it; the exact list is the record type's data model in Designer after import (the source field column), and before that, every column `GET_DDL` shows. Check each view with `DESC VIEW`: same names, same types; order does not matter.

**Step 4. Data.** §11 is a complete prompt that produces the generator as one Snowsight script: your five tables, 50,000 complaints with coherent sites, devices, history and predictions, and the five views. Give it to Claude as written. Sizes are yours; Scott's are 50 sites, 200 devices, 50,000 complaints, 50,000 history rows, one prediction per complaint, and 50,000 is what the imported console asserts. Shapes the screens depend on:
- `FAIL_PROBABILITY` in 0 to 1; `RISK_TIER` exactly your four values; the tier bands documented.
- `SCORED_AT` written as `SYSDATE()::TIMESTAMP_NTZ`. Appian reads `TIMESTAMP_NTZ` as UTC, and the Snowsight session is Pacific, so `CURRENT_TIMESTAMP()` cast to NTZ is seven hours wrong.
- `FAIL_REASON` and `DESK` as fixed enums, exactly as the display rules expect.
- Narratives: templated text per hazard category is enough for the screens; `SNOWFLAKE.CORTEX.COMPLETE` can generate varied ones for the packet.
- Deadlines coherent with elapsed days, so the policy escalation has real cases to fire on.

**Step 5. Scoring.** Two options. The simple one is a heuristic SQL insert like Scott's `run_inference.sql` (ask him for the file; it came in the Snowflake kit and is not in this repo). The better one for your story is Cortex `AI_CLASSIFY` over the narrative to produce the hazard, with a severity rule on top; then the sentence "Snowflake Cortex classified every complaint" is literally true. Score a smaller baseline if LLM cost matters (5,000 complaints reads fine on every screen). Either way the insert is `TRUNCATE` then `INSERT`, so rerunning restores pristine predictions.

**Step 6. Procedures.** Copy `snowflake/simulate-reset-procedures.sql`. Change the `USE DATABASE` and `USE SCHEMA` lines to your real schema, the table and column names to yours, the id prefix (`TRD9` → `CMP9`), and the fifteen `VALUES` rows to your packet (3 stories that open cases, 12 background rows below the case floor). The procedures write your tables; the views show the rows to Appian. Keep the validation, the exact-id delete list, the idempotency and the `SYSDATE()` stamps. Verify with a copy of `snowflake/verification-summary.sql`: one statement, one PASS/FAIL grid.

**Step 7. Semantic view.** `DESC SEMANTIC VIEW FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS;` gives the structure. Rewrite the YAML with your database, business names and synonyms, and five verified queries that match your Ask chips (overall serious rate, top sites by serious rate, severity distribution, serious rate by product family, units at risk for Critical and Catastrophic). Create it with `CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('LIFESCI.TRADE_SETTLEMENT', $$<yaml>$$, FALSE);` pasted as one block. Verify with `DESC SEMANTIC VIEW`, not `SHOW`; a truncated paste creates a partial view that reports success.

**Step 8. Agent.** `DESCRIBE AGENT FINSERV.TRADE_SETTLEMENT.SETTLEMENT_RISK_AGENT;` for the spec shape. Create yours over your semantic view, then adapt `snowflake/agent-instructions-v2.sql`: display labels never stored codes, no sums across incomparable units (your version: never sum units across product families), no narration, no references to charts or tables. Smoke test with `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` and the structured messages body (`deploy-notes.md` has it). Run each chip question three times before it goes on a screen; an answer that changes substance between runs is replaced.

**Step 9. Grants.** Your PAT's role needs `SELECT` on the semantic view and `USAGE` on the agent and the procedures. `FINSERVADMIN` owns everything it creates, so membership covers it today.

---

## 6. Appian, Path A: your own environment

Everything in this section was checked against the deployed objects on 2026-10-22. Where Appian's documentation is silent, the step says so and tells you what to confirm. The files this guide names (`snowflake/*.sql`, `agent/instructions.md`, `packet-spec.md`, `mockups/`, the talk track and script) are in the source repository linked at the top. You do not need a repository of your own to follow this path.

**Step 1. Export (Scott, in NY).**
- In the Settlement Operations application, run the Missing Precedents check and add what it finds. The known outside references are the Snowflake logo document and its folder (another application owns them) and any group not already in the application. A package that imports with a missing precedent fails loudly on that object, which is safe but costs a round trip.
- Export the application. Keep both files: the package zip and the import customization file template. Users are never exported, and group membership comes across only for members that exist on the target, so plan on step 2 regardless.

**Step 2. Prepare your environment before importing.**
- **Demo users.** Create two persona users. Today the source build names `alex.analyst` and `sam.supervisor` in two screens (`SO_supervisorCommand` lines 27 to 28, `SO_caseDetail` lines 691 and 713); use those usernames, or edit the two lines after import. If Scott moves the usernames into constants before the export (§10), the customization file sets them and this becomes a line in that file.
- **Cloud database tables.** The Appian-native record types are synced, and a synced record type full-syncs when it is deployed, so its table must exist first. In NY's Cloud Database console, export the structure (no data) of every table whose name starts with `SO_`: `SO_SETTLEMENT_CASE`, `SO_CASE_COMMENT`, `SO_SETTLEMENT_CASE_EVENT_HISTORY`, and the generated event type, reply thread and subscriber tables beside them. Run that script in your environment's Cloud Database console. If a sync still fails on import, the import log names the record type; create its table and run a full sync from the record type.
- **Snowflake ready.** §5 through step 9, so the connected system has something to connect to.

**Step 3. Import customization file.**
- Fill in every line the template offers. Expect entries for the two connected systems' plain fields and for the integrations; encrypted fields (the PAT) come through blank by design and are typed by hand, either here or in Designer after import.
- Constants: `SO_CONFIDENCE_THRESHOLD` and `SO_DEMO_RUN_NAME` keep their values. `SO_SNOWFLAKE_LOGO` resolves to the imported document and needs nothing.
- Only one customization file is applied per deployment.

**Step 4. Import.** Read the import log to the end, not just the summary. Synced record types report their full sync; a connected system that could not validate reports it here too.

**Step 5. Post-import edits, in this order.**
1. `SO Snowflake Data Source`: Account URL `a2770166725871-appian-partner.snowflakecomputing.com`, your user, your PAT, role `FINSERVADMIN`, warehouse `COMPUTE_WH`, Database `LIFESCI`. Test the connection from the connected system.
2. `SO Snowflake SQL API`: your PAT as the bearer token, one `Bearer` prefix. Test it.
3. Three integrations carry the database name in their body text: `SO_simulateFeed` and `SO_resetSession` (`"statement":"CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED(?)"` and `"database":"FINSERV"`, likewise for `RESET_SESSION`) and `SO_askSnowflake` (same body shape; the `database` field, and the agent's qualified name if the `DATA_AGENT_RUN` statement spells it out). Replace `FINSERV` with `LIFESCI` in each, nothing else. Test `SO_simulateFeed` with run name `SMOKE`; the procedure's own message comes back verbatim.
4. Confirm the Snowflake record types resolve to your views: open `SO Trade` in Designer and view its data. Complaint rows means the connected system's Database setting carries the record types, as expected from how Appian stores the source (schema and table on the record type, database on the connected system; Appian's documentation does not state this outright). A schema mismatch error or `FINSERV` rows means it does not, in which case stop and tell Scott rather than improvising; the fallback is Path B's record type step for those five record types plus re-pointing their references, and that decision is his to make with you.
5. Groups: your account into `SO Demo Admins` and `SO Supervisors`; `alex.analyst` into `SO Analysts`; `sam.supervisor` into `SO Supervisors`.
6. Event types: the event type table must hold exactly seven rows, ids 1 to 7: Case Created, Agent Triage Complete, Straight-Through Resolution, Assigned, Comment Added, Disposition Recorded, Escalated. Insert them if the import left the table empty.
7. The Demo Admin console asserts a baseline of exactly 50,000 trades and 50,000 predictions (`SO_demoAdminConsole`, the verdict line and the two Details lines). Change those numbers to your baseline, or if Scott has moved them into a constant before the export (§10), set it in the customization file. Until then the verdict reads Not ready.
8. Row-level security on `SO Trade` names the analyst persona's product line (`EQ_FLOW` in the source build). Set it to one of your `DESK` values, or if it is a constant by then, set it in the customization file.
9. Agent Studio: open `SO Triage Agent` and confirm it imported with its two tools pointing at `SO_caseContext` and `SO_remediationForReason`. If it did not come across, recreate it from `agent/instructions.md` and `agent/tools.md`; the process model `SO_triageCase` then needs its agent node re-pointed.
10. Sites: `settlement-ops` and `settlement-ops-admin` must be unique URL stubs on your environment; rename them in step 7 anyway.

**Step 6. Smoke test, in this order.** `SO Trade` data from `LIFESCI`. The Demo Admin console as your presenter account: the readiness line is green. Load the demo: the procedure reports 15 trades and 3 cases, and three cases appear within about two minutes. Open the hero: held for review below 0.80. Record Disposition on it. The supervisor page as `sam.supervisor`. Reset: baseline restored, zero open demo cases.

**Step 7. Rename.** Rename the application, every object (`SO` to your prefix), the groups, the sites and their URL stubs, and the record fields (`tradeId` to `complaintId`, `notional` to `unitsAffected`, `desk` to `productLine`, `brokerConfirmationLagHrs` to `daysSinceAwareness`, and so on through §4). References are by UUID, so renames break nothing, and Designer rewrites the names inside expressions for you. A record field's source column mapping stays what it was; that is the view's job.

**Step 8. Convert what only means something on a settlements desk.** This is the pass that turns the import into an LS asset. In this order, because each layer reads the one before it:
1. **Vocabulary canon.** Write it first (§8) and rewrite the display rules to it: `statusDisplay`, `riskTierDisplay` (severity), `failReasonDisplay` (hazard), `assetClassDisplay` (product family), `regionDisplay` (country or region), `quantityDisplay` (units; the shares-or-face branch goes), and `remediationForReason` (investigation action per hazard, with its disposition code and urgency). Also the constant `SO_DISPOSITION_CODES`.
2. **The clock, hours to days.** The settlements build measures everything in hours to cutoff. Complaints run in days to a reporting deadline. Objects that compute or render the clock: `casePriority` (risk times time remaining; the sort of the queue), `cutoffDisplay`, `priorityBand`, `railCutoffChip`, `railTicker`, the Timing card and banner in `SO_caseDetail`, the cutoff runway chart on `SO_supervisorCommand` (next 12 hours becomes next 30 days, by day), and `intakePlan` if it reads the window. The policy escalation in `SO_triageCase` compares elapsed days against days to deadline instead of lag hours against hours remaining; the escalation event text it composes changes with it.
3. **Money to units.** `fxToUsd` and the "USD eq." basis go; "Value at risk" on the supervisor page becomes units at risk (or open complaints at risk, if units do not read well for your devices). `penaltyAccrual` (CSDR basis points per day) either becomes a reportability-exposure line (days past deadline) or is removed with its constant. `onwardDeliveries` becomes related complaints on the same lot or device, or is removed; the agent context line that quotes it changes with it.
4. **The agent.** `caseContext` (the six labeled lines the agent sees) in your terms: complaint, device, site, prediction with hazard and severity, site history, related complaints. Then the Agent Studio instructions: the timing arithmetic in days, the confidence semantics unchanged (only concerning facts lower it, favorable facts never do, a case favorable across the board earns 0.85 or higher). Then the Cortex agent instructions (§5 step 8).
5. **The console.** `SO_demoAdminConsole` and `SO_adminCheck` labels (trades become complaints), the baseline assertion from step 5.7, the run-of-show copy.
6. **Screens.** Labels on every interface, the site header badge, the Snowflake mark unchanged. Density and type follow Scott's mockups; replace the vocabulary, keep the layout. The three mockups in `mockups/` are yours to fork when a screen needs more than relabeling.

**Step 9. Packet.** Author the three stories (§8), write them into your `SIMULATE_FEED` (§5 step 6), run the verification grid, then Load and read every story on screen as both personas: the hero holds below 0.80, the escalation fires by policy whatever the agent scored, the straight-through resolves.

**Step 10. Verify as personas** (§7, step 12).

**Step 11. Talk track and script.** From `talk-track-10min-internal.md` and `demo-script-15min-client-awareness.md`, every line rewritten.

**Step 12. Your records, optional.** Nothing in the demo needs a repo. What whoever runs this after you needs from you is four documents: the vocabulary canon, the packet spec (your three stories and the twelve background rows), the Snowflake scripts you ran (DDL, views, procedures, semantic view YAML, agent instructions), and the presenter script. Keep them wherever your team keeps such things. If you do want the Kiro method Scott uses for building and close-outs, start a repo from this one and ask him for the walkthrough.

---

## 7. Appian, Path B: NY

Two ways to do the mechanical part. With the Kiro method Scott uses: clone the `appian-devmcp-method-kiro` template for a build repo, copy `.work/`, `snowflake/`, `agent/`, `packet-spec.md`, `hero-trade-spec.md`, `mockups/` and `.kiro/steering/project.md` from his repo into a `reference/settlement-source/` folder, and let sessions do step 6 against the Dev MCP. Without it, step 6 is done by hand in Designer: Save As each `SO_` rule and interface into its `CQ_` name, then replace every record reference through the expression editor's picker, display rules first. Budget twice the time for the hand version; 38 objects, several hundred references. Everything else in this path is Designer work either way.

**Step 1. Application, groups, sites (Designer).**
- Application `Complaint Quality`, prefix `CQ`.
- Groups: `CQ Users` (parent) > `CQ Investigators`, `CQ Supervisors` (supervisors also members of investigators); `CQ Demo Admins` outside the tree.
- Sites: `complaint-quality` (pages Queue, Cases, Supervisor) and `complaint-quality-admin` (Demo Admins only). Two sites, never a tab.
- A presenter holds both `CQ Demo Admins` and `CQ Supervisors`. The console preflights the second; copy that logic, it is in `SO_demoAdminConsole.sail`.

**Step 2. Connected systems (Designer).**
- `CQ Snowflake Data Source`: the native 26.6 "Snowflake Data Source" template, not the AppMarket "Snowflake" tile. Account URL `a2770166725871-appian-partner.snowflakecomputing.com`, Database `LIFESCI`, role `FINSERVADMIN`, warehouse `COMPUTE_WH`, your PAT.
- `CQ Snowflake SQL API`: HTTP connected system to `https://a2770166725871-appian-partner.snowflakecomputing.com`, bearer auth with your PAT, one `Bearer` prefix. Load, Reset and Ask all run through this one; Scott's is `SO Snowflake SQL API`, and `SO_simulateFeed` and `SO_askSnowflake` show the request shapes.

**Step 3. Record types on Snowflake (Designer wizard, direct access, never sync).**
- `CQ Complaint` (TRADES), `CQ Complaint Prediction` (TRADE_PREDICTIONS, 1:1 on the id), `CQ Device` (INSTRUMENTS, N:1), `CQ Site` (COUNTERPARTIES, N:1), `CQ Complaint History` (SETTLEMENT_HISTORY). Table names are yours if you renamed them.
- Relationships: Complaint → Prediction (1:1), Complaint → Device (N:1), Complaint → Site (N:1), Site → History (1:N), Complaint → History (1:N).
- Record-level security on `CQ Complaint` only: investigators by `DESK` (product line), supervisors see all. Scott's rule hardcodes the demo analyst's desk; do the same for your demo investigator.
- Write down every record type UUID and field UUID (`getRecordType` over the Dev MCP returns them). The port needs them.

**Step 4. Appian-native record types (Designer, new table in the cloud database).**
- `CQ Complaint Case`: caseId, complaintId, sessionId, status, failReason (hazard code), proposedRemediation (investigation action), confidenceScore, disposition (text, codes only), assignee (User), desk, cutoffTs, createdOn, resolvedOn. Record events generated (Event History and Event Type); add `RELATED_RECORDS` security on the event record types by hand; disable commenting on the app.
- `CQ Case Comment`: caseId, author, commentText, createdOn (a plain datetime stamped by the Add Comment write path, not auto-managed).
- The 7 event types, seeded at configuration time: Case Created, Agent Triage Complete, Straight-Through Resolution, Assigned, Comment Added, Disposition Recorded, Escalated.

**Step 5. Constants.** Recreate these ten under your prefix: `CQ_CONFIDENCE_THRESHOLD` (0.80), `CQ_DEMO_RUN_NAME` (`DEMO`), `CQ_DISPOSITION_CODES` (your list from §4), `CQ_ANALYSTS_GROUP`, `CQ_SUPERVISORS_GROUP`, `CQ_PM_SIMULATE_RUN`, `CQ_PM_RESET_RUN`, `CQ_SNOWFLAKE_LOGO` (point at the same PNG document Scott's uses, or upload your own), `CQ_MARK_USE_LOGO`, `CQ_PENALTY_BP_PER_DAY` (rename to whatever your "cost of another day" is, or drop the penalty card).

**Step 6. Port the rules and interfaces (Kiro session over the Dev MCP, or Save As by hand).**
- Source: the 38 files in `.work/` (20 `rule_SO_*.sail`, 18 `SO_*.sail`).
- Build a substitution map: every `recordType!{uuid}` and every `.fields.{uuid}` / `.relationships.{uuid}` in those files, keyed by the name that follows the UUID, mapped to your UUIDs from steps 3 and 4 by the same field or relationship name (or by your rename mapping). Then `SO_` → `CQ_` on every `rule!`, `cons!` and object name.
- Apply the map to every file, then create the objects in this order: display-vocabulary rules first (`statusDisplay`, `riskTierDisplay`, `failReasonDisplay`, `assetClassDisplay`, `regionDisplay`, `quantityDisplay`), then the other rules, then interfaces. Each object is verified by reading it back, not by the create call succeeding.
- Rewrite the vocabulary canon in the display rules before anything renders: statuses, severity tiers, hazard codes, actions, dispositions, product families, regions.
- `SO_fxToUsd`, `SO_penaltyAccrual` and `SO_onwardDeliveries` are settlements-specific; port them anyway and decide later whether a complaints equivalent exists (units at risk, days of exposure, related complaints on the same lot).

**Step 7. Integrations.** `CQ_simulateFeed` and the reset call point at your procedures; `CQ_askSnowflake` calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` with your agent name and the structured messages body. Keep Scott's extraction logic (only the text elements after the last tool result); it is what stops the agent narrating on screen.

**Step 8. Process models (Designer, Save As).** `SO_simulateRun`, `SO_intakeRun`, `SO_resetRun`, `SO_triageCase` → Save As `CQ_…`, then open every node and re-point record types, rules, constants, integrations and the agent. `CQ_triageCase` carries the governance logic: the policy escalation before the gate (your version: elapsed days against the reporting deadline), the confidence XOR, the straight-through write, the investigator task. `SO_intakePlan` (the tier check that decides which scored complaints open cases) ports as a rule in step 6.

**Step 9. Agent Studio.** Recreate the triage agent from `agent/instructions.md` (deployed v6) with your domain in place of settlements, and the two tools from `agent/tools.md`: the context rule (`CQ_caseContext`, one query, six labeled lines) and the action rule (`CQ_actionForHazard`). No write tool; the process writes. Keep the confidence semantics: only concerning facts lower it, favorable facts never do, the timing arithmetic is mandatory.

**Step 10. Record actions on `CQ Complaint Case`.** Record Disposition, Assign, Escalate, Add Comment. The forms are in `.work/` and port in step 6.

**Step 11. Reskin.** Labels on every interface, the site header badge, the Snowflake mark (reuse `SO_snowflakeMark` as ported; it is a fragment rule and previews broken in Designer by design). Density and type follow Scott's mockups; replace the vocabulary, keep the layout.

**Step 12. Verify as personas.** Investigator sees only their product line; supervisor sees all; the console loads 15 complaints and opens 3 cases; the hero holds for review below 0.80; the escalation story escalates by policy regardless of score; the straight-through story resolves; Reset returns to baseline, line for line.

**The unsupported shortcut, for completeness.** A package is a zip of XML, and object identity is the UUID inside it. A script that replaces every UUID defined in the package with a fresh one, consistently across all files, and prefixes the object names, produces a package NY would import as new objects. Appian does not document or support this. The failure modes are asymmetric: a UUID the script remaps that pointed at an object outside the package (a system group, the logo document) fails the import loudly as a missing precedent, which is safe; a UUID the script misses is still Scott's, and the import would update his object, which is the one outcome this guide exists to prevent. Only attempt it with a throwaway environment to test the import on first. If you have that environment, you have Path A, and Path A is less work.

---

## 8. What you author from scratch

- The data (§5 step 4) and the scoring (§5 step 5).
- The vocabulary canon: statuses, severity tiers, hazard codes, investigation actions, disposition codes, product families, countries. Write it before the port or the reskin and never deviate from it; every display rule reads it.
- Three packet stories: a hero that holds for review (two concerning facts compound, score around 0.6), an escalation by policy (deadline inside the elapsed window), a straight-through (every fact favorable, 0.85 or higher). `packet-spec.md` §5 is the template; each story's hazard, device, site and timing must cohere.
- Agent instructions, both the Agent Studio triage agent and the Cortex agent.
- The semantic view's business vocabulary and five verified queries.
- The talk track and the presenter script.

---

## 9. Effort

Snowflake, either path: two to three days with the scripts as templates, most of it data and scoring.

Appian, Path A: a day to prepare the environment, import, make the post-import edits and smoke test; a day for the rename; three or four days for the conversion in step 8, most of it the clock and the agent. Path B: three or four Kiro sessions for the port plus the same reskin.

Then a day on the packet and verification and a day on the talk track and script. Path A lands in about two weeks of part-time work; Path B closer to three.

---

## 10. Ask Scott for

- (From Daniel Mackenthun, not Scott.) A Snowflake user on the partner account, `FINSERVADMIN` granted, `COMPUTE_WH` as its default warehouse, and the `LIFESCI` database created and granted to `FINSERVADMIN` (§5 steps 1 and 2).
- Whether a second Appian environment exists for you (§1). This one question decides a week of work.
- `run_inference.sql`, `semantic_view.yaml` and `agent_config.sql` from the Snowflake kit (not in this repo).
- Path A: the export with precedents added, the import customization file template, and the DDL of the `SO_` tables from NY's Cloud Database console. Path B: the Kiro template link and a walkthrough of the session loop, if you want the sessions to do the port.
- Read access to the source repository if it has gone private.
- Before the export, three values moved out of the source build's SAIL and into constants, so the customization file sets them per environment: the console's baseline count, the two persona usernames, the analyst persona's desk. Small session; without it, Path A step 5 edits them by hand.
- A read of your vocabulary canon and your three stories before you build; those two documents decide whether the port lands first time.

---

## 11. Prompt: generate the baseline data and the views

Give this to Claude as one message. It is complete; nothing from this guide needs to be pasted with it. Run the script it returns in Snowsight as `FINSERVADMIN`.

```
I am building an Appian + Snowflake demo for medical device post-market surveillance: complaint hazard, harm and severity classification with human review. Write me ONE Snowflake script, runnable top to bottom in a Snowsight worksheet as role FINSERVADMIN, warehouse COMPUTE_WH, that creates my tables, fills them with generated baseline data, and creates five compatibility views. Nothing in this script may reference the database FINSERV; it exists on the same account and belongs to someone else.

CONTEXT YOU NEED
The demo copies an existing settlements demo whose Appian application reads five Snowflake tables through record types. Those record types will be imported unchanged and will look for views named like the original tables, with the original column names and types, in schema LIFESCI.TRADE_SETTLEMENT. My real tables live in LIFESCI.COMPLAINT_QUALITY under my own names. The views translate. The Appian side never writes to these tables; every write comes through stored procedures I will add later. Keep column names exactly as listed below, because the view definitions and later scripts depend on them.

SCHEMA: LIFESCI.COMPLAINT_QUALITY (create or replace each table)

SITES  (50 rows; stands in for COUNTERPARTIES)
  SITE_ID VARCHAR(20) primary key, 'SITE' + 3 digits
  NAME VARCHAR(100), realistic hospital, clinic, distributor and field-service names, no real organizations
  TYPE VARCHAR(20): hospital, clinic, distributor, field_service
  REGION VARCHAR(10): NA, EMEA, APAC, LATAM (keep these exact codes; the imported screens map them)
  RISK_TIER VARCHAR(10): high, medium, low (lowercase; the imported screens map them)
  HISTORICAL_SERIOUS_RATE FLOAT, 0.02 to 0.25, correlated with RISK_TIER (high 0.15 to 0.25, medium 0.07 to 0.15, low 0.02 to 0.07); the book-wide average lands near 0.09
  QUALITY_CONTACT_NAME VARCHAR(100), QUALITY_CONTACT_PHONE VARCHAR(30)

DEVICES  (200 rows; stands in for INSTRUMENTS)
  DEVICE_ID VARCHAR(20) primary key, 'DEV' + 4 digits
  CATALOG_NUMBER VARCHAR(20), e.g. 'BSC-7714-02'
  NAME VARCHAR(100), plausible device names (stents, catheters, guidewires, leads, implantable pulse generators, endoscopes), no real product names
  PRODUCT_FAMILY VARCHAR(20): stent, catheter, guidewire, lead, implantable, endoscope
  UDI_DI VARCHAR(14), 14-digit numeric device identifier
  DEVICE_CLASS VARCHAR(5): I, II, III, with III about 30 percent
  COMPLAINT_RATE_PER_1000 FLOAT, 0.1 to 8.0
  LABEL_COUNTRY VARCHAR(3): ISO 3166 alpha-3 of the labeling country, mostly USA, DEU, IRL, JPN

COMPLAINTS  (50,000 rows; stands in for TRADES)
  COMPLAINT_ID VARCHAR(20) primary key, 'CMP' + 6 digits starting at 000001. Never generate an id starting with 'CMP9'; that prefix is reserved for demo packets.
  RECEIVED_DATE DATE, spread over the 24 months ending 60 days ago, weekdays only
  REPORTING_DEADLINE DATE: RECEIVED_DATE plus 30 days for COUNTRY 'USA' (FDA MDR), plus 15 days otherwise (EU MDR serious incident timeline); use the same rule for every row so the clock is explainable
  DEVICE_ID VARCHAR(20) foreign key to DEVICES
  SITE_ID VARCHAR(20) foreign key to SITES
  SOURCE VARCHAR(20): PATIENT, HCP, SALES_REP, FIELD, weighted toward HCP
  UNITS_AFFECTED NUMBER(18,2): units in the affected lot, log-normal-ish between 1 and 50,000, most under 500
  COUNTRY VARCHAR(3): ISO 3166 alpha-3 of the incident country, about 55 percent USA, the rest spread across DEU, GBR, FRA, JPN, AUS, BRA, CAN
  DAYS_SINCE_AWARENESS NUMBER(6,2): days between the firm becoming aware and this record, 0.5 to 20, right-skewed, median about 2
  INVESTIGATOR_ID VARCHAR(20), 'INV' + 3 digits, 30 distinct
  PRODUCT_LINE VARCHAR(20): CARDIO, ENDO, NEURO, UROLOGY, PERIPHERAL, consistent with the device's PRODUCT_FAMILY (stents and guidewires mostly CARDIO and PERIPHERAL, endoscopes ENDO, leads and implantables NEURO or CARDIO)
  LOT_SIZE NUMBER(18,0): the full lot, at least UNITS_AFFECTED
  NARRATIVE_VALIDATED BOOLEAN, true for 97 percent
  VALIDATED_AT TIMESTAMP_NTZ: RECEIVED_DATE at a business-hours time, in UTC; write all TIMESTAMP_NTZ values as UTC wall clock, never from CURRENT_TIMESTAMP cast to NTZ, because the Appian side reads NTZ as UTC and this session's time zone is not UTC
  EVENT_NARRATIVE VARCHAR(4000): a two to four sentence templated narrative that fits the hazard assigned in COMPLAINT_HISTORY (see below), varying device, setting, patient age band and outcome; at least 40 distinct templates across the hazard codes

COMPLAINT_HISTORY  (50,000 rows, exactly one per complaint; stands in for SETTLEMENT_HISTORY; this is the closed outcome of each baseline complaint)
  COMPLAINT_ID VARCHAR(20) foreign key, unique
  SITE_ID VARCHAR(20), copied from the complaint
  STATUS VARCHAR(20): CONFIRMED_SERIOUS or CLOSED_NOT_SERIOUS; about 13 percent CONFIRMED_SERIOUS overall, with the probability of serious rising with the site's HISTORICAL_SERIOUS_RATE, DEVICE_CLASS III, and SOURCE = HCP
  HAZARD_CODE VARCHAR(40): one of exactly four codes, mechanical_fracture, electrical_fault, contamination, labeling_use_error, on every row (the predicted and confirmed hazard; the demo's screens show it through a display rule, so store the code, never a label); mechanical_fracture most common for stents, guidewires and leads, electrical_fault for implantables and leads, contamination for catheters and endoscopes, labeling_use_error spread thin
  DAYS_PAST_DEADLINE NUMBER(6,0): 0 for most rows; 1 to 25 for about 8 percent, more often when STATUS is CONFIRMED_SERIOUS
  CLOSED_DATE DATE: REPORTING_DEADLINE plus DAYS_PAST_DEADLINE, minus a few days when DAYS_PAST_DEADLINE is 0, never before RECEIVED_DATE

COMPLAINT_PREDICTIONS  (50,000 rows, one per complaint; stands in for TRADE_PREDICTIONS; a model's view before the outcome was known)
  COMPLAINT_ID VARCHAR(20) foreign key, unique
  SERIOUS_PROBABILITY FLOAT in 0 to 1: a heuristic score, computed in SQL, from the site's HISTORICAL_SERIOUS_RATE (strongest), DEVICE_CLASS, DAYS_SINCE_AWARENESS relative to the days available before REPORTING_DEADLINE, UNITS_AFFECTED, and SOURCE, plus noise, so that CONFIRMED_SERIOUS rows score higher on average but not perfectly
  PREDICTED_SEVERITY VARCHAR(10): Critical, High, Medium, Low, keep these exact stored codes (the imported screens map them to severity labels and open cases for High and Critical); assign by SERIOUS_PROBABILITY bands exactly: Critical 0.7507 to 0.95, High 0.5003 to 0.7495, Medium 0.25 to 0.4999, Low below 0.25; target distribution close to Critical 3.6 percent, High 21 percent, Medium 34 percent, Low 41 percent
  PREDICTED_HAZARD VARCHAR(40): equals the history row's HAZARD_CODE on 85 percent of rows, another of the four codes otherwise
  PREDICTED_HARM VARCHAR(40): one of tissue_trauma, arrhythmia, infection, delayed_procedure, no_harm, consistent with the hazard
  SCORED_AT TIMESTAMP_NTZ: SYSDATE()::TIMESTAMP_NTZ at generation time, the same value on every row
  TOP_RISK_FACTORS VARIANT: an array of exactly three objects {factor, contribution}, where element 0 is {'factor': 'Site Complaint Rate', 'contribution': 2.5 * the site's HISTORICAL_SERIOUS_RATE} as a FLOAT, and elements 1 and 2 are drawn from these fixed pairs by position: ('Device Class III', 0.05), ('Narrative Ambiguity', 0.05), ('Prior Recall', 0.05), ('Multiple Lots', 0.02), ('Low Base Risk', 0.02), ('Normal Operations', 0.01), ('Implant Duration', 0.03), ('Tight Reporting Window', 0.05); the pairs chosen must not contradict the row (a Low row does not carry Device Class III unless the device is class III)

VIEWS: LIFESCI.TRADE_SETTLEMENT (create or replace; schema LIFESCI.TRADE_SETTLEMENT already exists)
Each view selects from the table above and renames columns to the original names. Column types must be what the original record types expect: ids VARCHAR(20), dates DATE, timestamps TIMESTAMP_NTZ, probabilities FLOAT, money-like numbers NUMBER(18,2), booleans BOOLEAN. Column order does not matter.
  TRADES over COMPLAINTS: TRADE_ID = COMPLAINT_ID, TRADE_DATE = RECEIVED_DATE, EXPECTED_SETTLEMENT_DATE = REPORTING_DEADLINE, INSTRUMENT_ID = DEVICE_ID, COUNTERPARTY_ID = SITE_ID, DIRECTION = SOURCE, NOTIONAL = UNITS_AFFECTED, CURRENCY = COUNTRY, BROKER_CONFIRMATION_LAG_HRS = DAYS_SINCE_AWARENESS, TRADER_ID = INVESTIGATOR_ID, DESK = PRODUCT_LINE, QUANTITY = LOT_SIZE, IS_MATCHED = NARRATIVE_VALIDATED, MATCHED_AT = VALIDATED_AT
  TRADE_PREDICTIONS over COMPLAINT_PREDICTIONS: TRADE_ID = COMPLAINT_ID, FAIL_PROBABILITY = SERIOUS_PROBABILITY, RISK_TIER = PREDICTED_SEVERITY, SCORED_AT = SCORED_AT, TOP_RISK_FACTORS = TOP_RISK_FACTORS
  COUNTERPARTIES over SITES: COUNTERPARTY_ID = SITE_ID, NAME, TYPE, REGION, RISK_TIER, HISTORICAL_FAIL_RATE = HISTORICAL_SERIOUS_RATE, OPS_CONTACT_NAME = QUALITY_CONTACT_NAME, OPS_CONTACT_PHONE = QUALITY_CONTACT_PHONE
  INSTRUMENTS over DEVICES: INSTRUMENT_ID = DEVICE_ID, TICKER = CATALOG_NUMBER, NAME, ASSET_CLASS = PRODUCT_FAMILY, CURRENCY = LABEL_COUNTRY, AVG_VOLATILITY = COMPLAINT_RATE_PER_1000, MARKET_CAP_TIER = DEVICE_CLASS, ISIN = UDI_DI, CSD = 'FDA' for LABEL_COUNTRY 'USA' and 'EU-MDR' otherwise, TICKER_ORIG = CATALOG_NUMBER, NAME_ORIG = NAME
  SETTLEMENT_HISTORY over COMPLAINT_HISTORY: TRADE_ID = COMPLAINT_ID, COUNTERPARTY_ID = SITE_ID, STATUS = 'FAILED' when CONFIRMED_SERIOUS else 'SETTLED', FAIL_REASON = HAZARD_CODE, DAYS_LATE = DAYS_PAST_DEADLINE, ACTUAL_SETTLEMENT_DATE = CLOSED_DATE
I will check each view against the imported record types' field lists and add any column I have missed; leave a comment block at the top of the views section listing every column each view exposes.

RULES FOR THE SCRIPT
- Pure SQL, Snowflake dialect, no Python, no stored procedures, no stages or file loads. Use GENERATOR, UNIFORM, RANDOM, NORMAL where they help; seed nothing, but make distributions deterministic enough that rerunning gives the same shape.
- Idempotent: CREATE OR REPLACE for every table and view, so rerunning the whole script rebuilds the baseline from scratch.
- Set context at the top: USE ROLE FINSERVADMIN; USE WAREHOUSE COMPUTE_WH; USE DATABASE LIFESCI; USE SCHEMA COMPLAINT_QUALITY; and qualify every object name anyway.
- Referential integrity by construction: every COMPLAINTS.DEVICE_ID and SITE_ID exists; every history and prediction row has exactly one complaint; no orphans.
- Dates coherent: VALIDATED_AT on RECEIVED_DATE; CLOSED_DATE on or after RECEIVED_DATE; REPORTING_DEADLINE after RECEIVED_DATE.
- Narratives must never contain real patient, clinician, hospital or product names.
- Comment each section in one or two lines: what it builds and the shape it targets.
- END WITH EXACTLY ONE SELECT that returns a PASS/FAIL grid, one row per check, columns CHECK, EXPECTED, ACTUAL, RESULT, covering at least: row counts for all five tables (50 / 200 / 50,000 / 50,000 / 50,000); zero orphan foreign keys in each direction; SERIOUS_PROBABILITY within 0 and 1; every PREDICTED_SEVERITY in the four codes and each tier's probability range inside its band; tier shares within 3 percentage points of the targets; CONFIRMED_SERIOUS share between 11 and 15 percent; every HAZARD_CODE in the four codes; every REGION, RISK_TIER, SOURCE, PRODUCT_LINE and PRODUCT_FAMILY value in its list; no COMPLAINT_ID starting with CMP9; SCORED_AT within the last ten minutes in UTC; VALIDATED_AT on RECEIVED_DATE for every row; CLOSED_DATE never before RECEIVED_DATE; each of the five views selectable with the same row count as its table; TOP_RISK_FACTORS array length exactly 3 on every row. The last row of the grid is OVERALL with RESULT PASS only if every other row passed.

Return the script only, in one code block, with no prose before or after it.
```
