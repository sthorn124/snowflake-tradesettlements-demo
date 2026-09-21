# Settlement Operations Demo — Build Plan
*Build-focused. Status as of Aug 27. ✅ = done and verified.*

## Demo Narrative

Positioning, the three-act structure and the talk track live in `pre-settlement-fail-prevention-one-pager.md`; the Phase 5 packet stories (hero and two seeded stories) in `hero-trade-spec.md` and `packet-spec.md`. Not duplicated here.

## Personas and What Each Sees

`alex.analyst` (SO Analysts, desk EQ_FLOW — watchlist, Case Detail, record actions) and `sam.supervisor` (SO Supervisors — Supervisor Command, all desks); the presenting SC's own account in `SO Demo Admins` for the separate Demo Admin site. Scope, groups and display vocabulary: `CLAUDE.md` project sections (Appian application; Display vocabulary; Demo Admin site). Whether the two personas are local-password accounts that sail can log in is not yet recorded (TODO).

## Data Model (entity level)

Snowflake, direct access, never synced: TRADES, TRADE_PREDICTIONS (1:1), COUNTERPARTIES (N:1), plus INSTRUMENTS and SETTLEMENT_HISTORY. Appian-native: SO Settlement Case (N:1 Trade, session-tagged), SO Case Comment, and record events. Field-level detail: `CLAUDE.md` project sections (Snowflake environment; Appian application).

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
  - [ ] **Intake process model (Part B2) — BUILT 2026-09-11, awaiting Scott's live pass.** `SO_intakeRun` reads `SO_intakePlan` (High/Critical tier from the prediction rows, story attributes by sequence, already-cased trades excluded), creates each case through `SO_createTriageCase` and starts `SO_triageCase` per new case. `SO_createTriageCase` now has its caller.
  - [ ] **Console wiring (Part B2) — BUILT 2026-09-11, awaiting Scott's live pass.** Load → `SO_simulateRun`; Delete → `SO_resetRun` (Appian first, then Snowflake); messages verbatim; placeholder `1012-ACME`; the `hero-trade-delete.sql` instruction removed. Run-name format is enforced by the procedures' REFUSED message and not re-checked in Appian (B1 ruling).
  - [ ] **Part C — full dress rehearsal** (clock-sensitive, one sitting). Opens after Scott's B2 live pass is reviewed.
- [ ] Session tagging end to end (cases, audit, resolution events)
- [ ] Reset Demo action (Demo Admins): delete session-tagged cases/children, cancel orphaned processes; Snowflake session-row cleanup proc — *2026-09-11: session-tagged cases/children + Snowflake packet rows now cleared by `SO_resetRun`; cancelling orphaned processes is still open.*
- [ ] Verify Ready action: baseline counts, zero open demo cases, MCP reachable, warehouse warm — green-checks screen
- [ ] SC setup doc: new-SC-from-zero (own Snowflake user, default warehouse, PAT, grants), reset/verify usage, known failure modes + fallbacks (pre-scored batch; REST DATA_AGENT_RUN path)

### Phase 6 — Supervisor analytics (0.5 day)
- [ ] Wire 3 verified-query questions (fail rate trend, top failing counterparties, notional at risk) as suggested prompts in a supervisor Ask panel (agentChatField scoped to analyst tool)
- [ ] Verify answers against worksheet ground truth; add to eval suite

### Phase 7 — Governance layer (1 day)
- [ ] Evaluate tab: full test suite (Phases 3+6), bulk run, accuracy metrics
- [ ] AI Guardrails configured in Admin Console
- [ ] Usage groups per desk; AI Actions consumption attribution
- [ ] Process HQ on SO Create Fail Case: automation-type view + resolution-time KPI
- [ ] Single architecture slide: the loop, two governance boundaries, zero data movement

### Phase 8 — Make the AI real (1–1.5 days)  ← the "genuinely model-driven" work
- [ ] Run 02_ml training in a Snowflake notebook → TRADE_FAIL_CLASSIFIER registered in Model Registry
- [ ] Rewrite run_inference.sql: TRADE_FAIL_CLASSIFIER!PREDICT_PROBA replaces the SQL heuristic; heuristic kept commented as documented fallback; re-verify tier distribution, adjust thresholds if the model's spread differs. **Write `SCORED_AT` explicitly as `SYSDATE()`** — the column defaults to `CURRENT_TIMESTAMP()`, the Pacific session clock, which Appian reads as UTC (measured 2026-09-10)
- [ ] On-demand single-trade scoring exposed as a custom MCP tool; wired into SO Triage Agent + feed simulation (live scoring on arrival)
- [ ] Stretch (cut first): Kafka event intake — trades.pending consumer trigger + Publish Event resolution loop-back to Snowflake

## Open dependencies
- Daniel: permanent network policy (only hard blocker)
- Daniel: FWA package export (optional accelerant for Phases 3–4 patterns)

**Critical path: 1 → 2 → 3 → 4 → 5. ~6 build days core; +1.5 for Phase 8. Phases 6–7 slot anywhere after 3.**
