/*
 * SO_demoAdminConsole — the demo operator's console. One action and a
 * readiness checklist. PLAIN SAIL, legible, no design polish beyond that: this
 * screen is never on stage.
 *
 * ================= WHO SEES IT =================
 * It lives on its OWN SITE, gated to SO Demo Admins, and that group sits
 * DELIBERATELY OUTSIDE the SO Users tree. An SC running the demo is not a
 * persona; the reset button must never appear as a tab beside the analyst's
 * watchlist, where a wrong click during a live demo would delete the case
 * being demonstrated.
 *
 * ================= WHAT IT WILL NOT DO =================
 * ITS READINESS CHECK NEVER INVOKES THE AGENT. "Agent verified" is read from the
 * most recent machine-written entry in the event history — evidence that the
 * agent HAS run, not a fresh run. A readiness check that invokes a model costs
 * ~44 seconds, costs money, and writes audit rows; a check that changes the thing
 * it is checking is not a check. (Loading a feed in panel 2 DOES start triage —
 * that is the demo itself, not a check.)
 *
 * IT REACHES SNOWFLAKE ONLY THROUGH THE TWO PROCEDURES (Phase 5 Part B2). Load
 * starts SO_simulateRun (SIMULATE_FEED through SO_simulateFeed, then intake in
 * the background); Delete starts SO_resetRun (the run's Appian cases FIRST, then
 * RESET_SESSION through SO_resetSession, and only if the Appian delete worked).
 * No free SQL, no DDL. Both show the procedure's own message VERBATIM, OK and
 * REFUSED alike — the refusals are the explanation, so they are never reworded.
 *
 * THE RUN NAME IS FIXED — cons!SO_DEMO_RUN_NAME, value DEMO — and 2026-09-22 removed
 * both name fields. An SC no longer invents a name, mistypes one, or has to remember
 * which one they used in order to clean up. Both buttons pass the constant straight to
 * SO_simulateRun and SO_resetRun. The upper-casing that used to stop "1012-acme" and
 * "1012-ACME" splitting one run across the two systems is pointless now that a single
 * literal is the only value ever sent, so it is gone from this screen.
 *
 * CONSEQUENCE, DELIBERATE: one environment runs one demo at a time. Per-run naming let
 * two SCs share an environment on the same day; that is given up for a console an SC
 * cannot get wrong.
 *
 * THE REFUSED PATH IS NO LONGER REACHABLE FROM HERE. The procedures still refuse a
 * malformed name and still refuse P4-VERIFY, and both process models still carry their
 * own P4-VERIFY guard — but "DEMO" can never trip either, so this screen's P4-VERIFY
 * branches were dead code and were removed: the protected-name warning in panel 2, the
 * protected branch of the delete preview, and the simProtected / isProtected locals.
 * NAME-GUARD TESTING NO LONGER HAS A HOME ON THIS SCREEN. There is no integration
 * test screen in this application yet (checked 2026-09-22), so a REFUSED message is
 * exercised by calling SO_simulateFeed from its own integration object in Designer,
 * with a malformed run name. If a test screen is ever built, it belongs there.
 *
 * ================= 2026-09-22 REDESIGN: A HEALTHY SCREEN IS QUIET =================
 * v8 was functionally right and visually exhausting — three numbered panels, a blue
 * concept box, and nine narrated checklist lines an SC had to read past to reach two
 * buttons. The rule now: PROSE IS SPENT ON FAILURE STATES. The healthy default view is
 * a one-line verdict, a status line and two buttons; every detail lives in a collapsed
 * Details section; failing checks surface in red with their detail. Refused and failed
 * results keep full prominence and full verbatim text — those are the states where
 * words earn their place.
 *
 * The agent footnote was DELETED rather than made a tooltip: helpTooltip renders only
 * beside a visible label, and the line was narration about a check rather than a check.
 *
 * ================= 2026-09-23: THE EXPLAINER AND THE STALE-DATE GUARD =================
 * The two button captions became ONE explainer box above both buttons. Two captions
 * could each only describe their own button, so neither could say the thing an operator
 * most needs to hear before pressing Reset: the permanent 50,000-trade history is not
 * what gets deleted. Said once, above both, it is also read before a button is chosen
 * rather than after.
 *
 * THE BUDGET, MEASURED RATHER THAN ESTIMATED. The redesign budget above is "under 60
 * words of visible prose on the healthy default view". The explainer costs 39 words
 * where the two captions cost 17, and the measured healthy view is now EXACTLY 60 — at
 * the line, not under it. Longest sentence 11 words, inside the 15-word rule. The copy
 * is Scott's, specified verbatim, and what it spends is spent on the one irreversible
 * action on the screen; the number is recorded here so the next edit knows there is no
 * headroom left rather than discovering it.
 *
 * THE STATUS LINE NOW CARRIES WHEN, not just what, and a stale load says so in amber.
 * Both are read from the packet's own SCORED_AT, because process-written cases come
 * back with a NULL createdOn and cannot date their own run (MEASURED 2026-09-23).

 * ================= 2026-09-24: THE PRESENTER PREFLIGHT =================
 * FIRST THING EVALUATED, AND IT GATES EVERY QUERY BEHIND IT. A presenter must
 * hold BOTH memberships: SO Demo Admins to reach this site at all, and SO
 * Supervisors for the data every check on this screen reads. The Demo-Admins-only
 * reading is dead (ruled 2026-09-24).
 *
 * WHY IT IS STRUCTURED AS A NESTED a!localVariables RATHER THAN A showWhen.
 * A misconfigured viewer must run ZERO record queries — not "queries whose
 * results are hidden". Every one of the twenty query locals therefore lives
 * inside the nested a!localVariables that is the TRUE branch's value, so they
 * are never declared for a viewer who fails the check. A showWhen would have
 * hidden the output and still run all twenty, which is the failure this
 * preflight exists to prevent.
 *
 * WHAT IT PREVENTS, MEASURED: a Demo-Admins-only account opening this site got a
 * whole-page crash — `wherecontains [line 232]: Invalid types, can only act on
 * data of the same type (Boolean, eede988b-…)` — because SO Demo Admins holds no
 * viewer right on ANY of the nine record types this console queries, and one of
 * the twenty results was consumed without a guard. The preflight stops the
 * screen before any of that. (The agent check that held the unguarded
 * consumer left the page on 2026-11-12.)
 *
 * ================= PHASE 11, 2026-11-12 =================
 * One button, "Prepare the demo" (SO_prepareRun), and one status line read from
 * SO_demoRunState. The Load and Reset buttons, their captions and their result
 * lines left the page. The verdict word is "Environment OK" / "Environment
 * problem", so the page has one "Ready": the status line's.
 */
a!localVariables(
  /* THE PREFLIGHT. One membership test, evaluated before anything else.
     cons!SO_SUPERVISORS_GROUP already existed and gates the Supervisor page;
     reusing it keeps one definition of "can read the demo data". */
  local!isPresenter: a!isUserMemberOfGroup(
    username: loggedInUser(),
    groups: cons!SO_SUPERVISORS_GROUP
  ),

  if(
    not(local!isPresenter),

    /* ---------- MISCONFIGURED VIEWER: ONE CARD, NOTHING ELSE ----------
       No verdict, no checklist, no buttons, and above all no queries. The
       signed-in line is kept because "this account" is ambiguous without
       it — the reader needs to know WHICH login is short a group. Amber,
       not red: this is a state with one fix, the same vocabulary the
       stale-date line uses, and red on this screen is reserved for a
       broken environment. */
    a!formLayout(
      backgroundColor: "#F3F5F8",
      contentsWidth: "FULL",
      focusOnFirstInput: false,
      contents: {
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {
            a!richTextItem(text: "Demo Admin", color: "#1B2330", size: "MEDIUM", style: "STRONG"),
            a!richTextItem(text: "    Settlement Operations", color: "#454F5C", size: "SMALL")
          }
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED", marginBelow: "STANDARD",
          value: a!richTextItem(
            text: "Signed in as " & loggedInUser(),
            color: "#9AA6B3", size: "SMALL"
          )
        ),
        a!cardLayout(
          padding: "MORE", shape: "SEMI_ROUNDED", showBorder: true,
          contents: a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(
                text: "This account can see the admin site but not the demo data.",
                color: "#96590A", size: "STANDARD", style: "STRONG"
              ),
              char(10),
              char(10),
              a!richTextItem(
                text: "Add it to SO Supervisors in the Admin Console, under Groups, then reload this page.",
                color: "#1B2330", size: "STANDARD"
              ),
              char(10),
              char(10),
              a!richTextItem(
                text: "Presenting needs both memberships: SO Demo Admins to open this site, SO Supervisors for the data these checks read. GETTING_STARTED.md carries the two lines.",
                color: "#6E7885", size: "SMALL"
              )
            }
          )
        )
      }
    ),

    /* ---------- CONFIGURED PRESENTER: THE CONSOLE, UNCHANGED ---------- */
    a!localVariables(
    /* ================= WHY THESE ARE AGGREGATIONS AND NOT .totalCount =================
       MEASURED HERE, on the first render: every one of these read `.totalCount`
       and every one returned **-1**, so the readiness screen confidently reported
       "Baseline trades -1, expected 50,000" in red. §4 names the trap; this is a
       50,000-row table, so the documented workaround — count(query.data) at
       batchSize 500 — cannot reach it either. The right tool is an AGGREGATION:
       a!aggregationFields with a COUNT measure returns one row holding the number,
       with no row transfer at all. Filters apply to the aggregate exactly as they
       would to the rows. */
    /* ================= BASELINE COUNTS =================
       RESERVED ROWS ARE EXCLUDED FROM THE BASELINE, not subtracted afterwards.
       The packet reserves TRD9* ids (hero-trade-spec.md), so a loaded packet
       otherwise reads as baseline corruption. Counted with "not starts with" so
       the assertion stays true whether or not a packet is loaded, and the
       reserved rows are reported on their own line. */
    local!tradeBaseline: a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', operator: "not starts with", value: "TRD9"),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    ),
    local!tradeReserved: a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', operator: "starts with", value: "TRD9"),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    ),
    local!predBaseline: a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId', operator: "not starts with", value: "TRD9"),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    ),

    /* ================= SESSION-TAGGED APPIAN ROWS =================
       THE STANDING CASES ARE REPORTED, NOT FAILED. P4-VERIFY rows are supposed to
       be there. Demo cases are counted by SO_demoRunState, by run name. */
    local!fixtureSession: "P4-VERIFY",
    local!allCases: a!refreshVariable(
      value: a!queryRecordType(
        recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
        fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID' },
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
      ).data,
      refreshAlways: true
    ),
    local!fixtureCases: if(a!isNullOrEmpty(local!allCases), 0, sum(a!forEach(
      items: local!allCases,
      expression: if(a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID', ""), "") = local!fixtureSession, 1, 0)))),
    local!commentCount: a!refreshVariable(
      value: a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId', function: "COUNT", alias: "n")),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    ),
      refreshAlways: true
    ),
    local!eventCount: a!refreshVariable(
      value: a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId', function: "COUNT", alias: "n")),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    ),
      refreshAlways: true
    ),

    /* ================= REACHABILITY PROBES =================
       ONE ROW FROM EACH RECORD TYPE. This is the check that catches an expired
       Snowflake PAT, an unset default warehouse, or a broken data source — all of
       which present as an EMPTY screen rather than an error (§5), which is exactly
       why an explicit probe is worth its query cost. */
    local!pTrade: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade', fields: { 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Trade", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pPrediction: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions', fields: { 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Prediction", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pCounterparty: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{caca5336-9c5e-4fd9-9a75-1e5d72316dd3}SO Counterparty', fields: { 'recordType!{caca5336-9c5e-4fd9-9a75-1e5d72316dd3}SO Counterparty.fields.{c6d9ae83-120c-4ba0-b8a9-43010d055f38}counterpartyId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Counterparty", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pInstrument: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{553867ce-5f08-44a8-a81c-ed5450f2897d}SO Instrument', fields: { 'recordType!{553867ce-5f08-44a8-a81c-ed5450f2897d}SO Instrument.fields.{54b79156-0f81-43d4-a133-bd9c321bbe11}instrumentId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Instrument", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pSettlementHistory: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History', fields: { 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{bad6863a-6fd2-40f3-a5ea-b41f50235249}tradeId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "SettlementHistory", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pCase: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case', fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Case", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pComment: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment', fields: { 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "Comment", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pEventHistory: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History', fields: { 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "EventHistory", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!pEventType: a!localVariables(
      local!q: a!queryRecordType(recordType: 'recordType!{beb76989-f7f1-40f9-8be6-0a1302c68803}SO Settlement Case Event Type', fields: { 'recordType!{beb76989-f7f1-40f9-8be6-0a1302c68803}SO Settlement Case Event Type.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName' }, pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)).data,
      a!map(name: "EventType", ok: not(a!isNullOrEmpty(local!q)))
    ),
    local!probes: {
      a!map(label: "SO Trade (Snowflake)", ok: index(local!pTrade, "ok", false)),
      a!map(label: "SO Trade Predictions (Snowflake)", ok: index(local!pPrediction, "ok", false)),
      a!map(label: "SO Counterparty (Snowflake)", ok: index(local!pCounterparty, "ok", false)),
      a!map(label: "SO Instrument (Snowflake)", ok: index(local!pInstrument, "ok", false)),
      a!map(label: "SO Settlement History (Snowflake)", ok: index(local!pSettlementHistory, "ok", false)),
      a!map(label: "SO Settlement Case (Appian)", ok: index(local!pCase, "ok", false)),
      a!map(label: "SO Case Comment (Appian)", ok: index(local!pComment, "ok", false)),
      a!map(label: "SO Settlement Case Event History", ok: index(local!pEventHistory, "ok", false)),
      a!map(label: "SO Settlement Case Event Type", ok: index(local!pEventType, "ok", false))
    },
    local!probesOk: sum(a!forEach(items: local!probes, expression: if(index(fv!item, "ok", false), 1, 0))),
    /* ONLY THE FAILURES ARE NAMED. Nine passing connection names told the SC nothing. */
    local!probesFailed: a!flatten(a!forEach(
      items: local!probes,
      expression: if(index(fv!item, "ok", false), {}, index(fv!item, "label", ""))
    )),

    /* ================= PREPARE'S ANSWER TO THIS PRESS =================
       Holds what SO_prepareRun returned to this page: ok, the message verbatim,
       and when. A page refresh loses it, which is fine: the status line and a
       failed step are read from data (SO_demoRunState), not from this. */
    local!prepResult: null,

    /* ================= THE RUN'S STATE =================
       ONE RULE, SO_demoRunState, READ HERE AND BY SO_prepareRun. It derives the
       state from data the processes already write (the TRD9 packet, its load
       stamp, the cases tagged with the run name, the story table) and returns
       the status line and its tone with it. A demo case is a case whose session
       id is the run name: on 2026-10-23 this page read "Demo loaded" with 0
       trades and 5 cases because it counted every case that was not a built-in
       test case, including five with no session id at all. */
    local!runState: a!refreshVariable(
      value: rule!SO_demoRunState(runName: cons!SO_DEMO_RUN_NAME, asOf: null),
      refreshAlways: true
    ),
    local!demoCases: tointeger(a!defaultValue(index(local!runState, "demoCases", 0), 0)),

    /* ================= THE PRESS, HELD ON THE PAGE (2026-11-13) =================
       local!runState IS WHAT THE RULE READ WHEN THIS PAGE LOADED, AND IT STAYS
       THAT. refreshAlways above does not re-read it: the rule's own local
       variables (its queries, its now()) re-evaluate only when something they
       depend on changes, and nothing does while the page is open. The docs say
       so under "Nested rules need refreshAlways". Found when Scott pressed
       Prepare and the line and the button did not change until he refreshed.

       So the page does not wait on a re-read. This press's own answer says a
       run has started (prepResult.ok), and from then the card shows the rule's
       Running view (whenRunning: its line, its tone, isRunning true) in place of
       what the page loaded with. The button therefore stays disabled on this
       page for as long as it is open. It is enabled again only on a refreshed
       page that reads a state other than Running. A press that was refused or
       failed leaves startedHere false: the message shows and the button stays
       enabled. */
    local!startedHere: and(
      not(a!isNullOrEmpty(local!prepResult)),
      a!defaultValue(index(local!prepResult, "ok", false), false)
    ),
    local!shownState: if(
      local!startedHere,
      index(local!runState, "whenRunning", local!runState),
      local!runState
    ),
    /* what to show when Prepare did not go through: this press's refusal first,
       otherwise the failed step recorded by the background half */
    local!pressRefused: and(
      not(a!isNullOrEmpty(local!prepResult)),
      not(a!defaultValue(index(local!prepResult, "ok", false), false))
    ),
    /* the failed step on the run record is the LAST run's. Once this press has
       started a new one it is no longer the last, and the page cannot re-read
       the record, so it stops showing it ("until the next press", below) */
    local!prepFailed: or(
      local!pressRefused,
      and(not(local!startedHere), a!defaultValue(index(local!runState, "lastFailed", false), false))
    ),
    local!prepFailedMessage: if(
      local!pressRefused,
      tostring(index(local!prepResult, "message", "")),
      tostring(index(local!runState, "lastMessage", ""))
    ),
    local!prepFailedAt: if(local!pressRefused, index(local!prepResult, "at", null), index(local!runState, "lastAt", null)),

    /* ================= THE VERDICT =================
       One line answers "is the environment working". Data and connections only.
       Whether the DEMO is ready is the status line's job (SO_demoRunState), so the
       page has one "Ready". The agent check left on 2026-11-12: it read the newest
       machine-written event, the standing cases always supply one, and a check
       that cannot fail is not a check. */
    local!dataOk: and(local!tradeBaseline = 50000, local!predBaseline = 50000),
    local!ready: and(local!dataOk, local!probesOk = count(local!probes)),

    a!formLayout(
      backgroundColor: "#F3F5F8",
      contentsWidth: "FULL",
      focusOnFirstInput: false,
      contents: {
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {
            a!richTextItem(text: "Demo Admin", color: "#1B2330", size: "MEDIUM", style: "STRONG"),
            a!richTextItem(text: "    Settlement Operations", color: "#454F5C", size: "SMALL")
          }
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: a!richTextItem(
            text: "One demo at a time.",
            color: "#454F5C", size: "SMALL"
          )
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED", marginBelow: "STANDARD",
          value: a!richTextItem(
            text: "Signed in as " & loggedInUser() & " · " & text(now(), "d mmm hh:mm"),
            color: "#9AA6B3", size: "SMALL"
          )
        ),

        /* ================= READINESS: ONE LINE, THEN DETAIL ON DEMAND ================= */
        a!cardLayout(
          padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
          contents: {
            a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(
                  text: if(local!ready, "Environment OK", "Environment problem"),
                  color: if(local!ready, "#17715B", "#B3261E"), size: "STANDARD", style: "STRONG"
                ),
                a!richTextItem(
                  text: "   ·  data " & text(local!tradeBaseline, "#,##0") & "/" & text(local!predBaseline, "#,##0")
                    & "  ·  " & local!probesOk & "/" & count(local!probes) & " connections",
                  color: "#6E7885", size: "SMALL"
                )
              }
            ),

            /* FAILURES SURFACE HERE, with their detail, without expanding anything. */
            a!richTextDisplayField(
              showWhen: not(local!dataOk),
              labelPosition: "COLLAPSED", marginBelow: "NONE",
              value: a!richTextItem(
                text: "✕  Baseline data " & text(local!tradeBaseline, "#,##0") & " trades / " & text(local!predBaseline, "#,##0") & " predictions — expected 50,000 each",
                color: "#B3261E", size: "SMALL", style: "STRONG"
              )
            ),
            a!richTextDisplayField(
              showWhen: local!probesOk < count(local!probes),
              labelPosition: "COLLAPSED", marginBelow: "NONE",
              value: a!richTextItem(
                text: "✕  No connection to " & joinarray(local!probesFailed, ", "),
                color: "#B3261E", size: "SMALL", style: "STRONG"
              )
            ),

            /* LIVE DEMO STATE — shown only when there is something loaded. Neutral, not red. */
            a!richTextDisplayField(
              showWhen: or(local!tradeReserved > 0, local!demoCases > 0),
              labelPosition: "COLLAPSED", marginBelow: "NONE",
              value: {
                a!richTextItem(text: "Loaded now:  ", color: "#6E7885", size: "SMALL"),
                a!richTextItem(
                  text: local!tradeReserved & if(local!tradeReserved = 1, " demo trade", " demo trades")
                    & "  ·  " & local!demoCases & if(local!demoCases = 1, " case", " cases"),
                  color: "#454F5C", size: "SMALL", style: "STRONG"
                )
              }
            ),

            a!sectionLayout(
              label: "Details",
              isCollapsible: true,
              isInitiallyCollapsed: true,
              labelSize: "EXTRA_SMALL",
              labelColor: "SECONDARY",
              marginBelow: "NONE",
              contents: {
                rule!SO_adminCheck(label: "Baseline trades", actual: text(local!tradeBaseline, "#,##0"), expected: "50,000", ok: local!tradeBaseline = 50000),
                rule!SO_adminCheck(label: "Baseline predictions", actual: text(local!predBaseline, "#,##0"), expected: "50,000", ok: local!predBaseline = 50000),
                rule!SO_adminCheck(label: "Demo trades", actual: local!tradeReserved & "", expected: "informational", ok: true),
                rule!SO_adminCheck(label: "Demo cases", actual: local!demoCases & "", expected: "informational", ok: true),
                rule!SO_adminCheck(label: "Built-in test cases", actual: local!fixtureCases & "", expected: "informational", ok: true),
                rule!SO_adminCheck(label: "Case comments", actual: local!commentCount & "", expected: "informational", ok: true),
                rule!SO_adminCheck(label: "Audit rows", actual: local!eventCount & "", expected: "informational", ok: true),
                rule!SO_adminCheck(
                  label: "Connections",
                  actual: local!probesOk & " of " & count(local!probes),
                  expected: count(local!probes) & " of " & count(local!probes),
                  ok: local!probesOk = count(local!probes)
                ),
                /* Only failing connections are named, here and on the verdict. */
                a!forEach(
                  items: local!probesFailed,
                  expression: a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "NONE",
                    value: a!richTextItem(text: "        ✕  " & fv!item, color: "#B3261E", size: "SMALL")
                  )
                )
              }
            )
          }
        ),

        /* ================= PREPARE THE DEMO (Phase 11, 2026-11-12) =================
           ONE BUTTON AND ONE STATUS LINE. The button starts SO_prepareRun, which
           answers in about 5 seconds: it refuses if a run is in progress, otherwise
           it records the start (SO Demo Run) and hands the work to SO_prepareRunSteps
           in the background: clear the last run, re-date the standing cases, load a
           fresh packet, start intake. The line and its colour come from
           SO_demoRunState, which the process reads too, so the page and the process
           cannot disagree about a run in progress. The line reads Running from the
           press because the page holds the press (local!startedHere, above), not
           because it re-reads the rule. No progress bar and no self-refresh, by
           ruling: the presenter refreshes. */
        a!cardLayout(
          padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
          contents: {
            a!richTextDisplayField(
              labelPosition: "COLLAPSED", marginBelow: "STANDARD",
              value: a!richTextItem(
                text: "Clears the last run, re-dates the standing cases and loads 15 fresh trades. The 50,000-trade history is untouched.",
                color: "#454F5C", size: "SMALL"
              )
            ),
            a!richTextDisplayField(
              labelPosition: "COLLAPSED", marginBelow: "STANDARD",
              value: {
                a!richTextItem(text: "Status:  ", color: "#6E7885", size: "SMALL"),
                a!richTextItem(
                  text: tostring(index(local!shownState, "line", "")),
                  /* READY green; nothing loaded and running neutral; every other state amber */
                  color: a!match(
                    value: tostring(index(local!shownState, "tone", "NEUTRAL")),
                    equals: "POSITIVE", then: "#17715B",
                    equals: "WARN", then: "#96590A",
                    default: "#454F5C"
                  ),
                  size: "STANDARD", style: "STRONG"
                )
              }
            ),
            a!buttonArrayLayout(
              align: "START", marginBelow: "LESS",
              buttons: a!buttonWidget(
                label: "Prepare the demo",
                style: "SOLID",
                /* DISABLED WHILE A RUN IS IN PROGRESS: from this page's own press for as
                   long as the page is open, and on a page loaded during a run. A
                   refreshed page that reads a state other than Running enables it. A
                   run that died unlocks itself: after 5 minutes SO_demoRunState stops
                   calling it running, and a refresh then shows the button enabled. */
                disabled: a!defaultValue(index(local!shownState, "isRunning", false), false),
                saveInto: {
                  a!save(local!prepResult, null),
                  a!startProcess(
                    processModel: cons!SO_PM_PREPARE_RUN,
                    processParameters: a!map(runName: cons!SO_DEMO_RUN_NAME),
                    isSynchronous: true,
                    onSuccess: a!save(local!prepResult, a!map(ok: fv!processInfo.pv.ok, message: fv!processInfo.pv.message, at: now())),
                    onError: a!save(local!prepResult, a!map(ok: false, message: "Prepare could not start, so nothing was changed. Your account may not be allowed to start it; ask the demo owner.", at: now())),
                    onIncomplete: a!save(local!prepResult, a!map(ok: false, message: "No answer within 30 seconds, or your account cannot read the result. Prepare may still finish: refresh this page and read the status line before pressing again.", at: now()))
                  )
                }
              )
            ),
            /* A FAILURE OR REFUSAL SHOWS IN FULL, WORD FOR WORD. Two sources, one
               line: a refusal comes back from this press (prepResult); a step that
               failed in the background is on the run record, so it is still here
               after a page refresh and until the next press. A start that went
               through shows nothing: the status line says the rest. */
            a!richTextDisplayField(
              showWhen: local!prepFailed,
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "Not prepared", color: "#B3261E", size: "STANDARD", style: "STRONG"),
                a!richTextItem(text: "   " & text(a!defaultValue(local!prepFailedAt, now()), "d mmm hh:mm"), color: "#6E7885", size: "SMALL"),
                char(10),
                a!richTextItem(text: local!prepFailedMessage, color: "#1B2330", size: "STANDARD", style: "STRONG")
              }
            )
          }
        )
      }
    )
    )
  )
)
