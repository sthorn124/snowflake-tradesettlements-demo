# Settlement Operations Demo — Build Plan
*Build-focused. Status as of Aug 27. ✅ = done and verified.*
*Re-planned 2026-11-11: the order from here is set in "Plan from 2026-11-11" below.*

## Demo Narrative

Domain and use case: capital-markets settlement operations — **Pre-Settlement Fail Prevention**. Snowflake predicts which trades will fail at trade date, Appian turns each prediction into governed remediation before cutoff, and resolved outcomes close the learning loop. Positioning, the three-act structure and the talk track live in `pre-settlement-fail-prevention-one-pager.md`; the Phase 5 packet stories (hero and two seeded stories) in `hero-trade-spec.md` and `packet-spec.md`. Not duplicated here.

## Personas and What Each Sees

`alex.analyst` (SO Analysts, desk EQ_FLOW — watchlist, Case Detail, record actions) and `sam.supervisor` (SO Supervisors — Supervisor Command, all desks); the presenting SC's own account in **both** `SO Demo Admins` (which is what makes the separate Demo Admin site appear) **and** `SO Supervisors` (which is what lets the console read the record types and intake run across all desks) — ruled 2026-09-24. Scope, groups and display vocabulary: `CLAUDE.md` project sections (Appian application; Display vocabulary; Demo Admin site). Whether the two personas are local-password accounts that sail can log in is not yet recorded (TODO).

The claude.ai Project reads this section when it authors the verification section of each build prompt, so this is where each persona's should and should-not see and do is written. Keep it current at close-out like the rest of the plan: when a build changes what a persona sees or can do, update this section in the same close-out.

## Data Model (entity level)

Snowflake, direct access, never synced: TRADES, TRADE_PREDICTIONS (1:1), COUNTERPARTIES (N:1), plus INSTRUMENTS and SETTLEMENT_HISTORY. Appian-native: SO Settlement Case (N:1 Trade, session-tagged), SO Case Comment, and record events. Field-level detail: `CLAUDE.md` project sections (Snowflake environment; Appian application).

## Plan from 2026-11-11

Ruled by Scott in the planning chat on 2026-11-11. This section sets the order. The phase blocks under Build Phases hold the detail.

**Build tool:** Claude Code (ruled 2026-11-11). `CLAUDE.md` loads the rule files in `.kiro/steering/`, which stay the one copy of the rules. Kiro's hooks and permission file do not run under Claude Code, and `CLAUDE.md` lists the rules a session has to hold itself.

**Order**
1. Phase 10, sync. No build.
2. Phase 11, demo setup experience.
3. The next phase is chosen after Phase 11.

**On hold:** Phase 7 (governance layer), Phase 8 (make the AI real), Phase 9 (late-trade live beat).

**Dropped:** the life sciences replication and the generic template. `maintenance/replicate-for-new-use-case.md` stays in the repo as a record and is not maintained.

**Parked**
- Generating the standing cases from Load. Proposed in chat on 2026-10-23 as "Phase 10, retire the fixture book" and never committed. Phase 11 re-dates the standing cases instead.
- Moving the three hard-coded values to constants (TODO, Replication section).
- Two SCs presenting at the same time.

**Candidates after Phase 11, order not ruled**
- The Phase 6.5 build. Its prompt was drafted 2026-10-09 and needs reissuing against the current repo.
- The hero story fix in the Snowflake packet (Phase 6.5, Hero story).
- Documents brought in line with the build (Phase 6.5, Documents). With Phase 7 on hold, the one-pager's Act 3 lines on the evaluation suite, AI guardrails, AI cost by desk and Process HQ describe work that is not built.
- Databricks (Phase 12).

## Build Phases

### Phase 0 — Foundation ✅ COMPLETE
- ✅ Snowflake stack deployed in FINSERV.TRADE_SETTLEMENT (schema, CSVs via stage+COPY, inference, semantic view, SETTLEMENT_RISK_AGENT, Streamlit dashboard)
- ✅ Verified: fail rate 12.83% (6,416/50,000); tiers Critical 1,824 / High 10,637 / Medium 16,995 / Low 20,544
- ✅ COMPUTE_WH created and granted; user default warehouse set
- ✅ MCP server TRADE_SETTLEMENT_MCP (trade_settlement_analyst + settlement_risk_agent); endpoint verified externally via curl tools/list
- ✅ Settlement Operations app in NY (SO prefix); SO Users / Analysts / Supervisors / Demo Admins groups
- ✅ SO Snowflake Data Source connected system (native 26.6 template); plugin connected system deleted
- ✅ SO Trade record type (TRADES, direct data access) — data rendering
- ✅ SO Trade Prediction record type; 1:1 Trade↔Prediction relationship on trade_id
- ✅ SO Snowflake MCP connected system; scratch agent discovers both tools

### Phase 0.5 — Dev tooling setup: Claude Code + dev MCP ✅ COMPLETE
- ✅ Create local project folder `settlement-ops-demo/` (MCP config inherited from root ~/.claude.json — dev MCP NY + docs MCP; nothing per-project needed)
- ✅ `CLAUDE.md`: copy the CPO demo's as the template, replace context — app conventions (SO prefix, naming, groups, objects built so far), Snowflake context (FINSERV.TRADE_SETTLEMENT objects; MCP tools + input schemas: trade_settlement_analyst→message, settlement_risk_agent→text), SAILGen lessons (multi-pass builds, DELETE-before-rebuild, cardLayout fallback, width vocabulary)
- ✅ Copy from CPO project if present: nothing to carry over — no `.claude/commands/`, no reusable mockup template. Skill layering handled separately by the 2026-08-27 restructure.
- ✅ `mockups/` folder created (mockups themselves build as the first step of Phase 4)
- ✅ `build-log.md` (now `BUILD_LOG.md`): created empty, filled as-built (feeds Phase 5 SC doc)
- ✅ Smoke test: one trivial object via dev MCP in NY before real build — SO_CONFIDENCE_THRESHOLD constant created + type-verified per appian-supplemental §1 (2026-08-27; see BUILD_LOG.md)
- ✅ 2026-09-21 — Repo retrofit to appian-devmcp-method conventions: git + private GitHub remote, merged CLAUDE.md (template core + project sections), template-owned files copied in, file names aligned (`BUILD_PLAN.md`, `BUILD_LOG.md`, `Closeout.md`), `prompts/NNN-<slug>.md` from 001, close-out ends in commit, push and push verification.

### Phase 1 — Finish the data layer — done except the network blocker
- ✅ 2026-08-27 — Scratch agent live-call test PASSED: "What is the overall settlement fail rate?" → 12.83% (6,416/50,000); saved as a test case in Agent Studio (seed of the eval suite). Trace: 3 tool calls / ~40s for a one-fact question — see build-log.md
- ✅ 2026-08-27 — SO Counterparty record type (COUNTERPARTIES, direct access); SO Trade N:1 SO Counterparty relationship
- ✅ 2026-08-27 — Record-level security on SO Trade: SO Supervisors all rows, SO Analysts desk = EQ_FLOW (hardcoded for the demo). Verified behaviorally per appian-supplemental §5 — logged in as alex.analyst (EQ_FLOW book) and sam.supervisor (50,000), counts confirmed
- ✅ 2026-08-27 — Demo users alex.analyst (SO Analysts) / sam.supervisor (SO Supervisors) created and group-assigned
- ✅ 2026-09-02 — **Mockup-driven data widening COMPLETE.** Snowflake: INSTRUMENTS +ISIN/+CSD with all 200 ticker/name identities rewritten to real-style values (200/200 distinct, every ISIN check-digit valid, 32 nulls = exactly the FX forwards); TRADES +QUANTITY/+IS_MATCHED/+MATCHED_AT; COUNTERPARTIES +ops contacts; SETTLEMENT_HISTORY +COUNTERPARTY_ID. Delivered as `snowflake/snowflake-mockup-columns.sql` and run by Scott in Snowsight. **Baseline invariants verified exact after the run: 6,416/50,000 = 12.83%; tiers 1,824 / 10,637 / 16,995 / 20,544.** Additive-only under the 2026-09-02 data-safety policy; TICKER/NAME snapshotted to TICKER_ORIG/NAME_ORIG before rewrite.
- ✅ 2026-09-02 — **Record model completed**: SO Instrument, SO Trade, SO Counterparty and SO Settlement History all carry the new columns (added in Designer — `addRecordTypeField` cannot map an existing external column); SO Settlement History → SO Trade ONE_TO_ONE (`68a4ae92`) and → SO Counterparty N:1 built, giving the recent-fails view its one-hop path. Both hand-built types verified against source table, field types, events, actions and security.
- [ ] **OPEN — BLOCKER.** Permanent network policy with Daniel (in progress; 24h bypass still the only network path). The one item keeping Phase 1 from closing; everything integration-dependent fails when the bypass lapses

### Phase 2 — Case management core (1 day)
- [ ] **Design decision (2026-08-27)** — Residual quantity on a partial settle: a partial that leaves quantity outstanding currently has to be recorded as `Settled - Partial Release`, which reads as a clean close in month-end analytics. Decide whether the demo needs a distinct code, or whether partials-with-residual are out of scope for the scripted packet
- ✅ 2026-08-28 — SO Settlement Case record type (UUID `09405a10-06c7-4368-9d5e-41a148dffd15`, table SO_SETTLEMENT). All fields verified by readback; `disposition` TEXT (owner's Designer fix), `assignee` USER (deliberate, beats spec); renamed from `SO Settlement`; `trade` N:1 to SO Trade; record-level security Supervisors-all / Analysts-EQ_FLOW. `caseID` AUTO_INCREMENT CONFIRMED 2026-08-28 (PK-omitted insert returned caseID=1); trade traversal proven at supervisor scope. Persona checks (alex vs sam) remain browser-only
- ✅ 2026-08-28 — SO Case Comment `c8cdbb02-1f27-4a90-933b-752f65b0f617` (commentText VARCHAR(4000) at creation, N:1 to case + `caseComments` reverse ONE_TO_MANY `b16380cf-82ae-42b1-a598-9982cfcaf49f`, RELATED_RECORDS security). Audit = native record events: Event History `eede988b-5576-4daa-a49c-fa962d90b16b`, 7 event types, RELATED_RECORDS added by hand. Cross-data-source traversal PROVEN by probe; caseID AUTO_INCREMENT confirmed; createdOn stamped by the write path (deliberate). Event comment width still UNMEASURED — carried to Phase 3 as its own task
- ✅ 2026-08-28 — `SO_remediationForReason` `_a-0000f04a-c437-8000-9c47-011c48011c48_561387`. a!match on the 4 canon reasons + Manual review fallback; null-safe. All 6 testRule cases pass (4 canon, garbage, null)
- ✅ 2026-08-28 — `SO_casePriority` `_a-0000f04a-c437-8000-9c47-011c48011c48_561393`. Returns Integer 1–100. All 4 harness checks pass: 55 / 34 / outranks / 85 as Number (Integer) from a past cutoff
- ✅ 2026-08-28 — Case record actions: Assign `53d0adce`, Add Comment `88f9539e`, Record Disposition `9201002c`, Escalate `0c98d8a9`. **Visibility expressions re-ruled 2026-09-09** (v19/v18/v20): Assign only while New/In triage/Awaiting review; Escalate hidden once escalated or resolved; **Record Disposition now SURVIVES escalation** — a supervisor closes an escalated case out with a disposition — and hides only on the two Resolved statuses. All null-guarded, because the record-view validator evaluates them with `rv!record` null. Four process models + four start forms; all drivable by testProcessModel and verified by per-record-type row counts. Surfacing on views/grids is Phase 4 (§9)
- [ ] **NEW (2026-08-28) — Phase 2 exit verification, browser-only.** No such item existed; added so the outstanding checks are tracked. (a) Click all four actions through as `alex.analyst`, including Record Disposition disappearing once the case is resolved; (b) confirm the analyst desk boundary (EQ_FLOW) as alex vs sam. **Neither is observable from the Dev MCP session — the design account is supervisor-scoped** — **still outstanding after the 2026-08-28 fifth pass; these two are the only Phase 2 items left.** Everything server-side is verified by row counts and a break-test
- ✅ 2026-08-28 — Event writes gated on business-write success across all four action models. Every business Write Records node wires ErrorOccurred/Error; an XOR gate sits before each event node. Proven by BREAK-TEST, not by a happy path: a forced write failure (`Data too long for column 'COMMENT_TEXT'`) returned COMPLETED with errComment=1 and wrote NO event row; restored and re-verified clean

### Phase 3 — Agent and process (1.5 days)
- ✅ 2026-09-01 — SO Triage Agent wired and verified live end to end. Context redesigned to process-side assembly (`SO_caseContext` `_a-…_561804`) after measuring that Agent Studio record-data tools do not traverse relationships (PROMOTED to appian-supplemental §11). Three lanes driven with the real agent on live trades: **escalate PROVEN** (case 13, credit case, no lane defect), **analyst PROVEN** (cases 11, 12), assessments citing real notional/counterparty/probability. Latency ~41s.
- ✅ 2026-09-01 — **Straight-through PROVEN end to end with the live agent.** Confidence 0.85 >= threshold 0.80 on a clean-facts specimen; case resolved with disposition Settled - Funding Received and the type-3 Straight-Through Resolution event written. Threshold unchanged at 0.80 — the apparent ceiling was a confidence-definition category error (fail probability folded into confidence), fixed in Agent Studio, worth +0.13 on a held-constant specimen. All three lanes now proven live
- ✅ 2026-09-01 — **Confidence discrimination PROVEN under v4** (clean 0.78 / concerning 0.35, spread 0.43, timing arithmetic stated in both assessments). The v3 failure where both scored 0.85 is fixed.
- ✅ 2026-09-01 — **v5 FINAL: both directions verified at threshold 0.80.** Clean specimen 0.87 → straight-through; concerning specimen 0.45 → escalated with the lag-vs-window arithmetic stated. Threshold never moved. **Phase 3 behavioral work complete; Phase 5 packet blocker lifted.**
- ✅ 2026-09-02 — **v6 FINAL: three specimens, five runs, all correct at threshold 0.80.** Clean TRD016924 **0.87 / 0.88 / 0.88** → straight-through ×3; concerning TRD044567 **0.35** → escalated; authored hero TRD9NY101 **0.62** → held for review with the timing arithmetic stated. v6 was needed because the v5 clean specimen was **straddling** the gate (0.78 and 0.87 six minutes apart), not because it regressed — caught by running a replicate before acting. Spread now **0.01**. Step 3 only; threshold never moved.
- ✅ 2026-09-02 — **XOR context guard added to `SO_triageCase` (node 8).** An unresolvable case context now halts before the agent node instead of producing a confident forged escalation. Break-tested: unresolvable caseId → COMPLETED in 4.2s, `agentOutputs: null`, `runId: null`, zero writes; normal path unaffected.
- ✅ 2026-09-02 — `SO_caseContext` extended to seven lines (adds INSTRUMENT, MATCHING, ONWARD DELIVERIES); `SO_penaltyAccrual` and `SO_onwardDeliveries` built and break-tested; `SO_remediationForReason` updated to `Arrange cover borrow / partial release` and all five branches re-verified.
- ✅ 2026-09-01 — Escalate lane event detail made reason-aware (node 23); verified live on a timing-escalated funding_gap.
- ✅ 2026-08-28 — One-call discipline written into `agent/instructions.md` as an explicit prohibition (not a preference), with the Phase 1 trace cited as its justification. Its trial is `agent/eval.md` section D; the staged tool-economy candidate resolves on that trace review
- ✅ 2026-08-28 — Two process models built and verified. `SO_createTriageCase` `0000f04e-fee5-8000-237d-7f0000014e7a` (per-session duplicate guard proven by double-run; Case Created event null-user/INTEGRATION). `SO_triageCase` `0000f04e-ff8f-8000-2381-7f0000014e7a` (3 lanes, all driven with stubs and verified by row counts; counterparty_default at confidence 0.95 correctly escalated, proving reason overrides confidence). Agent node still a placeholder
- ✅ 2026-08-28 — Confidence threshold constant wired live: `SO_triageCase`'s Route XOR and both the straight-through and referral event details read `cons!SO_CONFIDENCE_THRESHOLD`. Verified end to end — 0.95 routed straight-through, 0.60 referred with the stored detail naming both numbers
- ✅ 2026-08-28 — Event comment width MEASURED through the production Write Records node: **4000 characters** (300 stored 300; 4000 stored 4000, no truncation). The `getRecordType` VARCHAR(255) readback under-reports. CLAUDE.md cap note updated. **Follow-up in TODO.md:** the `left(..., 255)` caps in six models now clip and must be raised to 4000 (§7)
- [ ] Straight-through audit rendering (what the agent saw, tools called, why it cleared the gate)
- [ ] Eval test cases written per tool as built (inputs + expected outputs)

### Phase 4 — Workbench UX (1.5 days)
- [ ] **Mockups first** — one HTML mockup in `mockups/` per interface below (watchlist, case detail, supervisor view, admin/reset page) before any SAIL is written
- [ ] Analyst watchlist: Trade+Prediction join, priority-sorted, risk-tier tags
- ✅ 2026-09-09 — **Case detail BUILT and fix-passed** as the SO Settlement Case default `summary` record-type view (`SO_caseDetail`, populating the view's `uiExpr` — not a new site page, so the watchlist rail's "Open case →" already routes to it). Seven cards per `mockups/case_detail.html`: title row with a status-driven action bar upper-right, risk banner, trade & counterparty, exposure if fail, recent settlement fails, activity, and the agent-assessment / timing / ask rail. Record links to SO Instrument, SO Counterparty and SO Trade. Verified by render on five states (New, Awaiting review, Escalated, past-cutoff Escalated, Resolved · analyst), `diagnostics.error: null` on each. The four record actions render as **header shortcuts beside the Summary tab** (`relatedActionShortcuts` on the view, Related Actions tab hidden), not as an in-card bar. **Still open**: gate B browser pass — which now also owns the status→action mapping, since the header renders outside the view and no session can see it — and the ask panel is a deliberate shell (Phase 6).
- [ ] a!agentChatField in case view wired to SO Triage Agent
- ✅ 2026-09-09 — **Supervisor Command BUILT** (`SO_supervisorCommand`, site page gated on SO Supervisors). Six KPIs, cutoff runway (stacked bar), straight-through trend with an insufficient-data state, exposure-by-desk grid with rich-text VaR bars, reason mix with a computed insight footer, analyst queues including an Unassigned bucket, escalations grid with a composed "why escalated", and an inert Ask shell. **The runway/KPI coherence invariant is enforced structurally** — one query, one row set, every card a filtered view of it — and verified arithmetically across all six cards. **Still open**: browser pass, and the persona contrast (sam sees 5 desks, alex would see 1) can only be observed in a browser.
- ✅ 2026-09-09 — **Sites built.** `SO_SettlementOperations` (`settlement-ops`): Watchlist, Cases, Supervisor (gated `SO Supervisors`). `SO_DemoAdmin` (`settlement-ops-admin`): Admin, gated `SO Demo Admins` — a SEPARATE SITE by design, never a tab beside the watchlist. **Open**: the "Appian + Snowflake" header badge, and `SO Demo Admins` is EMPTY because group membership cannot be set over the Dev MCP (403) — one Designer edit. **Resolved 2026-09-10: Scott added the first member in Designer; record actions reordered so Record Disposition leads (verified by readback).** NOTE: `updateSite(pages:)` regenerated every page's URL stub when a page was added; re-check anything that hardcodes one. **Watchlist, Cases and Supervisor pages built 2026-09-09** (site v3, Supervisor gated on `cons!SO_SUPERVISORS_GROUP`). Admin page and the header badge remain. NOTE: `updateSite(pages:)` regenerated every page's URL stub when the third page was added — re-check anything that hardcodes a page URL.
- [ ] RLS working across both personas (alex vs sam logins)

- ✅ 2026-09-09 — **Demo Admin console built** (`SO_demoAdminConsole`): Verify Ready (nine read-only checks — baseline counts excluding reserved TRD9* rows, non-fixture sessions at zero with P4-VERIFY reported as a labelled line, one-row reachability probe per record type, and the agent's last run read from the audit trail rather than invoked), Reset Session (round trip proven on a throwaway tag; refuses P4-VERIFY by name; cascade to comments and events measured), and a disabled Simulate Feed stub. Snowflake-side cleanup rendered as an instruction, not a button.

- ✅ 2026-09-09 — **PHASE 4 BUILD SCOPE CLOSED.** Four gates built and ratified — A analyst watchlist, B case detail, C supervisor command, D demo admin — across two sites, thirteen interfaces and eighteen expression rules. Five items carried into Phase 5 with owners (see TODO): the `SO Demo Admins` first member, the record-action reorder, the logo re-home, the supervisor mockup update, and the Reset delete-click residual. Promotion checkpoint current: 10 candidates, 8 promoted, 1 superseded, 1 staged with a live trigger.

### Phase 5 — Simulation + repeatability (1 day)
- ✅ 2026-09-02 — **Hero trade authored as a packet trade, not adopted from baseline.** `hero-trade-spec.md` is the contract: reserved id scheme `TRD9<session><seq>` (baseline is all `TRD0…`, so collision is impossible), per-session reset predicates, the trade/case split that produces the ~3h cutoff reading, single-process intake with a swappable trigger, the `SIMULATE_FEED`/`RESET_SESSION` plan, and the Kafka path. `snowflake/hero-trade-insert.sql` + `hero-trade-delete.sql` are the manual equivalents. Verified live end to end: the hero triages to held-for-review at 0.62.
- [ ] Feed-arrival simulation: fixed scripted packet (~15 trades, 3 seeded high-risk) tagged with sessionId; triggers scoring + case creation
  - ✅ 2026-09-11 — **`SIMULATE_FEED` / `RESET_SESSION` created in Snowflake** (setup script run by Scott to its last statement).
  - [ ] **Part A evidence — `snowflake/verification-summary.sql`**: one statement returning one 25-check PASS/FAIL grid. Part B opens only on all PASS.
  - ✅ 2026-09-11 — **Snowsight deliverables canon RULED** (CLAUDE.md): every Snowsight deliverable returns its evidence as one grid; multi-grid verification blocks prohibited.
  - ✅ 2026-09-10 — **Packet predictions RULED baseline-shaped:** `TOP_RISK_FACTORS` authored on all 15 rows under the coherence rule (factors never contradict fail reason or lane); the hero's NULL precedent retired.
  - ✅ 2026-09-10 — **Case-creation criterion RULED: `RISK_TIER` High or Critical**, aligned to the semantic view's verified at-risk query. Documented in packet-spec §3 and CLAUDE.md; implemented as one tier check in the Part B intake model.
  - ✅ 2026-09-10 — **`MATCHED_AT` (trade-date evening), `SCORED_AT` (call time, UTC wall clock) and the id scheme (≤13-character run name, exact-id reset) RULED** and applied to packet-spec, hero-trade-spec and the procedures.
  - ✅ 2026-09-11 — **Part B1 — `SO Snowflake SQL API` connected system + `SO_simulateFeed` / `SO_resetSession` integrations.** PAT in, auth passing; body fixed to a self-built JSON string after the first test sent Appian map text (Snowflake 400 391917). **Scott's retest passed:** `SMOKE` → `OK run=SMOKE trades=15 predictions=15 high_or_critical=3`; reset → `OK run=SMOKE trades_deleted=15 predictions_deleted=15`.
  - ✅ 2026-09-22 — **Intake process model (Part B2) — BUILT 2026-09-11, DEFECT FOUND AND FIXED 2026-09-22.** The loop created one case per run because a flow returning to an already-fired XOR gateway never re-activates it; the loop now returns to the take-item script with the continue/stop gateway downstream of the increment. Verified on the live run: all three B2-TEST cases exist, one per story, and re-running the plan returns an empty `toCreate`. Originally: `SO_intakeRun` reads `SO_intakePlan` (High/Critical tier from the prediction rows, story attributes by sequence, already-cased trades excluded), creates each case through `SO_createTriageCase` and starts `SO_triageCase` per new case. `SO_createTriageCase` now has its caller.
  - ✅ 2026-09-22 — **Console wiring (Part B2), then SIMPLIFIED.** Load and Reset are live; the run name is now the fixed constant `SO_DEMO_RUN_NAME` (DEMO), both name fields are gone, a derived status line sits above the buttons, and the Snowflake message is demoted on success. Scott's remaining browser pass is in `Closeout.md` (d). Originally: Load ran, returned the procedure message verbatim and started intake; the second Load never reached Snowflake (message unknown — question for Scott); Delete was not exercised, because the run is deliberately still loaded. Originally: Load → `SO_simulateRun`; Delete → `SO_resetRun` (Appian first, then Snowflake); messages verbatim; placeholder `1012-ACME`; the `hero-trade-delete.sql` instruction removed. Run-name format is enforced by the procedures' REFUSED message and not re-checked in Appian (B1 ruling).
  - ✅ 2026-09-22 — **Deterministic escalation policy in `SO_triageCase`.** A breached window (broker lag > hours to cutoff) escalates ahead of straight-through and the analyst lane; the escalation event states the arithmetic and renders the fail reason through `SO_failReasonDisplay`. Four lanes break-tested on throwaway cases, all residue removed.
  - ✅ 2026-09-22 — **Console redesign (presentation pass).** Default healthy view cut from 312 words to 42: one-line readiness verdict, detail behind a collapsed Details section, panels 2 and 3 merged into one Run the demo card with captioned buttons. Reset enable verified to key on either side's demo rows.
  - ✅ 2026-09-23 — **Watchlist restructured to the v5 mockup.** Three stacked queues (NEEDS YOUR ACTION / ESCALATED — WITH SUPERVISOR / CLEARED THIS BATCH) replace the flat grid, with a Latest scoring batch band between the KPI strip and the queues. One definition of "open" feeds the KPI and both case queues, which partition it; one definition of "the batch" (SO Trade, reserved TRD9 range, desk-secured at the anchor) feeds the band, the cleared queue and the straight-through KPI. Verified loaded and reset; the rail was proven against the restructured queue through a pre-selected throwaway copy.
  - ✅ 2026-09-23 — **Console final copy.** One explainer box above both buttons replaces both captions; the status line carries the load timestamp, read from the packet's own `SCORED_AT` because process-written cases have a NULL `createdOn`; an amber line fires when the load predates today (rendered through an inverted-comparison throwaway).
  - ✅ 2026-09-24 — **FIXED: `SO_supervisorCommand` line 351, and the defect class swept.** The guard is on, symmetric with line 345 — but the guard alone would have drawn a line chart with a `null` category plotting a fabricated 100% → 33% fall, measured on a throwaway, so the empty cycle bucket is dropped too. A dateless resolved case is now counted in every figure (scope, STP %, penalties avoided, desk STP) and excluded only from the trend axis. Sweep of all 15 interfaces and 19 rules found **exactly one** unguarded site — line 351 — with the other five sites in the same file already correct. `sam.supervisor` now opens the Supervisor page with a demo loaded; previously HTTP 500.
  - ✅ 2026-09-24 — **RULED AND BUILT: the needs-action queue shows 6 nearest cutoffs, not 4.** The hero sits 4th of 9 by cutoff with two rows of headroom below it instead of being the last visible row. Footer copy derives from the same local, so it followed automatically.
  - ✅ 2026-09-24 — **RULED AND SWAPPED: the cycle trend groups by `resolvedOn`.** Both grouping reads moved together, guards kept. Measured rather than asserted (the card renders identically under either key): the demo's straight-through case keyed `''`/dropped under `modifiedOn` and `2026-09-24`/on-axis under `resolvedOn`; `dropped=1` → `dropped=0`. Also serves the analyst lane — a disposition writes `resolvedOn` too.
  - ✅ 2026-09-24 — **PART C RUN: full dress rehearsal, one sitting, no defect stopped it.** Whole lifecycle exercised twice as both personas with timings: press → Snowflake OK +9s → three cases at +21s/+36s/+44s → triage settled at **+88s**; analyst `Record Disposition → Settled - Borrow Executed` on the hero; double Load duplicated nothing; reset returned the environment to baseline line for line. The three-verb cleared vocabulary and the "without analyst touch" figure both held through the analyst action. Full observations in the 2026-09-24 close-out and BUILD_LOG. **Not cold-runnable yet** — see the rehearsal verdict: demo script, supervisor mockup refresh, Phase 6 Ask panels, SO Demo Admins process security.
  - ✅ 2026-09-24 — **Part C follow-ups landed, except the content ones.** `SO Demo Admins` now holds `initiator` on `SO_simulateRun` / `SO_intakeRun` / `SO_resetRun` (verified by independent readback), and the presenter's two-group requirement is written into `GETTING_STARTED.md`. The two human-only checks — Reset delete click and the console was/now line — are **closed by ruling** on three live human-clicked Resets plus verification-summary checks 20/21. The hero's scripted analyst action is **decided**: `Record Disposition → Settled - Borrow Executed`.
  - ✅ 2026-09-24 — **PRESENTER MODEL RULED AND ENFORCED IN THE CONSOLE.** A demo presenter holds **both** `SO Demo Admins` and `SO Supervisors`; the Demo-Admins-only reading is dead. `SO_demoAdminConsole` v12 preflights the second membership as its first evaluated expression and renders a single instruction card — **running zero record queries** — when it fails, replacing the whole-page crash a Demo-Admins-only account got. Measured: 19 ms for the card branch against 613 ms for the console. Line 232's naked consumer guarded as well. Propagated to CLAUDE.md:266/405, `GETTING_STARTED.md`, this file and TODO. **Open:** verification as `test.presenter` needs a sail session that does not exist.
  - ✅ 2026-09-24 — **MOCKUP AUTHORITY RULED; MATCHED-TIME GATE OPENED; FAILS-CARD GEOMETRY REBALANCED.** (1) A mockup is the structural authority only for the change built from it; at the gate authority transfers to the deployed screen and the mockup gets a **superseded header, not regeneration** — written into `CLAUDE.md`, applied to `mockups/supervisor_command.html`, and reconciled against §7's contrary clause. (2) `SO_caseDetail` **v9** opens the Matched stamp on the ruled condition — *authored on this clock*, implemented as a 7-day recency window because **every row on the instance reads `isMatched = Y`** and presence discriminates nothing; the stamp carries its day whenever it is not today's, since a packet trade matches on trade date and settles the next. (3) The fails card's five columns went relative (`2X/2X/3X/4X/2X`) after docs-search established that `AUTO` sizes to its own longest value rather than absorbing slack — `CLAUDE.md`'s contrary grid rule corrected in place — and the out-of-desk label shortened to "Other desk" with its framing moved into the summary line. Verified as two personas across three cases. **Open:** geometry is a browser check; the environment was found with a packet still loaded and was left that way.
  - ✅ 2026-09-24 — **Case-detail display honesty fixed.** The counterparty recent-fails card rendered a fabricated `0` for rows the viewer cannot read (desk-secured trades; a counterparty's fails span desks). Cause proven by reading the same card on the same case as both personas. Now `outside your desk view` + an em dash, with the dates, trade ids, reasons and the summary line — which every viewer can read — left intact.
  - [ ] **Part C content follow-ups, still open** — the demo script (the big one), the supervisor mockup refresh, and Phase 6 Ask panels.
- [ ] Session tagging end to end (cases, audit, resolution events)
- [ ] Reset Demo action (Demo Admins): delete session-tagged cases/children, cancel orphaned processes; Snowflake session-row cleanup proc — *2026-09-11: session-tagged cases/children + Snowflake packet rows now cleared by `SO_resetRun`; cancelling orphaned processes is still open.*
- [ ] Verify Ready action: baseline counts, zero open demo cases, MCP reachable, warehouse warm — green-checks screen
- [ ] SC setup doc: new-SC-from-zero (own Snowflake user, default warehouse, PAT, grants), reset/verify usage, known failure modes + fallbacks (pre-scored batch; REST DATA_AGENT_RUN path)

### Phase 6 — Supervisor analytics (0.5 day)
- ✅ 2026-09-24 — **Chip labels re-worded as natural-language questions** (ruled). Labels only: the question each chip sends, echoes and shows as a tooltip is byte-identical to Part 1d, and no other object changed. All six verified rendered through sail as the correct persona, all six tooltips confirmed carrying the full question. Length measured against the data — longest counterparty name `Iron Gate Securities` (20), longest asset class `FX forward` (10). **The risk is the SUPERVISOR labels, not the composed case ones:** that panel is a MEDIUM_PLUS rail where 32 characters is the only proven fit, and two labels are 40 and 42; the case panel is full-width, where Part 1d's 31 was never near its limit. Nothing shortened; shorter alternatives worded and banked in TODO. **Open:** geometry is Scott's browser check.
- ✅ 2026-09-24 — **PART 1d: chips redesigned, narration enforced downstream, agent v2 deployed.** Chips carry short complete labels with the full question in a `tooltip` (the documented cure for the truncation Scott reported — the parameter was simply never set) and use `style: "LINK"`, the lightest documented option. **Narration went from 5 of 21 runs to 0 of 18** — not by stronger prompt text but by filtering the response structure: keep only the text elements after the last `tool_result`, a boundary measured to hold across six captured runs. Agent v2 (run by Scott) closed both Part 1c canon defects: asset classes now render as display labels, and notional is reported per currency instead of as an unlabelled cross-currency sum. 18 verification runs, latency 12–32 s, four arithmetic reconciliations including a per-currency breakdown summing to 12,464 — Part 1c's High+Critical count. Also corrected `CLAUDE.md`: the book runs **seven** currencies, not four. **Open:** 1 of 18 referred to a table; one mislabelled denominator; uppercase button labels need a Designer tick-box.
- ✅ 2026-09-24 — **PART 1c: instructions verified by readback; stability bar run at 21 live calls; environment restored.** `instructions.response` matches the authored text exactly (847 chars) with every other field identical — `MODIFY LIVE VERSION` edited in place. **The 46s failure did not reproduce** (5 clean runs) and no ceiling below 120s exists on this path; not a timeout. **Facts were stable on all six questions across all three runs**; four narrate on 1–3 runs, which is instruction compliance rather than question wording. One question replaced with measured evidence (3/3 narration → 1/3) and because its old wording asked about "risk factors" while the agent answered with fail reasons. Latency **12–36 s**, down from 22–45 s. Arithmetic reconciled four ways, including Sup Q3 reporting **+1 High / +2 Critical against baseline — exactly the loaded packet**, proving a live read. **Open:** residual narration, raw enums in prose, an uncurrencied house total.
- ✅ 2026-09-24 — **PART 1b: Ask relocated to case detail, click feedback delivered, answer quality authored.** The trade-scoped Ask moved off the watchlist (where scope came from a grid selection and could silently empty) onto `SO_caseDetail`, replacing an inert shell that already sat after the agent assessment — the case is the page there, so scope cannot drift. Chips are composed from the case's own counterparty, asset class and notional. **Click feedback solved**: the documented keyword is `loadingIndicator`, not the `enableLoadingIndicator` Part 1 read off a component tree and wrongly concluded was absent; every ask path is now a button that spins and disables on press. `SO_askAnswerText` strips markdown and normalises blank lines. `snowflake/agent-instructions.sql` authored (one `ALTER AGENT` statement, whole spec restated to preserve it) and **awaiting Scott**. **Open:** case chip 3 failed its only run; hero-with-packet unverified.
- ✅ 2026-09-24 — **PART 1: both Ask panels wired live to Snowflake Cortex** via `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` over the existing SQL API connected system and PAT — **zero new Snowflake objects**, because the agent and the semantic view already existed. One shared `SO_askPanel` serves both screens; scope is the only parameter that differs. The analyst panel is NEW (that side never had one, in build or mockup) and sits at the foot of the queues by ruling. Three live grounded answers reconcile to the recorded 6,416/50,000 baseline. Failure path break-tested: plain one-liner, page survives. **PARTIAL — 3 of 6 questions, once each; the three-run bar, the hero-with-packet check and all geometry remain open (see TODO).**
- [ ] Wire 3 verified-query questions (fail rate trend, top failing counterparties, notional at risk) as suggested prompts in a supervisor Ask panel (agentChatField scoped to analyst tool)
- [ ] Verify answers against worksheet ground truth; add to eval suite

### Phase 6.5 — Case outcome and audit trail (added 2026-09-25, found in demo prep; committed to the plan 2026-10-13 from the drafting chat)

Agent card and Activity panel
- [ ] SEVERE for the governance story: an analyst's disposition note renders inside the agent card, under "SO Triage Agent", replacing the agent's own rationale (observed 2026-09-25, case SO-99). Suspected cause: the card shows the latest case comment rather than the agent-authored one. Confirm before fixing. Fix: the agent card shows only agent-authored rationale.
- [ ] The disposition note is saved (SO Case Comment, by design) but never appears in the Activity panel, which reads only case events. Merge case comments into the Activity feed in time order, attributed to the analyst.
- [ ] Event text shows raw stored codes ("insufficient_securities" in the Case Created and agent-assessed entries). Route through SO_failReasonDisplay per the display-vocabulary canon (same class as the open escalate-path item).
- [ ] "Disposition: ... by scott.thorn@appian.com" shows the username in the body while the entry header already shows the display name. Drop the "by <username>" tail.
- [ ] Two "Agent Triage Complete" entries at the same minute say nearly the same thing. Consolidate to one entry (decision, confidence vs gate, proposed fix), or give them distinct titles.

Resolution panel
- [ ] A resolution card directly under the trade banner, shown only on resolved cases: disposition, resolved by (analyst name, or "the agent" for straight-through), resolved at, and "Resolved <Xh Ym> before cutoff" (the live countdown freezes into this once resolved).
- [ ] One row comparing the agent's proposal and confidence with the final disposition (accepted as proposed / different outcome chosen).
- [ ] The analyst's disposition note renders here, attributed to the analyst. Together with the agent-card fix, this is where human reasoning lives on the case.
- [ ] Banner while resolved: no live countdown, no "Urgent" state; the agent card's hold reasoning stays as history.
- [ ] Verify on both paths: the hero after Record Disposition with a note, and story 03 straight-through.

Watchlist (added 2026-10-09)
- [ ] Needs Your Action sorts by time to cutoff only, so low-risk rows with earlier clocks and rows already past cutoff sit above the hero (observed 2026-09-25: hero below the top 6). Sort by risk and time together, as the one-pager promises ("risk × time-to-cutoff"). Do not sort by created date: the batch tag and band already mark new arrivals.
- [ ] Rows past their cutoff are realized fails, not prevention work. Move them out of Needs Your Action into a compact "Missed cutoff" line, with a count and view-all.
- [ ] Verify the hero ranks first with a demo loaded, at two different times of day (fixture cutoffs are fixed clock times, so the order currently shifts through the day).

Hero story
- [ ] The hero's scripted analyst action is now Record Disposition → Settled - Partial Release (ruled 2026-09-25; supersedes Borrow Executed in TODO).
- [ ] The hero is a BUY, so the agent's proposed "cover borrow" only makes sense if the firm has an onward sale of those shares. Before client ops audiences, fix the packet story: give the hero an onward sale in the settlement window (the case page's onward-deliveries card would then show it), or make the hero a sell where our own desk is short.

Documents
- [ ] One-pager Act 1 says the demo shows "a feed arrival scores new trades in real time"; the demo now opens on the finished batch (ruled 2026-09-23), with the live moment moved to Phase 9. The architecture section says the agent's tools come from Snowflake's MCP server; the Ask panels run through Snowflake's SQL API. Bring both lines in line with the build, or rule them as intended roadmap.
- [ ] TODO sweep: close items resolved weeks ago that still read as open (Part A grid run, check-12 ruling, the check-12 pair count, the deleted SO_zz_probeQuery, the ZZ-CLICK question, the superseded Borrow Executed decision).

### Phase 7 — Governance layer (1 day; ON HOLD from 2026-11-11)
- [ ] Evaluate tab: full test suite (Phases 3+6), bulk run, accuracy metrics
- [ ] AI Guardrails configured in Admin Console
- [ ] Usage groups per desk; AI Actions consumption attribution
- [ ] Process HQ on SO Create Fail Case: automation-type view + resolution-time KPI
- [ ] Single architecture slide: the loop, two governance boundaries, zero data movement

### Phase 8 — Make the AI real (1–1.5 days; ON HOLD from 2026-11-11)  ← the "genuinely model-driven" work
- [ ] Run 02_ml training in a Snowflake notebook → TRADE_FAIL_CLASSIFIER registered in Model Registry
- [ ] Rewrite run_inference.sql: TRADE_FAIL_CLASSIFIER!PREDICT_PROBA replaces the SQL heuristic; heuristic kept commented as documented fallback; re-verify tier distribution, adjust thresholds if the model's spread differs. **Write `SCORED_AT` explicitly as `SYSDATE()`** — the column defaults to `CURRENT_TIMESTAMP()`, the Pacific session clock, which Appian reads as UTC (measured 2026-09-10)
- [ ] On-demand single-trade scoring exposed as a custom MCP tool; wired into SO Triage Agent + feed simulation (live scoring on arrival)
- [ ] Stretch (cut first): Kafka event intake — trades.pending consumer trigger + Publish Event resolution loop-back to Snowflake

### Phase 9 — Late-trade live beat (later, ruled 2026-09-25; committed to the plan 2026-10-13 from the drafting chat; ON HOLD from 2026-11-11)
- [ ] One late trade booked mid-demo with ~40 minutes to cutoff: scored, case opened, agent decision made, and landing at the top of Needs Your Action within about a minute. The drama is the cutoff clock, not rows appearing.
- [ ] A second one-trade packet in Snowflake whose cutoff is set relative to the moment of the press, plus one "Book a late trade" button on the Demo Admin console.
- [ ] Slots mid-Act 1, after the hero. Optional beat; the aftermath opening stands without it.

### Phase 10 — Sync (no build; planned 2026-11-11)

The last build session on record is 2026-09-24. NY was changed after that without a close-out. On 2026-10-22 and 2026-10-23: a watchlist sort fix, a hand re-date of the standing cases, the "Cleared this batch" card hidden in Designer, and blank cases left by a Reset that ran during triage. No Kiro session has run on this repo. A Claude Code session on 2026-10-23 made the fixture re-date commit (`1e21f5f`, pushed 2026-11-11) while the repo had no `CLAUDE.md`.

- ✅ 2026-11-11: `CLAUDE.md` added as a loader for the rule files in `.kiro/steering/`, so Claude Code sessions start with the rules. Scott's local folder and GitHub brought level (the local plan edit discarded as already on GitHub, the re-date commit pushed).

- [ ] Planning chat: bring the repo's records up to date. The 2026-11-11 plan commit is the first part. Still to do: sweep `TODO.md` (about 80 open boxes, many already done); close the stale Snowflake network-policy blocker lines here and in `deploy-notes.md`; tick the boxes in Phases 3 to 6 that are built but unticked; regenerate `PROJECT_INSTRUCTIONS.md` for Claude Code and the Databricks context.
- ✅ 2026-11-11: Scott, in Claude Code: a short read-only session on NY. It confirms the rules loaded through `CLAUDE.md`, reads the Demo Admin console and the four process models Phase 11 changes, and lists the blank cases. It ends with a close-out and a push. The prompt is `prompts/001-phase10-read-only-audit.md`. Result: the rules loaded; the console and the four models are unchanged since 2026-09-24; no case without a trade exists on NY (17 cases, ids 36 to 52). The answers are in `Closeout.md` under "Inputs for Phase 11".
- [ ] Scott: bring the Dev MCP setup level (found in the audit). Ruled 2026-11-12: not before Phase 11, because the local server and NY's plugin already match and only the repo's reference notes are behind. NY's plugin and the local server are 26.9.5, the pins in `reference/toolchain.md` describe 26.6.105, and the App Market has 26.9.15. Say "run the update procedure".
- ✅ 2026-11-12: Install the master copy of the skills for Claude Code (found in the audit). Ruled 2026-11-12: the copies under `~/.kiro/skills/` are the master; the Phase 11 session copies them over `~/.claude/skills/` and into the repo. `~/.kiro/skills/` holds Version 2026-11-10.4, `~/.claude/skills/` holds 2026-10-28 and is the one Claude Code loads, and the repo holds 2026-10-05.2. `~/.claude/skills/appian` is also one bundle behind the server. Done in the Phase 11 session: `~/.claude/skills/appian-supplemental` is Version 2026-11-10.4, `~/.claude/skills/appian` is bundle `274ce627`, and the repo copy of the supplemental is the same file.
- ✅ 2026-11-12: Planning chat: correct two build parameters in `.kiro/steering/project.md` (found in the audit). The design account's username on NY is `scott.thorn@appian.com`, and `SO Supervisors` is not a member of `SO Analysts`.
- [ ] Scott, in Snowsight: run `snowflake/verification-summary.sql` as FINSERVADMIN on COMPUTE_WH and paste the grid.
- [ ] Scott: paste the regenerated `PROJECT_INSTRUCTIONS.md` block into the claude.ai Project, once the planning chat has regenerated it.
- ✅ 2026-11-12: Planning chat: the Project's three demo scripts (15-minute script, 10-minute talk track, 5-minute video script) overwritten from the repo copies. The one-pager was already the same and was left. Each Project copy was checked against the repo at every line Phase 11 changed, not character by character.
- [ ] Scott: make the repository private, then confirm a new Project chat can still read `Closeout.md`.

Rulings open
- ✅ Ruled 2026-11-12: the repo is the master copy of the demo documents, and the Project's copies are overwritten from it. The talk track's header now says so; its Claude Doc original is no longer kept current.
- [ ] Not ruled: whether the replication guide (`demo-docs/replicate-for-new-use-case.md`) is removed from the Project.
- [ ] This build stays in its own repo for now. Moving it into the SC workspace repo waits.

Staying in sync afterwards: NY changes only through a build session that ends in a pushed close-out. A hand change in Designer gets a TODO line the same day.

### Phase 11 — Demo setup experience (ruled 2026-11-11; build prompt `prompts/002-phase11-one-button-setup.md`, 2026-11-12)

Goal: one presenter action sets the demo up, and the console cannot be driven into a bad state. The scope comes from failures observed around the 2026-10-23 client demo. It is not a console redesign.

Console (`SO_demoAdminConsole`)
- ✅ 2026-11-12: One button, **Prepare the demo**. It clears the last run, re-dates the standing cases, loads a fresh run and starts intake. The separate Load and Reset buttons leave the page. Console version 14. The button starts `SO_prepareRun`, which answers in about 5 seconds and prepares in the background.
- ✅ 2026-11-12: One status line with six states and this copy (four ruled 2026-11-11; the last two added with the 2026-11-12 rulings): Rendered on console version 14 in five real states (Ready, Running, Nothing loaded, Story out of place, Did not finish), each with this copy and its colour; Loaded before today was read from the rule only.
  - Nothing loaded: "No demo loaded." Button enabled.
  - Running: "Preparing the demo. About two minutes. Refresh this page to check." Button disabled.
  - Ready: "Ready to present. Loaded today at <time> by <first and last name>." Button enabled. The name is the account that pressed Prepare for the run now loaded (ruled 2026-11-12, `prompts/003-ready-margin-watchlist-totals.md`); when the run record names nobody the line ends at the time.
  - Loaded before today: "Loaded before today. Prepare the demo again for fresh dates." Button enabled.
  - Did not finish: "The last run did not finish. Prepare the demo again." Button enabled.
  - Story out of place: "Not ready. The <hero | escalation | straight-through> case is <its status>, not <its scripted status>. Prepare the demo again." Button enabled.
  - Hero past cutoff (a seventh state, added 2026-11-12 on Scott's "Yes, add it"; the words are the session's): "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again." Amber. Button enabled. `SO_demoRunState` version 3; the console is unchanged at version 14 and rendered the line.
  - Hero under two hours to cutoff (the same state, a second wording, ruled 2026-11-12): "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." Amber. Button enabled. `SO_demoRunState` version 4. Both hero wordings are now ruled.
- ✅ 2026-11-12: The button is disabled for the whole run, from the press until all three stories have an agent decision. The state reads Running from the press, because `SO_prepareRun` records the start before it answers. Rendered during a run: the button's `disabled` is true; in every other state rendered it is false.
- ✅ 2026-11-12: A run that dies partway unlocks itself. After 5 minutes with no finish, the console treats the run as over and enables the button (press to Ready measured at 73 and 78 seconds in the audit). Measured on the rule with one story left "New": Running at 239 seconds, Did not finish at 302. A Prepare whose background half died before loading unlocks the same way, by the age of its run record; that path was built and not forced.
- ✅ 2026-11-12: The status line counts real demo cases only. On 2026-10-23 it read "Demo loaded" with 0 trades and 5 cases, because cases with no trade behind them were counted. The console counts cases whose session id is the run name, through `SO_demoRunState`.
- ✅ 2026-11-12: The console drops its "agent OK" check (ruled 2026-11-12). The standing cases satisfy it, so it cannot fail. The top line's verdict word becomes "Environment OK" / "Environment problem", so the page has one "Ready". No agent text on the verdict line and no agent row in Details. The verdict reads "Environment OK" / "Environment problem".
- ✅ 2026-11-12: One rule, `SO_demoRunState`, gives the run's state to the console and to Prepare. Prepare refuses to start while a run is in progress. The rule is built and `SO_prepareRun` reads it: a start while the state was Running was refused in 1.1 seconds with no step run. The console reads it from version 14.
- ✅ 2026-11-12: No progress bar and no self-refreshing page (ruled 2026-11-11). The presenter refreshes the page to see Ready, and the Running copy says so. Nothing of either kind was built.

Follow-up: the Ready line and the watchlist's totals (ruled 2026-11-12; build prompt `prompts/003-ready-margin-watchlist-totals.md`)
- ✅ 2026-11-12: Ready ends when the hero case has under two hours to its cutoff, about 65 minutes after a load. The two hours is one named value in `SO_demoRunState` (version 4). Measured on a real run with the clock set through `testRule`: Ready 121 minutes before the cutoff, the new line 119 minutes before, the existing line after it. The console (version 14, not edited) rendered both lines, and a Prepare started from the new state ended in Ready.
- ✅ 2026-11-12: The Ready line names who loaded the run, by first and last name, read from the run's `SO Demo Run` row. Rendered on the console: "Ready to present. Loaded today at 12:25 PM by Scott Thorn."
- ✅ 2026-11-12: The watchlist's two money totals convert each row through `SO_fxToUsd` before adding (`SO_analystWatchlist` version 24). Before: 662.5M and 354.6M on the watchlist against 698.4M and 393.7M on the supervisor screen, in the same second, over the same 16 open items. After: 698.4M and 393.7M on both. Both tiles carry the conversion basis in their tooltip. `SO_supervisorCommand` was not edited.
- ✅ 2026-11-12: The saved copy of `SO_analystWatchlist` is the deployed source again (it was three versions behind).
- ✅ 2026-11-12: The "Cleared this batch" card is not on the watchlist: hidden by hand on 2026-10-23 (`showWhen: "false"`, version 23). Found 2026-11-12 and ruled the same day: "Edit the documents". The card stays hidden. The demo script and the video script no longer send the presenter to it, and the talk track quotes the band instead of the card. Four lines across the three files.
- ✅ 2026-11-12: `nick.bethune` holds `SO Demo Admins` only and `nick.bethune@appian.com` holds `SO Supervisors` only; they are two accounts. Found 2026-11-12 in the group readback and closed the same day by Scott's ruling, "don't worry about nick bethune users". No membership was changed.

Follow-up: two fixes from Scott's browser check (2026-11-13; build prompt `prompts/004-console-press-and-batch-tag.md`)
- ✅ 2026-11-13: The console shows "Preparing" straight after the press. Cause: `SO_demoRunState` is read once per page, because a rule's local variables do not re-evaluate when the page variable that calls it refreshes (Appian docs; not measured by a session, which cannot press). Fix: the page holds its own press and shows the rule's Running view from it; the button stays disabled on that page. `SO_demoAdminConsole` version 18 (15 is the change; 16 and 17 were probes, restored), `SO_demoRunState` version 5 (a `whenRunning` output; lines unchanged). Both press outcomes were rendered on the real page by a one-line probe. The press itself is Scott's check.
- ✅ 2026-11-13: No time beside the demo trade ids on the watchlist (`SO_analystWatchlist` version 25). The Latest scoring batch band keeps its time. Render compared with version 24 leaf by leaf: the two tags gone, nothing else but the clock.
- ✅ 2026-11-13: Scott's browser check of `prompts/004` on NY: "other stuff looks good". He also found that the watchlist's countdowns do not go down while the page is open, and accepted it: "that's fairly standard for appian. the screen doesn't usually auto refresh." No fix (`.kiro/steering/project.md`, Working style).

Standing cases
- ✅ 2026-11-12: Prepare re-dates the 17 standing cases (the hand-authored P4-VERIFY cases, reported as ids 36 to 52) relative to now: the cutoff, the created and updated times, the resolved time on the resolved cases, and the times on their comments and events, so each case history still reads in order. The cases are re-dated. They are not generated and not deleted. Done by `SO_redateStandingCases`, which `SO_prepareRun` starts between the reset and the load. After each of two Prepare runs every case, comment and event time equalled what the old script produces for the same hour.
- ✅ 2026-11-12: The one deliberate past-cutoff case stays past cutoff. After every run, case 39 was the only standing case past cutoff.
- ✅ 2026-11-12: The re-date is its own process model, `SO_redateStandingCases`, called by Prepare. `fixtures/p4-verify-redate.py` and its CSVs are superseded by it, and the per-session ritual becomes "run `SO_redateStandingCases`". Built with two rules, `SO_standingCaseOffsets` and `SO_standingCaseRedate`. The script says it is superseded, and `project.md` names the model as the per-session ritual.

Agent write-back and cleanup
- ✅ 2026-11-12: `SO_triageCase` writes the agent's result only if its case still exists. Cause of the 2026-10-22 blank cases: Reset ran while triage was still running, and the late write created a case with no trade, desk or cutoff. This replaces the earlier idea of cancelling in-flight triage processes. Node 14, "Case still exists?", straight after the agent node (version 18.0). Reproduced first on 14.0: the late writes re-created the deleted case under its own id with a status, remediation and score and nothing else, plus one comment and two events. On 18.0 the same test wrote nothing and the process ended; a case left alone routed and wrote as before. The description no longer says "stub".
- ✅ 2026-11-12: Delete the blank cases left from 2026-10-22 (reported as SO-106 to SO-110). Closed by Scott's ruling with nothing to delete. The Phase 10 audit (2026-11-11) found none on NY: the case table held 17 rows, ids 36 to 52, each with a trade. No session deleted them on record; who removed the five is an open `TODO.md` item.
- [ ] Cancel the two `SO_triageCase` instances that are stuck ACTIVE (found in the audit): process `536912644` from 2026-10-22, case 105, agent run failed; and process `536908653` from 2026-08-28, case 5. Neither case exists any more. Ruled 2026-11-12: cancel both. The Dev MCP cannot cancel an instance, so Scott does it by hand in Process Monitoring. Not urgent once the triage guard is in.
- ✅ 2026-11-12: **The page would wait 34 seconds for Prepare (found and ruled 2026-11-12).** Scott ruled "Start without waiting". Prepare is now two models and a record: `SO_prepareRun` answers in about 5 seconds (4.95, 5.55, 5.20 on three runs) after writing a row to the new record type `SO Demo Run`, and `SO_prepareRunSteps` runs the reset, the re-date and the load in the background and closes the row. `SO_demoRunState` reads the row, so the state is Running from the press and a failed step's message survives a page refresh.
- [ ] **Reset leaves each run's assessment comments in the table (found 2026-11-12).** `SO_resetRun`'s delete removes the cases and their audit events. The comments stay, hidden, because a comment is readable only through its case. Measured once. Rule whether Reset deletes the comments first, and whether the rows already left behind are cleaned up. `SO_resetRun` was not edited.
- [ ] Decide what a failed agent run leaves behind (found in the audit). The agent node has no error path, so a failed run stops triage there and the case stays "New". This is the "run that dies partway" the console has to unlock from. Ruled 2026-11-12: no error path in this phase. The 5-minute unlock covers it, and the next Prepare clears the case. Read 2026-11-12: the deployed node type, `internal3.execute_ai_agent`, has no error output and no pause-on-error input. The newer type, `internal3.execute_ai_agent_v2`, declares `Success` and `ErrorMessage` outputs; moving to it needs a pick in Designer and was not tried.

Investigate before fixing
- [ ] The hero case landed in Escalated instead of Needs your action on one Load on 2026-10-22. The cause is unknown. Observe and report before any change. Audit, 2026-11-11: by the Route node's conditions, on a normal run the hero reaches Escalated only through the agent's own `escalate` flag. When it recurs, read the case's Escalated event and the triage instance's `agentOutputs` within seven days, before the instance is archived. Ruled 2026-11-12: the routing is left alone. Ready shows only when each story is in its scripted queue, so a miss is seen before presenting. On 2026-11-12 the hero landed in Pending Analyst on both Prepare runs, at a score of 0.62.

Documents
- ✅ 2026-11-12: `demo-script-15min-client-awareness.md`, `talk-track-10min-internal.md` and `video-script-5min.md` describe Load and Reset as two buttons. Update them to the one-button flow in the same phase. (`GETTING_STARTED.md` does not name the buttons; checked 2026-11-12.) Eleven lines changed across the three files; nothing else in them was touched.

Proposed by the planning chat, not ruled
- ✅ Ruled 2026-11-12, now in scope above: Ready also requires each of the three stories to sit in its scripted queue. If one does not, the line names it and says to prepare again.
- [ ] Ruled 2026-11-12, in `prompts/003-ready-margin-watchlist-totals.md`: the Ready line names who loaded the demo, so a second SC can see that someone else's run is live before pressing. Note 2026-11-12: `SO Demo Run` now stores who pressed Prepare (`startedBy`), so this needs only the line.
- ✅ Ruled 2026-11-12 ("Yes, add it"), now in scope above: Ready does not look at how old today's load is (found 2026-11-12). A run loaded at 2 AM still reads "Ready to present" at 9 AM with the hero's cutoff past. Built the same day: Ready ends when the hero case's cutoff passes. Measured on the live run: Ready 22 seconds before the cutoff, "Not ready" 38 seconds after it.

- [ ] Ruled 2026-11-12: Ready ends when the hero case has under two hours to its cutoff, in place of ending at the cutoff. The hero stops fitting its window about 1h55m after a load. Both wordings of the line are ruled. New line before the cutoff: "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." Prompt `prompts/003-ready-margin-watchlist-totals.md`.
- [ ] Ruled 2026-11-12: the watchlist's cross-currency totals go through `SO_fxToUsd` before they are added. Found by reading the saved source after the audit reported 698.4M on the supervisor screen against 662.5M on the watchlist. Same prompt.

The status-line copy above is the contract for the build prompt.

### Phase 12 — Databricks (scoped 2026-11-11; approach proposed, not ruled)

Environment, as reported by Scott on 2026-11-11 and not yet verified from NY
- A Databricks workspace on AWS. Catalog `capital_markets`, schema `trade_settlement`. Scott owns the schema. The workspace admin owns the catalog.
- Personal access tokens are disabled in the workspace, so Appian connects as a service principal with an OAuth secret. Scott granted it USE SCHEMA and SELECT on the schema. USE CATALOG is the catalog owner's grant.

Approach proposed by the planning chat
- Duplicate record types in NY: five Databricks-backed record types beside the five Snowflake-backed ones. Nothing existing changes.
- The platform is chosen on the Demo Admin console before a run: Snowflake, both, or Databricks. "Both" reads predictions from Databricks and everything else from Snowflake.
- Reads that reach trade data through the case become platform-aware. Counted in `.work/` on 2026-11-11: 144 field references from SO Settlement Case through its `trade` relationship, in `SO_caseDetail`, `SO_analystWatchlist`, `SO_supervisorCommand` and `SO_caseContext`.

Gates, all open
- [ ] NY offers the Databricks connected system. Appian documents it from release 26.10.
- [ ] The service principal connects from NY and a record type reads one table.
- [ ] An expression accepts a record field reference returned by a rule. This decides whether the four objects change once or need a deeper rewrite.
- [ ] One timed read across Snowflake and Databricks at 50,000 rows.

Steps, not started
- [ ] Copy the five tables into `capital_markets.trade_settlement`, verified by one PASS/FAIL grid.
- [ ] Five Databricks record types with their relationships and desk security.
- [ ] The platform setting, platform-aware reads, and the provenance mark and header badge by platform.
- [ ] "Both" mode.
- [ ] Databricks-only mode: Load and Reset procedures, and the Ask panel on Genie.

## Open dependencies
- Daniel: permanent network policy (only hard blocker)
- Daniel: FWA package export (optional accelerant for Phases 3–4 patterns)

**Critical path: 1 → 2 → 3 → 4 → 5. ~6 build days core; +1.5 for Phase 8. Phases 6–7 slot anywhere after 3.**

*From 2026-11-11 the order is set by "Plan from 2026-11-11" above.*
