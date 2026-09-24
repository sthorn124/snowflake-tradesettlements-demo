/*
 * SO_demoAdminConsole — the demo operator's console. Three actions and a
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
 * screen before any of that; the guard on local!agentLast below closes the
 * naked consumer anyway, because defence in depth costs one if().
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
       THE FIXTURE SESSION IS REPORTED, NOT FAILED. P4-VERIFY rows are supposed to
       be there; a readiness screen that flags them red teaches the operator to
       ignore red. Non-fixture sessions are the ones that must be zero. */
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
    local!otherCases: if(a!isNullOrEmpty(local!allCases), 0, count(local!allCases) - local!fixtureCases),
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

    /* ================= AGENT: VERIFIED AT LAST RUN, NEVER INVOKED =================
       The most recent event with NO USER and a machine-decision type is the
       agent's own last write. Its timestamp is the evidence. */
    local!agentEvents: a!queryRecordType(
      recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
      fields: { 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName' },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', ascending: false))
    ).data,
    /* THE ONE NAKED CONSUMER OF TWENTY, NOW GUARDED (2026-09-24). Nineteen of
       the console's query results are either aggregated-and-defaulted or opened
       with an explicit a!isNullOrEmpty; this one was fed straight into a!forEach
       and then into wherecontains, which is type-sensitive. When the query came
       back as anything other than a list of rows, the forEach yielded
       record-typed values and wherecontains compared Boolean against
       eede988b-… — taking the whole page down. The preflight above now stops a
       viewer who cannot read this record type from ever reaching here, so this
       guard is redundant by design; it stays because the cost is one if() and
       the failure mode was a whole-page crash on the operator's only screen. */
    local!agentLast: if(
      a!isNullOrEmpty(local!agentEvents),
      null,
      a!localVariables(
        local!idx: wherecontains(true, a!forEach(
          items: local!agentEvents,
          expression: and(
            a!isNullOrEmpty(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', null)),
            contains({ "Agent Triage Complete", "Straight-Through Resolution", "Escalated" },
              a!defaultValue(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName', ""), ""))
          ))),
        if(a!isNullOrEmpty(local!idx), null, index(local!agentEvents, index(local!idx, 1, 1), null))
      )
    ),

    /* ================= LOAD THE DEMO (panel 2) =================
       simResult holds the LAST answer only: the procedure message verbatim, and when.
       There is no run-name local any more — the name is cons!SO_DEMO_RUN_NAME. */
    local!simResult: null,

    /* ================= THE STATUS LINE =================
       DERIVED, NOT TRACKED. Every figure is already read for panel 1, so this is a
       reading of existing queries rather than new state: reserved TRD9* trades say
       whether Snowflake holds a demo, non-fixture cases say whether Appian does. */
    local!statusLoaded: or(local!tradeReserved > 0, local!otherCases > 0),

    /* WHEN THE DEMO WAS LOADED, READ FROM THE SCORING STAMP. There is no
       load-time field to read: SO Settlement Case.createdOn comes back NULL on
       process-written rows (MEASURED this session), so the case cannot date its
       own run. The packet's predictions can — SIMULATE_FEED writes SCORED_AT
       explicitly at call time, in UTC — and every row of a run carries the same
       stamp, so the newest one IS the load time. */
    local!loadStamp: a!refreshVariable(
      value: index(
        index(
          a!queryRecordType(
            recordType: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions',
            fields: { 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt' },
            filters: a!queryFilter(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId', operator: "starts with", value: "TRD9"),
            pagingInfo: a!pagingInfo(
              startIndex: 1, batchSize: 1,
              sort: a!sortInfo(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt', ascending: false)
            )
          ).data,
          1, null
        ),
        'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt',
        null
      ),
      refreshAlways: true
    ),

    /* THE STALE-DATE GUARD. A packet loaded yesterday still renders: its trades
       exist, its cases exist, and every screen looks alive — but its cutoffs and
       settlement dates were computed against yesterday's clock, so the watchlist
       shows a book already past cutoff. That reads as a broken demo rather than
       an old one, which is exactly the failure the fixture re-date ritual exists
       to prevent, and the console is where it can be caught before anyone
       presents. BOTH SIDES COMPARE THROUGH text(): the stamp is stored UTC while
       today() is the local date, and comparing them raw would flip the verdict
       for the several hours a day when the two calendars disagree. */
    local!loadStale: and(
      not(a!isNullOrEmpty(local!loadStamp)),
      text(local!loadStamp, "yyyy-mm-dd") <> text(today(), "yyyy-mm-dd")
    ),

    local!statusLine: if(
      local!statusLoaded,
      "Demo loaded"
        & if(a!isNullOrEmpty(local!loadStamp), "", " " & text(local!loadStamp, "d mmm hh:mm"))
        & "  ·  " & local!tradeReserved & if(local!tradeReserved = 1, " trade", " trades")
        & "  ·  " & local!otherCases & if(local!otherCases = 1, " case", " cases"),
      "No demo data loaded."
    ),

    /* ================= THE VERDICT =================
       One line answers "can I walk into the room". Data, connections and agent only —
       demo rows are STATE, not a fault, and must not turn the verdict red while a demo
       is deliberately loaded (v8 did exactly that). */
    local!dataOk: and(local!tradeBaseline = 50000, local!predBaseline = 50000),
    local!agentOk: not(a!isNullOrEmpty(local!agentLast)),
    local!ready: and(local!dataOk, local!probesOk = count(local!probes), local!agentOk),

    /* ================= RESET SESSION =================
       Cases are queried as RECORD ROWS so each carries its primary key, which is
       what a delete needs (SO_resetRun runs the same query server-side and
       deletes with the Delete Records node). Comments and event rows are NOT queried for
       deletion: SO Settlement Case relates to both with CASCADING update
       behaviour, so deleting the case removes them. That is asserted here and
       PROVEN by the before/after counts, not assumed. */
    /* THE NAME IS THE CONSTANT, not an input and not a typed field (2026-09-22).
       ri!sessionPrefill is now unused; it is left declared so the site page's
       configuration does not have to change, and so this screen still renders
       under testInterface, where a!startProcess cannot be invoked — everything up
       to the click (query, counts, status line) stays checkable that way. */
    local!resetSession: cons!SO_DEMO_RUN_NAME,
    local!lastReset: null,
    local!resetError: null,
    local!resetBefore: null,
    local!resetRows: a!refreshVariable(
      value: a!queryRecordType(
          recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
          fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID' },
          filters: a!queryFilter(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID', operator: "=", value: local!resetSession),
          pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
        ).data,
      refreshAlways: true
    ),
    local!resetCaseIds: if(a!isNullOrEmpty(local!resetRows), {},
      a!forEach(items: local!resetRows, expression: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', null))),
    local!resetCommentCount: a!refreshVariable(
      value: if(a!isNullOrEmpty(local!resetCaseIds), 0,
        a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId', operator: "in", value: local!resetCaseIds),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    )),
      refreshAlways: true
    ),
    local!resetEventCount: a!refreshVariable(
      value: if(a!isNullOrEmpty(local!resetCaseIds), 0,
        a!localVariables(
      local!agg: a!queryRecordType(
        recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
        fields: a!aggregationFields(measures: a!measure(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId', operator: "in", value: local!resetCaseIds),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      tointeger(a!defaultValue(index(index(local!agg, 1, null), "n", 0), 0))
    )),
      refreshAlways: true
    ),

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
            text: "One demo at a time. Load starts it, Reset removes it.",
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
                  text: if(local!ready, "Ready", "Not ready"),
                  color: if(local!ready, "#17715B", "#B3261E"), size: "STANDARD", style: "STRONG"
                ),
                a!richTextItem(
                  text: "   ·  data " & text(local!tradeBaseline, "#,##0") & "/" & text(local!predBaseline, "#,##0")
                    & "  ·  " & local!probesOk & "/" & count(local!probes) & " connections"
                    & "  ·  agent " & if(local!agentOk, "OK", "no record"),
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
            a!richTextDisplayField(
              showWhen: not(local!agentOk),
              labelPosition: "COLLAPSED", marginBelow: "NONE",
              value: a!richTextItem(
                text: "✕  No record of the AI agent running",
                color: "#B3261E", size: "SMALL", style: "STRONG"
              )
            ),

            /* LIVE DEMO STATE — shown only when there is something loaded. Neutral, not red. */
            a!richTextDisplayField(
              showWhen: or(local!tradeReserved > 0, local!otherCases > 0),
              labelPosition: "COLLAPSED", marginBelow: "NONE",
              value: {
                a!richTextItem(text: "Loaded now:  ", color: "#6E7885", size: "SMALL"),
                a!richTextItem(
                  text: local!tradeReserved & if(local!tradeReserved = 1, " demo trade", " demo trades")
                    & "  ·  " & local!otherCases & if(local!otherCases = 1, " case", " cases"),
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
                rule!SO_adminCheck(label: "Demo cases", actual: local!otherCases & "", expected: "informational", ok: true),
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
                ),
                rule!SO_adminCheck(
                  label: "AI agent",
                  actual: if(
                    local!agentOk,
                    "last run " & text(index(local!agentLast, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', null), "d mmm hh:mm"),
                    "no record"
                  ),
                  expected: "a record of the agent running",
                  ok: local!agentOk
                )
              }
            )
          }
        ),

        /* ================= RUN THE DEMO — PANELS 2 AND 3, MERGED ================= */
        a!cardLayout(
          padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
          contents: {
            /* ONE EXPLAINER, ABOVE BOTH BUTTONS, REPLACING BOTH CAPTIONS. Two
               captions under two buttons said the same kind of thing twice in two
               registers and neither had room to say what Reset actually spares —
               the 50,000-row baseline. Said once, before the buttons, it is read
               before either is pressed rather than after one is chosen. */
            a!cardLayout(
              padding: "LESS", style: "#F5F7F9", showBorder: false,
              shape: "SEMI_ROUNDED", marginBelow: "STANDARD",
              contents: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(text: "Load", style: "STRONG", color: "#1B2330", size: "SMALL"),
                  a!richTextItem(text: " — Adds 15 trades to Snowflake. The 3 high-risk ones open cases on the analyst watchlist. About 2 minutes.", color: "#454F5C", size: "SMALL"),
                  char(10),
                  a!richTextItem(text: "Reset", style: "STRONG", color: "#1B2330", size: "SMALL"),
                  a!richTextItem(text: " — Deletes those 15 trades and their cases from Snowflake and Appian. The permanent 50,000-trade history is untouched.", color: "#454F5C", size: "SMALL")
                }
              )
            ),

            a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              marginBelow: if(local!loadStale, "NONE", "STANDARD"),
              value: {
                a!richTextItem(text: "Status:  ", color: "#6E7885", size: "SMALL"),
                a!richTextItem(
                  text: local!statusLine,
                  color: if(local!statusLoaded, "#17715B", "#454F5C"),
                  size: "STANDARD", style: "STRONG"
                )
              }
            ),
            /* AMBER, NOT RED, AND ONE LINE. Stale demo data is not a fault in the
               environment — everything is working — so it does not belong in the
               red vocabulary the readiness verdict owns. It is a state with one
               fix, and the line is the fix. */
            a!richTextDisplayField(
              showWhen: local!loadStale,
              labelPosition: "COLLAPSED", marginBelow: "STANDARD",
              value: a!richTextItem(
                text: "Loaded before today. Reset, then Load for fresh dates.",
                color: "#96590A", size: "SMALL", style: "STRONG"
              )
            ),

            a!columnsLayout(
              marginBelow: "STANDARD",
              columns: {
                a!columnLayout(contents: {
                  a!buttonArrayLayout(
                    align: "START", marginBelow: "LESS",
                    buttons: a!buttonWidget(
                      label: "Load the demo",
                      style: "SOLID",
                      saveInto: {
                        a!save(local!simResult, null),
                        a!startProcess(
                          processModel: cons!SO_PM_SIMULATE_RUN,
                          processParameters: a!map(runName: cons!SO_DEMO_RUN_NAME),
                          isSynchronous: true,
                          onSuccess: a!save(local!simResult, a!map(message: fv!processInfo.pv.message, at: now())),
                          onError: a!save(local!simResult, a!map(message: "The load could not start, so nothing was sent to Snowflake. Your account may not be allowed to start it; ask the demo owner.", at: now())),
                          onIncomplete: a!save(local!simResult, a!map(message: "No answer within 30 seconds, or your account cannot read the result. The load may still finish: check the status line above before pressing again.", at: now()))
                        )
                      }
                    )
                  )
                }),
                a!columnLayout(contents: {
                  a!buttonArrayLayout(
                    align: "START", marginBelow: "LESS",
                    buttons: a!buttonWidget(
                      label: "Reset the demo",
                      style: "SOLID",
                      color: "NEGATIVE",
                      /* ENABLED WHEN EITHER SIDE HOLDS DEMO ROWS. B2's Appian-first reset can
                         legitimately leave Snowflake rows with zero Appian cases, and pressing
                         Reset again is the recovery — keying this on cases alone would strand
                         that state. Verified 2026-09-22; statusLoaded already reads both. */
                      disabled: not(local!statusLoaded),
                      saveInto: {
                        a!save(local!resetError, null),
                        a!save(local!lastReset, null),
                        a!save(
                          local!resetBefore,
                          a!map(
                            cases: count(local!resetRows),
                            comments: local!resetCommentCount,
                            events: local!resetEventCount
                          )
                        ),
                        a!startProcess(
                          processModel: cons!SO_PM_RESET_RUN,
                          processParameters: a!map(runName: cons!SO_DEMO_RUN_NAME),
                          isSynchronous: true,
                          onSuccess: a!save(
                            local!lastReset,
                            a!map(
                              cases: index(local!resetBefore, "cases", 0),
                              comments: index(local!resetBefore, "comments", 0),
                              events: index(local!resetBefore, "events", 0),
                              message: fv!processInfo.pv.message,
                              at: now()
                            )
                          ),
                          onError: a!save(local!resetError, "The clean-up could not start. Nothing was deleted in Appian or in Snowflake."),
                          onIncomplete: a!save(local!resetError, "No answer within 30 seconds, or your account cannot read the result. The clean-up may still finish: the status line above shows what remains; press again once it stops changing.")
                        )
                      }
                    )
                  )
                })
              }
            ),

            /* ================= RESULTS =================
               Success is one green line plus the small grey verbatim response. Refusals and
               failures keep full prominence: those are the states worth reading. */
            a!richTextDisplayField(
              showWhen: not(a!isNullOrEmpty(local!simResult)),
              labelPosition: "COLLAPSED",
              value: a!localVariables(
                local!m: tostring(index(local!simResult, "message", "")),
                local!isOk: left(local!m, 7) = "OK run=",
                local!isRefused: left(local!m, 8) = "REFUSED:",
                {
                  a!richTextItem(
                    text: if(local!isOk, "Feed loaded", if(local!isRefused, "Not loaded — refused", "Not loaded")),
                    color: if(local!isOk, "#17715B", "#B3261E"), size: "STANDARD", style: "STRONG"
                  ),
                  a!richTextItem(text: "   " & text(a!defaultValue(index(local!simResult, "at", null), now()), "d mmm hh:mm"), color: "#6E7885", size: "SMALL"),
                  char(10),
                  a!richTextItem(
                    text: "Snowflake's response: ",
                    color: "#6E7885", size: "SMALL"
                  ),
                  a!richTextItem(
                    text: local!m,
                    color: if(local!isOk, "#6E7885", "#1B2330"),
                    size: if(local!isOk, "SMALL", "STANDARD"),
                    style: if(local!isOk, {}, "STRONG")
                  )
                }
              )
            ),
            a!richTextDisplayField(
              showWhen: not(a!isNullOrEmpty(local!resetError)),
              labelPosition: "COLLAPSED",
              value: a!richTextItem(text: local!resetError, color: "#B3261E", size: "STANDARD", style: "STRONG")
            ),
            a!richTextDisplayField(
              showWhen: not(a!isNullOrEmpty(local!lastReset)),
              labelPosition: "COLLAPSED",
              value: a!localVariables(
                local!m: tostring(index(local!lastReset, "message", "")),
                local!isOk: left(local!m, 7) = "OK run=",
                {
                  a!richTextItem(
                    text: if(local!isOk, "Cleaned up", "Not fully cleaned up"),
                    color: if(local!isOk, "#17715B", "#B3261E"), size: "STANDARD", style: "STRONG"
                  ),
                  a!richTextItem(text: "   " & text(a!defaultValue(index(local!lastReset, "at", null), now()), "d mmm hh:mm"), color: "#6E7885", size: "SMALL"),
                  char(10),
                  /* THE EVIDENCE LINE — before and after, kept deliberately. */
                  a!richTextItem(text: "was ", color: "#6E7885", size: "SMALL"),
                  a!richTextItem(
                    text: index(local!lastReset, "cases", 0) & " cases · "
                      & index(local!lastReset, "comments", 0) & " comments · "
                      & index(local!lastReset, "events", 0) & " audit rows",
                    color: "#454F5C", size: "SMALL"),
                  a!richTextItem(text: "   now ", color: "#6E7885", size: "SMALL"),
                  a!richTextItem(
                    text: count(local!resetRows) & " cases · " & local!resetCommentCount & " comments · " & local!resetEventCount & " audit rows",
                    color: if(count(local!resetRows) = 0, "#17715B", "#B3261E"), size: "SMALL", style: "STRONG"),
                  char(10),
                  a!richTextItem(text: "Snowflake's response: ", color: "#6E7885", size: "SMALL"),
                  a!richTextItem(
                    text: local!m,
                    color: if(local!isOk, "#6E7885", "#1B2330"),
                    size: if(local!isOk, "SMALL", "STANDARD"),
                    style: if(local!isOk, {}, "STRONG")
                  )
                }
              )
            )
          }
        )
      }
    )
    )
  )
)
