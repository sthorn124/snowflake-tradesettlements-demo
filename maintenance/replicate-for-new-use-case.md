# Replicating the Appian + Snowflake demo for a new use case

*Written 2026-10-22 for the Boston Scientific complaint-classification build (hazard / harm / severity with human review). Everything below was checked against this repo and the NY environment on that date. Scott owns the original; questions about it go to him.*

The settlements demo is a pattern, and the pattern is what you are copying: Snowflake holds the data and scores it, Appian turns each score into a case with an owner and a deadline, an AI agent handles the confident cases, people handle the rest, policy overrides the agent when a window is breached, and every decision is on the record. The complaint use case fits that pattern closely. This guide says what to copy, what to recreate, what to author, and how to keep the two builds apart.

---

## 1. Isolation rules

Both builds share the Snowflake account and the NY Appian environment. These rules keep yours from touching Scott's.

**Snowflake**

- Build in your own schema under `FINSERV` (this guide uses `FINSERV.COMPLAINT_QUALITY`; pick any name). `FINSERVADMIN` can create schemas. Never write to `FINSERV.TRADE_SETTLEMENT`.
- Every procedure, view and agent you create names your schema explicitly. Copy Scott's scripts and change the `USE SCHEMA` line and every qualified name; a procedure that inherits the session schema is one worksheet mistake away from the wrong table.
- Use your own Snowflake user and your own PAT, restricted to role `FINSERVADMIN`. Set your default warehouse (`ALTER USER <you> SET DEFAULT_WAREHOUSE = COMPUTE_WH;`) or record types fail with "no active warehouse".
- `COMPUTE_WH` is shared and X-Small. Two demos at the same time will contend. If you present often, ask Scott about a second warehouse.
- Your demo run ids use a different reserved prefix. Scott's packet trades are `TRD9…`; use `CMP9…` so a stray query can never confuse the two.

**Appian (NY, same environment)**

- Create a new application with a new prefix. This guide uses `CQ` (Complaint Quality); pick any two letters no other NY application uses. Object names are unique across the environment, so the prefix is what separates the builds.
- Do not import the Settlement Operations package. An import on the same environment is not a copy; it overwrites Scott's objects, because they carry the same UUIDs.
- Do not Save As over an `SO_` object, and do not edit any `SO_` object "just to see". Save As from an `SO_` object into a new `CQ_` name is fine; that is how you copy process models.
- Your own groups, connected systems, sites and constants. Do not add yourself to the `SO` groups to test; test as your own personas.
- The record type wizard will show `TRADE_SETTLEMENT` beside your schema. Always pick yours.

---

## 2. What transfers, and how

| Layer | Reuse | How | You author |
|---|---|---|---|
| Snowflake tables | Structure | `GET_DDL` on Scott's schema, replace the schema name, keep the column names, run | The data |
| `SIMULATE_FEED` / `RESET_SESSION` procedures | Logic, validation, idempotency | Copy `snowflake/simulate-reset-procedures.sql`, change schema and id prefix, replace the 15 `VALUES` rows | Your 15-row packet |
| Semantic view | Structure | `DESC SEMANTIC VIEW` on Scott's, rewrite names, synonyms and verified queries, create from YAML | Business vocabulary, 5 verified queries |
| Cortex agent | Spec shape, instruction rules | `DESCRIBE AGENT`, then `snowflake/agent-instructions-v2.sql` adapted | Domain instructions |
| Scoring | Approach | Heuristic SQL (Scott has `run_inference.sql` from the Snowflake kit) or Cortex `AI_CLASSIFY` over the narrative | Thresholds, tier bands |
| Appian record types (5 on Snowflake) | Nothing copies; the wizard regenerates them from your tables in minutes | Same column names give the same field names automatically | Relationships, row security |
| Appian record types (2 native) | Field list | Recreate from the list in §4 | Nothing |
| Interfaces (18) and rules (20) | All of the SAIL | Port `.work/*.sail` by UUID and prefix substitution (§4, step 6) | Labels and vocabulary |
| Process models (4) | Structure | Save As from `SO_`, re-point every node | Nothing |
| Agent Studio agent | Instructions, tool design | Recreate from `agent/instructions.md` and `agent/tools.md` | Domain instructions |
| Demo Admin console and site | SAIL | Ported with the interfaces | Nothing |
| Packet stories | The contract | `packet-spec.md` and `hero-trade-spec.md` as templates | Your 3 stories |
| Talk track and scripts | Structure and beats | `talk-track-10min-internal.md`, `demo-script-15min-client-awareness.md` | Every line |

The honest summary: the Snowflake side copies with search-and-replace; the Appian side is a port, mechanical but a port. On the same environment there is no copy-the-app shortcut.

---

## 3. Use-case mapping

Keep the column names. Appian never shows a column name on screen (every label is set in the interface), the semantic view gives Cortex business names over physical columns, and identical names let the Appian port map fields automatically. Rename tables freely; the record type wizard picks the table. If you rename columns anyway, keep a two-column mapping file (old name, new name); the port needs it.

| Settlements | Complaints | Column(s) | Powers this demo beat |
|---|---|---|---|
| `TRADES` | `COMPLAINTS` | Table rename only | Everything |
| Trade id | Complaint id | `TRADE_ID` | Row identity, packet ids `CMP9<run>01..15` |
| Trade date | Date received | `TRADE_DATE` | Batch band |
| Expected settlement date | Regulatory reporting deadline (FDA MDR 30 days from awareness; EU MDR 15 days for a serious incident) | `EXPECTED_SETTLEMENT_DATE` | The cutoff clock on every screen |
| Instrument | Device model / catalog number | `INSTRUMENT_ID` → `DEVICES` | Device card, "by product family" questions |
| Counterparty | Reporting site or facility | `COUNTERPARTY_ID` → `SITES` | The history card ("recent incidents from this site") and the agent's confidence |
| Direction (BUY/SELL) | Complaint source (patient, HCP, sales rep, field) | `DIRECTION` | Display only |
| Notional | Units affected (lot size) | `NOTIONAL` | "Value at risk" becomes "units at risk" |
| Currency | Country of origin | `CURRENCY` | Display; the "by currency" chip becomes "by country" |
| Broker confirmation lag | Days since awareness | `BROKER_CONFIRMATION_LAG_HRS` | The policy escalation: lag against the window |
| Desk | Product line | `DESK` | Row-level security: investigators scoped by product line |
| Matched / matched at | Narrative validated / validated at | `IS_MATCHED`, `MATCHED_AT` | Stage 1 validation, shown as a stamp |
| `TRADE_PREDICTIONS` | `COMPLAINT_PREDICTIONS` | Table rename only | |
| Fail probability | Model confidence that the complaint is serious or reportable | `FAIL_PROBABILITY` | The score on every row |
| Risk tier (4) | Predicted severity (keep 4: Minor, Serious, Critical, Catastrophic; a 5th tier means touching the tier rules) | `RISK_TIER` | Case creation: Critical and Catastrophic open cases |
| Top risk factors | Predicted hazard and harm, as `{factor, contribution}` | `TOP_RISK_FACTORS` | Agent context; optional columns `PREDICTED_HAZARD`, `PREDICTED_HARM` are cleaner |
| Fail reason (4 codes) | Hazard category (4 codes, e.g. `mechanical_fracture`, `electrical_fault`, `contamination`, `labeling_use_error`) | `FAIL_REASON` on history and cases | Reason → action rule, display rule |
| Remediation per reason | Investigation action per hazard (engineering failure analysis, electrical safety test, sterility review, IFU review) | Rule `CQ_actionForHazard` | The agent's proposal |
| Disposition codes | Final classification outcome (`Classified - Accepted as Proposed`, `Classified - Severity Raised`, `Classified - Severity Lowered`, `Reportable - MDR Filed`, `Not Reportable`, `Escalated - Safety Board`, `Deadline Missed`) | Constant | Record Disposition action |
| `SETTLEMENT_HISTORY` | `COMPLAINT_HISTORY` (prior complaints per device or site, final severity, days to close) | `FAIL_REASON`, `STATUS`, `DAYS_LATE`, `ACTUAL_SETTLEMENT_DATE` | The history card |
| Confidence gate at 0.80 | Accept-all above the gate; human adjudication below | `CQ_CONFIDENCE_THRESHOLD` | Act 3 governance |
| Window breached escalates by policy | Reporting deadline inside the elapsed window escalates to the safety board by policy | `CQ_triageCase` | The "AI advises, rules decide" beat |

Two things in the Boston Scientific document do not become demo beats. Stages 2 and 3 (async dispatch, webhooks, retries, backoff) are plumbing; the demo opens on a scored batch and Load simulates the intake, exactly as Scott's does. Stage 5's e-signature is a talk-track line on the disposition action, not a build item for v1.

---

## 4. Appian, step by step (NY)

Work through the Kiro method Scott uses: clone the `appian-devmcp-method-kiro` template for your build repo, then copy these from this repo into a `reference/settlement-source/` folder as porting sources: `.work/`, `snowflake/`, `agent/`, `packet-spec.md`, `hero-trade-spec.md`, `mockups/`, `.kiro/steering/project.md`. Your Kiro sessions do the mechanical work below against the Dev MCP; you do the Designer work it cannot (connected systems, record type wizard, groups, sites, Agent Studio).

**Step 1. Application, groups, sites (Designer).**
- Application `Complaint Quality`, prefix `CQ`.
- Groups: `CQ Users` (parent) > `CQ Investigators`, `CQ Supervisors` (supervisors also members of investigators); `CQ Demo Admins` outside the tree.
- Sites: `complaint-quality` (pages Queue, Cases, Supervisor) and `complaint-quality-admin` (Demo Admins only). Two sites, never a tab.
- A presenter holds both `CQ Demo Admins` and `CQ Supervisors`. The console preflights the second; copy that logic, it is in `SO_demoAdminConsole.sail`.

**Step 2. Connected systems (Designer).**
- `CQ Snowflake Data Source`: the native 26.6 "Snowflake Data Source" template, not the AppMarket "Snowflake" tile. Account Name is the bare identifier `a2770166725871-appian_partner`, role `FINSERVADMIN`, your user, your PAT as the password.
- `CQ Snowflake SQL API`: HTTP connected system to `https://a2770166725871-appian-partner.snowflakecomputing.com`, bearer auth with your PAT, one `Bearer` prefix. Load, Reset and Ask all run through this one; Scott's is `SO Snowflake SQL API`, and `SO_simulateFeed` and `SO_askSnowflake` show the request shapes.

**Step 3. Record types on Snowflake (Designer wizard, direct access, never sync).**
- `CQ Complaint` (COMPLAINTS), `CQ Complaint Prediction` (COMPLAINT_PREDICTIONS, 1:1 on complaint id), `CQ Device` (DEVICES, N:1), `CQ Site` (SITES, N:1), `CQ Complaint History` (COMPLAINT_HISTORY).
- Relationships: Complaint → Prediction (1:1), Complaint → Device (N:1), Complaint → Site (N:1), Site → History (1:N), Complaint → History (1:N).
- Record-level security on `CQ Complaint` only: investigators by `DESK` (product line), supervisors see all. Scott's rule hardcodes the demo analyst's desk; do the same for your demo investigator.
- Write down every record type UUID and field UUID (`getRecordType` over the Dev MCP returns them). The port needs them.

**Step 4. Appian-native record types (Designer, new table in the cloud database).**
- `CQ Complaint Case`: caseId, complaintId, sessionId, status, failReason (hazard code), proposedRemediation (investigation action), confidenceScore, disposition (text, codes only), assignee (User), desk, cutoffTs, createdOn, resolvedOn. Record events generated (Event History and Event Type); add `RELATED_RECORDS` security on the event record types by hand; disable commenting on the app.
- `CQ Case Comment`: caseId, author, commentText, createdOn (a plain datetime stamped by the Add Comment write path, not auto-managed).
- The 7 event types, seeded at configuration time: Case Created, Agent Triage Complete, Straight-Through Resolution, Assigned, Comment Added, Disposition Recorded, Escalated.

**Step 5. Constants.** Recreate these ten under your prefix: `CQ_CONFIDENCE_THRESHOLD` (0.80), `CQ_DEMO_RUN_NAME` (`DEMO`), `CQ_DISPOSITION_CODES` (your list from §3), `CQ_ANALYSTS_GROUP`, `CQ_SUPERVISORS_GROUP`, `CQ_PM_SIMULATE_RUN`, `CQ_PM_RESET_RUN`, `CQ_SNOWFLAKE_LOGO` (point at the same PNG document Scott's uses, or upload your own), `CQ_MARK_USE_LOGO`, `CQ_PENALTY_BP_PER_DAY` (rename to whatever your "cost of another day" is, or drop the penalty card).

**Step 6. Port the rules and interfaces (Kiro session, Dev MCP).**
- Source: the 38 files in `.work/` (20 `rule_SO_*.sail`, 18 `SO_*.sail`).
- Build a substitution map: every `recordType!{uuid}` and every `.fields.{uuid}` / `.relationships.{uuid}` in those files, keyed by the name that follows the UUID, mapped to your UUIDs from step 3 and 4 by the same field or relationship name (or by your rename mapping). Then `SO_` → `CQ_` on every `rule!`, `cons!` and object name.
- Apply the map to every file, then create the objects in this order: display-vocabulary rules first (`statusDisplay`, `riskTierDisplay`, `failReasonDisplay`, `assetClassDisplay`, `regionDisplay`, `quantityDisplay`), then the other rules, then interfaces. Each object is verified by reading it back, not by the create call succeeding.
- Rewrite the vocabulary canon in the display rules before anything renders: statuses, severity tiers, hazard codes, actions, dispositions, product families, regions.
- `SO_fxToUsd`, `SO_penaltyAccrual` and `SO_onwardDeliveries` are settlements-specific; port them anyway and decide later whether a complaints equivalent exists (units at risk, days of exposure, related complaints on the same lot).

**Step 7. Integrations.** `CQ_simulateFeed` and the reset call point at your procedures; `CQ_askSnowflake` calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` with your agent name and the structured messages body. Keep Scott's extraction logic (only the text elements after the last tool result); it is what stops the agent narrating on screen.

**Step 8. Process models (Designer, Save As).** `SO_simulateRun`, `SO_intakeRun`, `SO_resetRun`, `SO_triageCase` → Save As `CQ_…`, then open every node and re-point record types, rules, constants, integrations and the agent. `CQ_triageCase` carries the governance logic: the policy escalation before the gate (your version: elapsed days against the reporting deadline), the confidence XOR, the straight-through write, the investigator task. `SO_intakePlan` (the tier check that decides which scored complaints open cases) ports as a rule in step 6.

**Step 9. Agent Studio.** Recreate the triage agent from `agent/instructions.md` (deployed v6) with your domain in place of settlements, and the two tools from `agent/tools.md`: the context rule (`CQ_caseContext`, one query, six labeled lines) and the action rule (`CQ_actionForHazard`). No write tool; the process writes. Keep the confidence semantics: only concerning facts lower it, favorable facts never do, the timing arithmetic is mandatory.

**Step 10. Record actions on `CQ Complaint Case`.** Record Disposition, Assign, Escalate, Add Comment. The forms are in `.work/` and port in step 6.

**Step 11. Reskin.** Labels on every interface, the site header badge, the Snowflake mark (reuse `SO_snowflakeMark` as ported; it is a fragment rule and previews broken in Designer by design). Density and type follow Scott's mockups; replace the vocabulary, keep the layout.

**Step 12. Verify as personas.** Investigator sees only their product line; supervisor sees all; the console loads 15 complaints and opens 3 cases; the hero holds for review below 0.80; the escalation story escalates by policy regardless of score; the straight-through story resolves; Reset returns to baseline, line for line.

---

## 5. Snowflake, step by step

**Step 1. Access.** Your own user on the partner account, default warehouse `COMPUTE_WH`, role `FINSERVADMIN`, a PAT restricted to `FINSERVADMIN` with the expiry written down. Never work as `ACCOUNTADMIN`.

**Step 2. Schema.** `CREATE SCHEMA FINSERV.COMPLAINT_QUALITY;`

**Step 3. Structure.** In Snowsight: `SELECT GET_DDL('SCHEMA', 'FINSERV.TRADE_SETTLEMENT');`. Save the output, replace `TRADE_SETTLEMENT` with your schema everywhere, rename the five tables, drop the Streamlit app and the stage if you load data another way, and run it. Keep the column names (§3). `TRADES` has three columns Scott added later (`QUANTITY`, `IS_MATCHED`, `MATCHED_AT`); `INSTRUMENTS` has four (`ISIN`, `CSD`, `TICKER_ORIG`, `NAME_ORIG`); `COUNTERPARTIES` two (`OPS_CONTACT_NAME`, `OPS_CONTACT_PHONE`); `SETTLEMENT_HISTORY` one (`COUNTERPARTY_ID`). `GET_DDL` includes them all.

**Step 4. Data.** Generate it in Snowflake with `GENERATOR` and `UNIFORM`/`RANDSTR`, or in a script and load through a stage with `COPY INTO`. Sizes are yours; Scott's are 50 sites, 200 devices, 50,000 complaints, 50,000 history rows, one prediction per complaint. Shapes the screens depend on:
- `FAIL_PROBABILITY` in 0 to 1; `RISK_TIER` exactly your four values; the tier bands documented.
- `SCORED_AT` written as `SYSDATE()::TIMESTAMP_NTZ`. Appian reads `TIMESTAMP_NTZ` as UTC, and the Snowsight session is Pacific, so `CURRENT_TIMESTAMP()` cast to NTZ is seven hours wrong.
- `FAIL_REASON` and `DESK` as fixed enums, exactly as the display rules expect.
- Narratives: templated text per hazard category is enough for the screens; `SNOWFLAKE.CORTEX.COMPLETE` can generate varied ones for the packet.
- Deadlines coherent with elapsed days, so the policy escalation has real cases to fire on.

**Step 5. Scoring.** Two options. The simple one is a heuristic SQL insert like Scott's `run_inference.sql` (ask him for the file; it came in the Snowflake kit and is not in this repo). The better one for your story is Cortex `AI_CLASSIFY` over the narrative to produce the hazard, with a severity rule on top; then the sentence "Snowflake Cortex classified every complaint" is literally true. Score a smaller baseline if LLM cost matters (5,000 complaints reads fine on every screen). Either way the insert is `TRUNCATE` then `INSERT`, so rerunning restores pristine predictions.

**Step 6. Procedures.** Copy `snowflake/simulate-reset-procedures.sql`. Change the `USE SCHEMA` line, the table names, the id prefix (`TRD9` → `CMP9`), and the fifteen `VALUES` rows to your packet (3 stories that open cases, 12 background rows below the case floor). Keep the validation, the exact-id delete list, the idempotency and the `SYSDATE()` stamps. Verify with a copy of `snowflake/verification-summary.sql`: one statement, one PASS/FAIL grid.

**Step 7. Semantic view.** `DESC SEMANTIC VIEW FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS;` gives the structure. Rewrite the YAML with your tables, business names and synonyms, and five verified queries that match your Ask chips (overall serious rate, top sites by serious rate, severity distribution, serious rate by product family, units at risk for Critical and Catastrophic). Create it with `CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('FINSERV.COMPLAINT_QUALITY', $$<yaml>$$, FALSE);` pasted as one block. Verify with `DESC SEMANTIC VIEW`, not `SHOW`; a truncated paste creates a partial view that reports success.

**Step 8. Agent.** `DESCRIBE AGENT FINSERV.TRADE_SETTLEMENT.SETTLEMENT_RISK_AGENT;` for the spec shape. Create yours over your semantic view, then adapt `snowflake/agent-instructions-v2.sql`: display labels never stored codes, no sums across incomparable units (your version: never sum units across product families), no narration, no references to charts or tables. Smoke test with `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` and the structured messages body (`deploy-notes.md` has it). Run each chip question three times before it goes on a screen; an answer that changes substance between runs is replaced.

**Step 9. Grants.** Your PAT's role needs `SELECT` on the semantic view and `USAGE` on the agent and the procedures. `FINSERVADMIN` owns everything it creates, so membership covers it today.

---

## 6. What you author from scratch

- The data (step 4) and the scoring (step 5).
- The vocabulary canon: statuses, severity tiers, hazard codes, investigation actions, disposition codes, product families, countries. Write it before the port and never deviate from it; every display rule reads it.
- Three packet stories: a hero that holds for review (two concerning facts compound, score around 0.6), an escalation by policy (deadline inside the elapsed window), a straight-through (every fact favorable, 0.85 or higher). `packet-spec.md` §5 is the template; each story's hazard, device, site and timing must cohere.
- Agent instructions, both the Agent Studio triage agent and the Cortex agent.
- The semantic view's business vocabulary and five verified queries.
- The talk track and the presenter script.

---

## 7. Effort

Snowflake: two to three days with the scripts as templates, most of it data and scoring. Appian: three or four Kiro sessions for the port plus a reskin pass, then a day on the packet and verification. Talk track and script, a day. Plan on two weeks of part-time work to a demo another SC could run.

---

## 8. Ask Scott for

- `run_inference.sql`, `semantic_view.yaml` and `agent_config.sql` from the Snowflake kit (not in this repo).
- The Kiro template link and a walkthrough of the session loop, the close-out and the verification harness.
- The Snowflake logo document, or permission to point your constant at it.
- A read of your vocabulary canon and your three stories before you build; those two documents decide whether the port lands first time.
