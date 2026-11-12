/*
 * SO_demoRunState — the state of the demo run, for the Demo Admin console and
 * for SO_prepareRun. ONE RULE, so the page and the process cannot disagree
 * about whether a run is in progress.
 *
 * DERIVED FROM DATA THE PROCESSES ALREADY WRITE. Nothing records run state:
 *   - the packet in Snowflake: SO Trade rows whose id starts with TRD9;
 *   - when it was loaded: the newest SCORED_AT among TRD9 predictions, which
 *     SIMULATE_FEED writes at call time in UTC;
 *   - the run's cases: SO Settlement Case rows whose session id IS the run
 *     name. A case with any other session id, or none, is not a demo case;
 *   - the stories and where each should end up: SO_intakePlan's story table.
 *
 * SIX STATES, tested in this order:
 *   NOTHING_LOADED       no TRD9 trades and no cases tagged with the run name
 *   LOADED_BEFORE_TODAY  the load stamp's date is not today
 *   READY                loaded today; every story has its decision and is in
 *                        its scripted status
 *   STORY_OUT_OF_PLACE   loaded today; every story has its decision and at
 *                        least one is not in its scripted status
 *   RUNNING              loaded today; a story has no decision yet and the
 *                        stamp is under 5 minutes old
 *   DID_NOT_FINISH       loaded today; a story has no decision and the stamp
 *                        is 5 minutes old or more. Also any partly loaded
 *                        state that fits no row above
 *
 * A STORY HAS ITS DECISION when its case's status is neither "New" nor
 * "Agent Triage". "Agent Triage" is not progress: triage writes it after the
 * agent has returned, so for the whole agent call the case still reads "New".
 *
 * THE 5 MINUTES IS WHAT UNLOCKS A RUN THAT DIED. A failed agent run leaves its
 * case "New" for good; press to Ready measures 70 to 80 seconds.
 *
 * TODAY IS THE VIEWER'S DAY: both sides go through text(), which renders in
 * the viewer's time zone, so the stored UTC stamp and "now" are compared on
 * one calendar. `line` uses the same clock for "Loaded today at <time>".
 *
 * ri!asOf stands in for "now" when a state has to be read without waiting for
 * it (tomorrow, or six minutes after a load). Leave it empty everywhere else.
 */
a!localVariables(
  local!name: a!defaultValue(ri!runName, cons!SO_DEMO_RUN_NAME),
  local!now: a!defaultValue(ri!asOf, now()),
  local!runningLimitSeconds: 300,
  local!stories: rule!SO_intakePlan(runName: local!name).stories,

  local!packetTrades: tointeger(a!defaultValue(index(index(
    a!queryRecordType(
      recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade',
      fields: a!aggregationFields(measures: a!measure(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', function: "COUNT", alias: "n")),
      filters: a!queryFilter(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', operator: "starts with", value: "TRD9"),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
    ).data, 1, null), "n", 0), 0)),

  local!loadStamp: index(index(
    a!queryRecordType(
      recordType: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions',
      fields: { 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt' },
      filters: a!queryFilter(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId', operator: "starts with", value: "TRD9"),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt', ascending: false))
    ).data, 1, null), 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt', null),

  local!cases: a!queryRecordType(
    recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
    fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status' },
    filters: a!queryFilter(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID', operator: "=", value: local!name),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500, sort: a!sortInfo(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', ascending: true))
  ).data,
  local!demoCases: if(a!isNullOrEmpty(local!cases), 0, count(local!cases)),

  /* each story with its case: the newest case on the story's trade in this run */
  local!storyStates: a!forEach(
    items: local!stories,
    expression: a!localVariables(
      local!story: fv!item,
      local!mine: if(a!isNullOrEmpty(local!cases), {}, a!flatten(a!forEach(
        items: local!cases,
        expression: if(tostring(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID']) = tostring(local!story.tradeId),
          a!map(caseId: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'], status: tostring(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status'])), {})
      ))),
      local!case: if(a!isNullOrEmpty(local!mine), null, index(local!mine, count(local!mine), null)),
      local!status: tostring(a!defaultValue(index(local!case, "status", ""), "")),
      a!map(
        seq: local!story.seq,
        label: local!story.label,
        tradeId: local!story.tradeId,
        scriptedStatus: local!story.scriptedStatus,
        caseId: index(local!case, "caseId", null),
        status: local!status,
        decided: and(not(a!isNullOrEmpty(local!case)), not(contains({ "New", "Agent Triage" }, local!status))),
        inPlace: local!status = local!story.scriptedStatus
      )
    )
  ),
  local!undecided: sum(a!forEach(items: local!storyStates, expression: if(fv!item.decided, 0, 1))),
  local!outOfPlace: a!flatten(a!forEach(items: local!storyStates, expression: if(and(fv!item.decided, not(fv!item.inPlace)), fv!item, {}))),
  local!firstOut: if(a!isNullOrEmpty(local!outOfPlace), null, index(local!outOfPlace, 1, null)),

  local!hasStamp: not(a!isNullOrEmpty(local!loadStamp)),
  local!loadedToday: if(local!hasStamp, text(local!loadStamp, "yyyy-mm-dd") = text(local!now, "yyyy-mm-dd"), false),
  local!ageSeconds: if(local!hasStamp, tointeger(round(86400 * (todecimal(local!now) - todecimal(local!loadStamp)), 0)), null),

  local!state: if(
    and(local!packetTrades = 0, local!demoCases = 0), "NOTHING_LOADED",
    if(and(local!hasStamp, not(local!loadedToday)), "LOADED_BEFORE_TODAY",
    if(not(local!loadedToday), "DID_NOT_FINISH",
    if(local!undecided = 0, if(a!isNullOrEmpty(local!firstOut), "READY", "STORY_OUT_OF_PLACE"),
    if(a!defaultValue(local!ageSeconds, local!runningLimitSeconds) < local!runningLimitSeconds, "RUNNING", "DID_NOT_FINISH"))))
  ),
  /* the pieces of the status line, each safe to build in any state */
  local!loadedAt: if(local!hasStamp, text(local!loadStamp, "h:mm a"), ""),
  local!outLabel: tostring(index(local!firstOut, "label", "")),
  local!outStatus: rule!SO_statusDisplay(status: tostring(index(local!firstOut, "status", ""))).label,
  local!outScripted: rule!SO_statusDisplay(status: tostring(index(local!firstOut, "scriptedStatus", ""))).label,

  a!map(
    state: local!state,
    /* the status line, word for word as ruled 2026-11-11 and 2026-11-12 */
    line: a!match(
      value: local!state,
      equals: "NOTHING_LOADED", then: "No demo loaded.",
      equals: "RUNNING", then: "Preparing the demo. About two minutes. Refresh this page to check.",
      equals: "READY", then: "Ready to present. Loaded today at " & local!loadedAt & ".",
      equals: "LOADED_BEFORE_TODAY", then: "Loaded before today. Prepare the demo again for fresh dates.",
      equals: "STORY_OUT_OF_PLACE", then: "Not ready. The " & local!outLabel & " case is "
        & local!outStatus & ", not " & local!outScripted & ". Prepare the demo again.",
      default: "The last run did not finish. Prepare the demo again."
    ),
    /* READY is green; nothing loaded and running are neutral; the other three are amber */
    tone: a!match(
      value: local!state,
      equals: "READY", then: "POSITIVE",
      whenTrue: contains({ "NOTHING_LOADED", "RUNNING" }, local!state), then: "NEUTRAL",
      default: "WARN"
    ),
    isRunning: local!state = "RUNNING",
    runName: local!name,
    packetTrades: local!packetTrades,
    demoCases: local!demoCases,
    loadStamp: local!loadStamp,
    ageSeconds: local!ageSeconds,
    stories: local!storyStates
  )
)
