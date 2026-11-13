/*
 * SO_demoRunState — the state of the demo run, for the Demo Admin console and
 * for SO_prepareRun. ONE RULE, so the page and the process cannot disagree
 * about whether a run is in progress.
 *
 * DERIVED FROM DATA THE PROCESSES WRITE:
 *   - the run record: SO Demo Run, one row per press of Prepare the demo.
 *     SO_prepareRun writes it (PREPARING) before it returns to the page, and
 *     SO_prepareRunSteps closes it (LOADED, or FAILED with the failed step's
 *     message). Added 2026-11-12: for the first half minute of a Prepare the
 *     last run is being cleared and no packet exists, so data alone read
 *     "Nothing loaded" and a second press was not refused;
 *   - the packet in Snowflake: SO Trade rows whose id starts with TRD9;
 *   - when it was loaded: the newest SCORED_AT among TRD9 predictions, which
 *     SIMULATE_FEED writes at call time in UTC;
 *   - the run's cases: SO Settlement Case rows whose session id IS the run
 *     name. A case with any other session id, or none, is not a demo case;
 *   - the stories and where each should end up: SO_intakePlan's story table.
 *
 * SEVEN STATES, tested in this order:
 *   NOTHING_LOADED       no TRD9 trades and no cases tagged with the run name
 *   LOADED_BEFORE_TODAY  the load stamp's date is not today
 *   STORY_OUT_OF_PLACE   loaded today; every story has its decision and at
 *                        least one is not in its scripted status
 *   HERO_PAST_CUTOFF     loaded today; every story has its decision and is in
 *                        its scripted status; the hero case has under two
 *                        hours to its cutoff, or is past it. Added 2026-11-12
 *                        on Scott's yes: a load at 2 AM still read "Ready to
 *                        present" at 9 AM, four hours after the hero's cutoff.
 *                        Widened the same day (ruled): the state starts two
 *                        hours BEFORE the cutoff and keeps its name. Its line
 *                        has two wordings, before the cutoff and after it
 *   READY                loaded today; every story has its decision and is in
 *                        its scripted status; the hero has two hours or more
 *                        to its cutoff
 *   RUNNING              a Prepare recorded as PREPARING whose packet has not
 *                        landed, under 5 minutes old (tested FIRST); or loaded
 *                        today, a story has no decision yet and the stamp is
 *                        under 5 minutes old
 *   DID_NOT_FINISH       loaded today; a story has no decision and the stamp
 *                        is 5 minutes old or more; or a PREPARING record
 *                        5 minutes old or more whose packet never landed.
 *                        Also any partly loaded state that fits no row above
 *
 * A STORY HAS ITS DECISION when its case's status is neither "New" nor
 * "Agent Triage". "Agent Triage" is not progress: triage writes it after the
 * agent has returned, so for the whole agent call the case still reads "New".
 *
 * THE HERO IS THE STORY LABELLED "hero" IN SO_intakePlan: the one case the
 * presenter still has to act on, so the one whose cutoff ends Ready. The other
 * two stories are finished when the run is. A story out of place is reported
 * first, because that line names the status. A hero with no cutoff stored
 * never leaves Ready on this test.
 *
 * READY ENDS TWO HOURS BEFORE THE HERO'S CUTOFF (ruled 2026-11-12). The hero
 * needs its broker confirmation lag, 1.15 hours, to fit the window. Inside the
 * last two hours its screen stops agreeing with its own assessment, so the run
 * is no longer one to present from. local!readyMarginHours is the one place
 * the two hours is set. The line's words "under two hours" are ruled text:
 * a new margin needs a new line, and both change together.
 *
 * WHO LOADED IT (ruled 2026-11-12, a second presenter uses the site). The
 * Ready line ends "by <first name> <last name>": the account that pressed
 * Prepare for the run now loaded. That press is the newest LOADED run record
 * for the run name whose press-to-close window holds the load stamp. A run
 * loaded any other way has no such record, and a later press that failed is
 * not the one that loaded it; in both cases, and when the record names nobody
 * or the account is not in the user directory, the line ends at the time.
 *
 * THE 5 MINUTES IS WHAT UNLOCKS A RUN THAT DIED. A failed agent run leaves its
 * case "New" for good; press to Ready measures about 100 seconds.
 *
 * A FAILED PREPARE DOES NOT GET A STATE OF ITS OWN. The state stays what the
 * data says (often "No demo loaded."); lastFailed and lastMessage carry the
 * failed step's message, word for word, until the next press.
 *
 * TODAY IS THE VIEWER'S DAY: both sides go through text(), which renders in
 * the viewer's time zone, so the stored UTC stamp and "now" are compared on
 * one calendar. `line` uses the same clock for "Loaded today at <time>".
 *
 * ri!asOf stands in for "now" when a state has to be read without waiting for
 * it (tomorrow, or six minutes after a load). Leave it empty everywhere else.
 *
 * ON A PAGE, THIS RULE IS READ ONCE, WHEN THE PAGE LOADS (found 2026-11-13).
 * Its local variables, the queries and now() among them, re-evaluate only when
 * what they depend on changes, and nothing they depend on changes while a page
 * is open. A page variable set to refresh always does not change that: the
 * docs say a rule's inner variables do not re-evaluate when the outer one
 * refreshes ("Nested rules need refreshAlways"). So the console did not show
 * Running after its own press until the page was refreshed. The rule is left
 * as it is, because a page that never re-reads it is what the ruling asks for
 * (no self-refresh). Instead it carries `whenRunning`: the line, tone and
 * isRunning of the Running state, for a page to show from the moment its own
 * press has started a run. The sentence and the tone stay defined here once.
 */
a!localVariables(
  local!name: a!defaultValue(ri!runName, cons!SO_DEMO_RUN_NAME),
  local!now: a!defaultValue(ri!asOf, now()),
  local!runningLimitSeconds: 300,
  /* Ready ends this many hours before the hero's cutoff. The one place it is set */
  local!readyMarginHours: 2,
  /* the Running state's line and tone, named because `whenRunning` returns them too */
  local!runningLine: "Preparing the demo. About two minutes. Refresh this page to check.",
  local!runningTone: "NEUTRAL",
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
    fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs' },
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
          a!map(caseId: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'], status: tostring(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status']), cutoff: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs']), {})
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
        cutoff: index(local!case, "cutoff", null),
        decided: and(not(a!isNullOrEmpty(local!case)), not(contains({ "New", "Agent Triage" }, local!status))),
        inPlace: local!status = local!story.scriptedStatus
      )
    )
  ),
  local!undecided: sum(a!forEach(items: local!storyStates, expression: if(fv!item.decided, 0, 1))),
  local!outOfPlace: a!flatten(a!forEach(items: local!storyStates, expression: if(and(fv!item.decided, not(fv!item.inPlace)), fv!item, {}))),
  local!firstOut: if(a!isNullOrEmpty(local!outOfPlace), null, index(local!outOfPlace, 1, null)),

  /* the hero: the story the presenter still has to act on before its cutoff */
  local!heroLabel: "hero",
  local!heroStories: a!flatten(a!forEach(items: local!storyStates, expression: if(tostring(fv!item.label) = local!heroLabel, fv!item, {}))),
  local!heroCutoff: if(a!isNullOrEmpty(local!heroStories), null, index(index(local!heroStories, 1, null), "cutoff", null)),
  local!heroPast: if(a!isNullOrEmpty(local!heroCutoff), false, todecimal(local!heroCutoff) <= todecimal(local!now)),
  /* todecimal() of a date and time is a day number, so the margin is hours / 24.
     Under the margin is not ready; exactly the margin is still ready. Past the cutoff is inside it too */
  local!heroInsideMargin: if(a!isNullOrEmpty(local!heroCutoff), false,
    todecimal(local!heroCutoff) - todecimal(local!now) < local!readyMarginHours / 24),

  local!hasStamp: not(a!isNullOrEmpty(local!loadStamp)),

  /* the newest press of Prepare for this run name */
  local!run: index(a!queryRecordType(
    recordType: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run',
    fields: { 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{477c5b8e-0603-48fc-831f-7a72c52081da}id', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{0e278cda-bebd-4ec9-b9b8-22eccb81982f}status', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{94f30f83-8a8e-4f51-bb08-d0b8a231865e}message', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{05f990f3-3a40-48e6-a066-f57cc1182b18}startedBy', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{d316b688-1b59-4b94-b1ca-bc8e117575c4}startedOn', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{5a053825-881f-4692-ab15-ca58351007de}updatedOn' },
    filters: a!queryFilter(field: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{93a0e45e-b7c3-43f6-b3cf-edc94de95457}runName', operator: "=", value: local!name),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{477c5b8e-0603-48fc-831f-7a72c52081da}id', ascending: false))
  ).data, 1, null),
  local!hasRun: not(a!isNullOrEmpty(local!run)),
  local!runStatus: if(local!hasRun, tostring(a!defaultValue(local!run['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{0e278cda-bebd-4ec9-b9b8-22eccb81982f}status'], "")), ""),
  local!runStartedOn: if(local!hasRun, local!run['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{d316b688-1b59-4b94-b1ca-bc8e117575c4}startedOn'], null),
  local!runAgeSeconds: if(a!isNullOrEmpty(local!runStartedOn), null,
    tointeger(round(86400 * (todecimal(local!now) - todecimal(local!runStartedOn)), 0))),
  /* pressed, and the packet that press will load has not landed yet */
  local!preparing: and(
    local!runStatus = "PREPARING",
    not(a!isNullOrEmpty(local!runStartedOn)),
    if(local!hasStamp, todecimal(local!loadStamp) < todecimal(a!defaultValue(local!runStartedOn, local!now)), true)
  ),
  local!preparingFresh: and(local!preparing, a!defaultValue(local!runAgeSeconds, local!runningLimitSeconds) < local!runningLimitSeconds),
  local!loadedToday: if(local!hasStamp, text(local!loadStamp, "yyyy-mm-dd") = text(local!now, "yyyy-mm-dd"), false),
  local!ageSeconds: if(local!hasStamp, tointeger(round(86400 * (todecimal(local!now) - todecimal(local!loadStamp)), 0)), null),

  /* the press that loaded the run now in place: the newest LOADED record for
     this run name, and only if the load stamp falls between its press and its close */
  local!loadedRun: index(a!queryRecordType(
    recordType: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run',
    fields: { 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{477c5b8e-0603-48fc-831f-7a72c52081da}id', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{05f990f3-3a40-48e6-a066-f57cc1182b18}startedBy', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{d316b688-1b59-4b94-b1ca-bc8e117575c4}startedOn', 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{5a053825-881f-4692-ab15-ca58351007de}updatedOn' },
    filters: {
      a!queryFilter(field: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{93a0e45e-b7c3-43f6-b3cf-edc94de95457}runName', operator: "=", value: local!name),
      a!queryFilter(field: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{0e278cda-bebd-4ec9-b9b8-22eccb81982f}status', operator: "=", value: "LOADED")
    },
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{477c5b8e-0603-48fc-831f-7a72c52081da}id', ascending: false))
  ).data, 1, null),
  local!hasLoadedRun: not(a!isNullOrEmpty(local!loadedRun)),
  local!loadedPressedOn: if(local!hasLoadedRun, local!loadedRun['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{d316b688-1b59-4b94-b1ca-bc8e117575c4}startedOn'], null),
  local!loadedClosedOn: if(local!hasLoadedRun, local!loadedRun['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{5a053825-881f-4692-ab15-ca58351007de}updatedOn'], null),
  local!loadedUsername: if(local!hasLoadedRun, tostring(a!defaultValue(local!loadedRun['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{05f990f3-3a40-48e6-a066-f57cc1182b18}startedBy'], "")), ""),
  local!loadedRunIsThisLoad: if(
    or(not(local!hasStamp), a!isNullOrEmpty(local!loadedPressedOn), a!isNullOrEmpty(local!loadedClosedOn)),
    false,
    and(
      todecimal(local!loadedPressedOn) <= todecimal(local!loadStamp),
      todecimal(local!loadStamp) <= todecimal(local!loadedClosedOn)
    )
  ),
  /* first and last name from the user directory. A query, not user(): an
     account that no longer exists returns no row here, where user() would
     take the whole rule down, and the console and Prepare with it */
  local!loadedUser: if(
    or(not(local!loadedRunIsThisLoad), a!isNullOrEmpty(local!loadedUsername)),
    null,
    index(a!queryRecordType(
      recordType: 'recordType!{SYSTEM_RECORD_TYPE_USER}User',
      fields: { 'recordType!{SYSTEM_RECORD_TYPE_USER}User.fields.{SYSTEM_RECORD_TYPE_USER_FIELD_firstName}firstName', 'recordType!{SYSTEM_RECORD_TYPE_USER}User.fields.{SYSTEM_RECORD_TYPE_USER_FIELD_lastName}lastName' },
      filters: a!queryFilter(field: 'recordType!{SYSTEM_RECORD_TYPE_USER}User.fields.{SYSTEM_RECORD_TYPE_USER_FIELD_username}username', operator: "=", value: touser(local!loadedUsername)),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
    ).data, 1, null)
  ),
  local!loadedBy: if(a!isNullOrEmpty(local!loadedUser), "", trim(
    tostring(a!defaultValue(local!loadedUser['recordType!{SYSTEM_RECORD_TYPE_USER}User.fields.{SYSTEM_RECORD_TYPE_USER_FIELD_firstName}firstName'], "")) & " "
    & tostring(a!defaultValue(local!loadedUser['recordType!{SYSTEM_RECORD_TYPE_USER}User.fields.{SYSTEM_RECORD_TYPE_USER_FIELD_lastName}lastName'], ""))
  )),

  local!state: if(
    local!preparingFresh, "RUNNING",
    if(local!preparing, "DID_NOT_FINISH",
    if(and(local!packetTrades = 0, local!demoCases = 0), "NOTHING_LOADED",
    if(and(local!hasStamp, not(local!loadedToday)), "LOADED_BEFORE_TODAY",
    if(not(local!loadedToday), "DID_NOT_FINISH",
    if(local!undecided = 0,
      if(not(a!isNullOrEmpty(local!firstOut)), "STORY_OUT_OF_PLACE", if(local!heroInsideMargin, "HERO_PAST_CUTOFF", "READY")),
    if(a!defaultValue(local!ageSeconds, local!runningLimitSeconds) < local!runningLimitSeconds, "RUNNING", "DID_NOT_FINISH"))))))
  ),
  /* the pieces of the status line, each safe to build in any state */
  local!loadedAt: if(local!hasStamp, text(local!loadStamp, "h:mm a"), ""),
  local!heroCutoffAt: if(a!isNullOrEmpty(local!heroCutoff), "", text(local!heroCutoff, "h:mm a")),
  local!outLabel: tostring(index(local!firstOut, "label", "")),
  local!outStatus: rule!SO_statusDisplay(status: tostring(index(local!firstOut, "status", ""))).label,
  local!outScripted: rule!SO_statusDisplay(status: tostring(index(local!firstOut, "scriptedStatus", ""))).label,

  a!map(
    state: local!state,
    /* the status line, word for word as ruled 2026-11-11 and 2026-11-12. The
       "passed its cutoff" line is the exception: Scott ruled the state, and a
       session wrote its words on the pattern of the story line below. He has
       since ruled both hero wordings as they stand here */
    line: a!match(
      value: local!state,
      equals: "NOTHING_LOADED", then: "No demo loaded.",
      equals: "RUNNING", then: local!runningLine,
      equals: "READY", then: "Ready to present. Loaded today at " & local!loadedAt
        & if(a!isNullOrEmpty(local!loadedBy), "", " by " & local!loadedBy) & ".",
      equals: "HERO_PAST_CUTOFF", then: if(local!heroPast,
        "Not ready. The " & local!heroLabel & " case passed its cutoff at "
          & local!heroCutoffAt & ". Prepare the demo again.",
        "Not ready. The " & local!heroLabel & " case has under two hours to cutoff. Prepare the demo again."
      ),
      equals: "LOADED_BEFORE_TODAY", then: "Loaded before today. Prepare the demo again for fresh dates.",
      equals: "STORY_OUT_OF_PLACE", then: "Not ready. The " & local!outLabel & " case is "
        & local!outStatus & ", not " & local!outScripted & ". Prepare the demo again.",
      default: "The last run did not finish. Prepare the demo again."
    ),
    /* READY is green; nothing loaded and running are neutral; every other state is amber */
    tone: a!match(
      value: local!state,
      equals: "READY", then: "POSITIVE",
      equals: "RUNNING", then: local!runningTone,
      equals: "NOTHING_LOADED", then: "NEUTRAL",
      default: "WARN"
    ),
    isRunning: local!state = "RUNNING",
    /* what a page shows from the moment its own press has started a run. The page
       cannot learn that by re-reading this rule (header), so it reads these instead
       of the three keys above. Same sentence, same tone, isRunning true */
    whenRunning: a!map(state: "RUNNING", line: local!runningLine, tone: local!runningTone, isRunning: true),
    /* the newest press of Prepare: a failure stays here, word for word, until the next press */
    lastFailed: local!runStatus = "FAILED",
    lastMessage: if(local!hasRun, tostring(a!defaultValue(local!run['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{94f30f83-8a8e-4f51-bb08-d0b8a231865e}message'], "")), ""),
    lastAt: if(local!hasRun, local!run['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{5a053825-881f-4692-ab15-ca58351007de}updatedOn'], null),
    runRecordId: if(local!hasRun, local!run['recordType!{c48c9eb9-96e3-4642-b9c5-63c67b6e023a}SO Demo Run.fields.{477c5b8e-0603-48fc-831f-7a72c52081da}id'], null),
    runStatus: local!runStatus,
    runName: local!name,
    packetTrades: local!packetTrades,
    demoCases: local!demoCases,
    loadStamp: local!loadStamp,
    ageSeconds: local!ageSeconds,
    heroCutoff: local!heroCutoff,
    /* true once the cutoff itself has passed: tells the two HERO_PAST_CUTOFF wordings apart */
    heroPast: local!heroPast,
    /* who pressed Prepare for the run now loaded, first and last name; empty when nobody is named */
    loadedBy: local!loadedBy,
    stories: local!storyStates
  )
)
