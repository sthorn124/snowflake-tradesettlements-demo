/*
 * SO_supervisorCommand — the house view. Structural authority:
 * mockups/supervisor_command.html.
 *
 * ================= ONE QUERY, ONE ROW SET, EVERY NUMBER =================
 * THE RUNWAY/KPI COHERENCE INVARIANT IS ENFORCED BY CONSTRUCTION, not by care.
 * Every figure on this screen — the six KPIs, the runway bars, the desk grid,
 * the reason mix, the analyst queues, the escalations table — comes from ONE
 * query (local!cases) and ONE derived row set (local!rows). Nothing is counted
 * twice by two different expressions, so a chart and the KPI above it cannot
 * drift apart: "unresolved value inside the critical window" IS the
 * inside-window KPI, because it is literally the same list filtered once.
 *
 * The failure this rules out is silent. Two queries per card, each individually
 * correct, together produce a screen whose bar chart and headline number
 * disagree — and nothing errors, because both queries returned valid rows. That
 * is why the invariant is structural rather than a review checklist item.
 *
 * NOR IS CUTOFF STATE RECOMPUTED HERE. SO_cutoffDisplay already emits
 * hoursRemaining, isPast, insideCriticalWindow and a local-frame displayHour —
 * the last two exist FOR this screen. A derived-state rule carries its state to
 * consumers and consumers read it (CLAUDE.md); re-deriving "is this inside four
 * hours" locally is how the KPI and the rail came to disagree at gate A.
 *
 * ================= WHAT THE PERSONA CHANGES =================
 * RECORD-LEVEL SECURITY DOES THE DESK SCOPING AND THIS SCREEN DOES NOTHING TO
 * HELP IT. sam.supervisor carries an unconditional branch on SO Trade and sees
 * every desk; alex.analyst is scoped to EQ_FLOW and would see a one-desk house
 * view with EQ_FLOW-only totals. BOTH ARE CORRECT. The page is gated to
 * SO Supervisors, and the analyst-shaped result is what proves the scoping is
 * real rather than cosmetic (appian-supplemental §5: a count taken as an analyst
 * is never a total).
 *
 * ================= CROSS-CURRENCY, STATED PLAINLY =================
 * The book runs EUR, GBP, JPY and CHF at once and NOTHING IN THE DATA CARRIES AN
 * FX RATE. Every aggregate goes through rule!SO_fxToUsd, which holds indicative
 * static rates, and every figure it produces renders as "USD eq." with the basis
 * in its tooltip. See that rule's header. Per-currency totals would be honest
 * too, and useless — "value at risk across all desks" is not a number you can
 * read five times.
 *
 * TYPE SCALE: SMALL muted labels, STANDARD semibold ink values everywhere this
 * screen composes text itself. THE ONE EXCEPTION IS THE KPI VALUE, which
 * SO_kpiCard renders at LARGE — verified by render, not assumed. That is the
 * ratified KPI treatment from the watchlist gate and it is not this screen's to
 * change; the rail canon's "no LARGE anywhere" governs rails and panels, where
 * a headline number would be competing with prose. A KPI tile IS a headline
 * number and nothing else. Noted explicitly because an earlier draft of this
 * comment claimed no LARGE on the screen at all, which the render disproved.
 *
 * PROVENANCE: field-level marks on Snowflake intelligence (fail probability,
 * predicted reason, counterparty history); card-level "live read" tags on
 * wholly-Snowflake-served panels. Counts of our own cases and every penalty
 * figure are Appian-computed and carry no mark.
 */
a!localVariables(
  /* ---------------- THE ONE QUERY ----------------
     No session filter: this is the BOOK, not one demo run. Record-level
     security is what scopes it, which is the whole point of the persona
     contrast above. */
  local!cases: a!queryRecordType(
    recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
    fields: {
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4ac3036c-ab51-4940-a5d5-363e4f2a8a09}modifiedOn',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier'
    },
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500,
      sort: a!sortInfo(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs', ascending: true))
  ).data,

  /* ---------------- ONE DERIVED ROW PER CASE ---------------- */
  local!rows: a!forEach(
    items: local!cases,
    expression: a!localVariables(
      local!co: rule!SO_cutoffDisplay(cutoffTs: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs', null)),
      local!st: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status', ""),
      local!ccy: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency', ""),
      local!notional: todecimal(a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', null), 0)),
      local!sd: rule!SO_statusDisplay(status: local!st),
      local!isResolved: or(local!st = "Resolved - Straight Through", local!st = "Resolved - Analyst"),
      a!map(
        caseId: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', null),
        tradeId: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID', ""),
        status: local!st,
        statusLabel: index(local!sd, "label", local!st),
        statusColor: index(local!sd, "color", "#454F5C"),
        desk: a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk', ""), "—"),
        failReason: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason', ""),
        reasonLabel: index(rule!SO_failReasonDisplay(failReason: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason', ""), short: false), "label", "—"),
        ticker: a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker', ""), "—"),
        instName: a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name', ""), ""),
        cptyName: a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name', ""), ""),
        cptyTier: rule!SO_riskTierDisplay(riskTier: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier', "")),
        predTier: rule!SO_riskTierDisplay(riskTier: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier', "")),
        probability: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability', null),
        notional: local!notional,
        ccy: local!ccy,
        usd: rule!SO_fxToUsd(amount: local!notional, currency: local!ccy),
        lag: todecimal(a!defaultValue(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs', null), 0)),
        hasLag: not(a!isNullOrEmpty(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs', null))),
        cutoff: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs', null),
        hrsLeft: todecimal(a!defaultValue(index(local!co, "hoursRemaining", 0), 0)),
        isPast: a!defaultValue(index(local!co, "isPast", false), false),
        inWindow: a!defaultValue(index(local!co, "insideCriticalWindow", false), false),
        /* LOCAL-FRAME hour for the runway buckets, from SO_cutoffDisplay —
           derived through text() there precisely because hour() returns UTC. */
        displayHour: index(local!co, "displayHour", null),
        atText: index(local!co, "atText", ""),
        isResolved: local!isResolved,
        isOpen: not(local!isResolved),
        isEscalated: local!st = "Escalated",
        inRemediation: local!st = "In Remediation",
        straightThrough: local!st = "Resolved - Straight Through",
        assignee: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee', null),
        assigneeName: if(
          a!isNullOrEmpty(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee', null)),
          "Unassigned",
          user(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee', null), "firstName") & " " & user(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee', null), "lastName")
        ),
        confidence: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore', null),
        createdOn: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn', null),
        modifiedOn: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4ac3036c-ab51-4940-a5d5-363e4f2a8a09}modifiedOn', null),
        /* THE DAY IT RESOLVED, from the field that actually records it. Written
           by the resolution write path on every lane — the agent's straight
           through, the analyst's disposition — so unlike modifiedOn it is
           populated on process-written rows as well as fixtures (measured on
           all of both, 2026-09-24). This is the cycle trend's grouping key. */
        resolvedOn: index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn', null),
        ageHrs: if(a!isNullOrEmpty(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn', null)), 0.0, todecimal(index(fv!item, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn', null) - now()) * -24)
      )
    )
  ),

  /* ---------------- THE FILTERED SETS — index(), never a second query ----------------
     wherecontains over a parallel boolean list, because a!flatten of
     if(cond,{x},{}) returns a value whose type shifts when nothing matches and
     count() on it then lies (§4: count() returns 1 on a list of dictionaries). */
  local!openIdx: wherecontains(true, a!forEach(items: local!rows, expression: index(fv!item, "isOpen", false))),
  local!open: if(a!isNullOrEmpty(local!openIdx), {}, index(local!rows, local!openIdx, {})),
  local!escIdx: wherecontains(true, a!forEach(items: local!rows, expression: index(fv!item, "isEscalated", false))),
  local!escalated: if(a!isNullOrEmpty(local!escIdx), {}, index(local!rows, local!escIdx, {})),
  local!resIdx: wherecontains(true, a!forEach(items: local!rows, expression: index(fv!item, "isResolved", false))),
  local!resolved: if(a!isNullOrEmpty(local!resIdx), {}, index(local!rows, local!resIdx, {})),
  /* INSIDE THE CRITICAL WINDOW — this list IS the KPI and IS the leftmost
     runway bars. Same rows, filtered once, read twice. */
  local!insideIdx: wherecontains(true, a!forEach(items: local!open, expression: index(fv!item, "inWindow", false))),
  local!inside: if(a!isNullOrEmpty(local!insideIdx), {}, index(local!open, local!insideIdx, {})),
  /* CARRIED OVER: open and already past its cutoff — it did not clear in its own
     cycle, which is what carryover means. The mockup's "▲12 vs yesterday" and
     "10-day avg" cannot be built: a single-session fixture has no yesterday to
     difference against, and inventing one is the fixture-prose failure. */
  local!carriedIdx: wherecontains(true, a!forEach(items: local!open, expression: index(fv!item, "isPast", false))),
  local!carried: if(a!isNullOrEmpty(local!carriedIdx), {}, index(local!open, local!carriedIdx, {})),

  local!openCount: count(local!open),
  local!resolvedCount: count(local!resolved),
  local!varUsd: if(local!openCount = 0, 0, sum(a!forEach(items: local!open, expression: index(fv!item, "usd", 0)))),
  local!insideUsd: if(count(local!inside) = 0, 0, sum(a!forEach(items: local!inside, expression: index(fv!item, "usd", 0)))),
  local!stCount: if(local!resolvedCount = 0, 0, sum(a!forEach(items: local!resolved, expression: if(index(fv!item, "straightThrough", false), 1, 0)))),
  local!stPct: if(local!resolvedCount = 0, 0, tointeger(round(100 * local!stCount / local!resolvedCount, 0))),

  /* PENALTIES AVOIDED — one day of CSDR accrual on each resolved case, had it
     failed. SO_penaltyAccrual is the SAME rule the case screen uses, so the
     house figure and the case figure cannot disagree. Appian-computed, no mark. */
  local!avoidedUsd: if(local!resolvedCount = 0, 0, sum(a!forEach(
    items: local!resolved,
    expression: rule!SO_fxToUsd(
      amount: todecimal(a!defaultValue(index(rule!SO_penaltyAccrual(value: index(fv!item, "notional", 0), currency: index(fv!item, "ccy", "")), "daily", 0), 0)),
      currency: index(fv!item, "ccy", "")
    )
  ))),

  /* OLDEST ESCALATION, for the SLA sub-line. Waiting is measured from the write
     that escalated the case (modifiedOn), not from creation. */
  local!oldestEscHrs: if(count(local!escalated) = 0, 0.0, max(a!forEach(
    items: local!escalated,
    expression: if(a!isNullOrEmpty(index(fv!item, "modifiedOn", null)), 0.0,
      todecimal(index(fv!item, "modifiedOn", null) - now()) * -24)
  ))),

  /* ---------------- HISTORIC DAYS LATE — A SAMPLE, LABELLED AS ONE ----------------
     SETTLEMENT_HISTORY holds thousands of fails; this reads the 500 most recent
     and averages DAYS_LATE. Calling a 500-row sample "the average" would be the
     fixture-prose failure in a new costume, so the sub-line says "last 500"
     out loud. */
  local!lateSample: a!queryRecordType(
    recordType: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History',
    fields: { 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{6f093ccc-cc93-42dc-9971-356029b80a4c}daysLate' },
    filters: a!queryFilter(field: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{7a475c04-027c-4437-8de5-926105a81572}status', operator: "=", value: "FAILED"),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500,
      sort: a!sortInfo(field: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{73e751ad-433c-4555-994e-266d8aac867a}actualSettlementDate', ascending: false))
  ).data,
  local!avgDaysLate: if(
    a!isNullOrEmpty(local!lateSample),
    null,
    sum(a!forEach(items: local!lateSample, expression: todecimal(a!defaultValue(index(fv!item, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{6f093ccc-cc93-42dc-9971-356029b80a4c}daysLate', 0), 0))))
      / count(local!lateSample)
  ),

  /* ---------------- DESK ROLL-UP ---------------- */
  /* DISTINCT VIA union(list, list) — NOT union(list, {}). MEASURED here:
     the empty-array form fails validation with "Invalid types, can only act on
     data of the same type (Text, Any Type)", because {} is Any Type and union
     will not mix. Unioning a list with itself is the working distinct idiom. */
  local!deskList: a!forEach(items: local!rows, expression: index(fv!item, "desk", "—")),
  local!desks: if(a!isNullOrEmpty(local!deskList), {}, union(local!deskList, local!deskList)),
  local!deskRows: a!forEach(
    items: local!desks,
    expression: a!localVariables(
      local!d: fv!item,
      local!dOpenIdx: wherecontains(true, a!forEach(items: local!open, expression: index(fv!item, "desk", "") = local!d)),
      local!dOpen: if(a!isNullOrEmpty(local!dOpenIdx), {}, index(local!open, local!dOpenIdx, {})),
      local!dResIdx: wherecontains(true, a!forEach(items: local!resolved, expression: index(fv!item, "desk", "") = local!d)),
      local!dRes: if(a!isNullOrEmpty(local!dResIdx), {}, index(local!resolved, local!dResIdx, {})),
      a!map(
        desk: local!d,
        open: count(local!dOpen),
        usd: if(count(local!dOpen) = 0, 0, sum(a!forEach(items: local!dOpen, expression: index(fv!item, "usd", 0)))),
        inside: if(count(local!dOpen) = 0, 0, sum(a!forEach(items: local!dOpen, expression: if(index(fv!item, "inWindow", false), 1, 0)))),
        escalated: if(count(local!dOpen) = 0, 0, sum(a!forEach(items: local!dOpen, expression: if(index(fv!item, "isEscalated", false), 1, 0)))),
        resolved: count(local!dRes),
        stPct: if(count(local!dRes) = 0, null,
          tointeger(round(100 * sum(a!forEach(items: local!dRes, expression: if(index(fv!item, "straightThrough", false), 1, 0))) / count(local!dRes), 0)))
      )
    )
  ),
  /* Decimal is correct here — this one is only ever a divisor for the bar
     scale, never a wherecontains needle. Guarded against zero so an empty book
     cannot divide by nothing. */
  local!maxDeskUsd: todecimal(max({ 1, if(count(local!deskRows) = 0, 1, max(a!forEach(items: local!deskRows, expression: todecimal(index(fv!item, "usd", 0))))) })),

  /* ---------------- REASON MIX ----------------
     THE FOUR CANON REASONS IN CANON ORDER, not whatever the data happens to
     contain — a reason with zero open cases is information ("nothing on
     counterparty default today"), and letting the list be data-driven would make
     it silently disappear. */
  local!reasonKeys: { "insufficient_securities", "funding_gap", "operational_error", "counterparty_default" },
  local!reasonRows: a!forEach(
    items: local!reasonKeys,
    expression: a!localVariables(
      local!r: fv!item,
      local!rIdx: wherecontains(true, a!forEach(items: local!open, expression: index(fv!item, "failReason", "") = local!r)),
      local!rSet: if(a!isNullOrEmpty(local!rIdx), {}, index(local!open, local!rIdx, {})),
      a!map(
        reason: local!r,
        label: index(rule!SO_failReasonDisplay(failReason: local!r, short: false), "label", local!r),
        n: count(local!rSet),
        usd: if(count(local!rSet) = 0, 0, sum(a!forEach(items: local!rSet, expression: index(fv!item, "usd", 0))))
      )
    )
  ),
  /* tointeger() ON THE MAX, and it is not decoration: max() over an INTEGER
     list returns Number (Decimal) (§4), and the wherecontains below then refuses
     to compare it against the integer list — "Invalid types, can only act on
     data of the same type (Number (Decimal), Number (Integer))". Measured here. */
  local!maxReasonN: tointeger(if(count(local!reasonRows) = 0, 1, max({ 1, max(a!forEach(items: local!reasonRows, expression: tointeger(index(fv!item, "n", 0)))) }))),
  local!topReason: if(count(local!reasonRows) = 0, null, index(local!reasonRows, index(wherecontains(local!maxReasonN, a!forEach(items: local!reasonRows, expression: tointeger(index(fv!item, "n", 0)))), 1, 1), null)),

  /* ---------------- ANALYST QUEUES ----------------
     Open work only, grouped by who holds it, with Unassigned as a real bucket
     rather than a gap — unowned work is the thing a supervisor is looking for. */
  local!ownerList: a!forEach(items: local!open, expression: index(fv!item, "assigneeName", "Unassigned")),
  local!owners: if(a!isNullOrEmpty(local!ownerList), {}, union(local!ownerList, local!ownerList)),
  local!queueRows: a!forEach(
    items: local!owners,
    expression: a!localVariables(
      local!o: fv!item,
      local!qIdx: wherecontains(true, a!forEach(items: local!open, expression: index(fv!item, "assigneeName", "Unassigned") = local!o)),
      local!q: if(a!isNullOrEmpty(local!qIdx), {}, index(local!open, local!qIdx, {})),
      a!map(
        owner: local!o,
        isUnassigned: local!o = "Unassigned",
        n: count(local!q),
        urgent: if(count(local!q) = 0, 0, sum(a!forEach(items: local!q, expression: if(index(fv!item, "inWindow", false), 1, 0)))),
        desks: a!localVariables(
          local!dl: a!forEach(items: local!q, expression: index(fv!item, "desk", "")),
          if(a!isNullOrEmpty(local!dl), "", joinarray(union(local!dl, local!dl), " · "))
        ),
        oldestHrs: if(count(local!q) = 0, 0.0, max(a!forEach(items: local!q, expression: todecimal(index(fv!item, "ageHrs", 0)))))
      )
    )
  ),
  local!maxQueue: tointeger(if(count(local!queueRows) = 0, 1, max({ 1, max(a!forEach(items: local!queueRows, expression: tointeger(index(fv!item, "n", 0)))) }))),

  /* ---------------- CUTOFF RUNWAY ----------------
     TWELVE HOURLY BUCKETS FROM NOW, in the LOCAL frame. The bucket index is
     whole hours remaining, and the label is built from text(now(),"HH") — the
     same local-frame route SO_cutoffDisplay uses for displayHour, so a bar and
     the wall clock under it cannot disagree (hour() would return UTC).
     Past-cutoff open cases fall outside this window ON PURPOSE: they are the
     carryover figure in the first KPI, and counting them here as well would
     show the same case twice. */
  local!nowHour: tointeger(text(now(), "HH")),
  local!runwayCats: a!forEach(items: enumerate(12), expression: text(mod(local!nowHour + fv!item, 24), "00") & ":00"),
  local!runwayUnresolved: a!forEach(
    items: enumerate(12),
    expression: a!localVariables(
      local!h: fv!item,
      sum(a!forEach(items: local!open, expression:
        if(and(index(fv!item, "hrsLeft", -1) > 0, tointeger(floor(index(fv!item, "hrsLeft", 0))) = local!h, not(index(fv!item, "inRemediation", false))),
          todecimal(index(fv!item, "usd", 0)) / 1000000, 0)))
    )
  ),
  local!runwayRemediation: a!forEach(
    items: enumerate(12),
    expression: a!localVariables(
      local!h: fv!item,
      sum(a!forEach(items: local!open, expression:
        if(and(index(fv!item, "hrsLeft", -1) > 0, tointeger(floor(index(fv!item, "hrsLeft", 0))) = local!h, index(fv!item, "inRemediation", false)),
          todecimal(index(fv!item, "usd", 0)) / 1000000, 0)))
    )
  ),
  local!runwayTotal: sum(local!runwayUnresolved) + sum(local!runwayRemediation),
  /* RECONCILE THE RUNWAY AGAINST THE HEADLINE, ON SCREEN.
     The bars cover twelve hours; Value at risk covers the whole open book. On
     this book that is 519M of bars under a 653M headline, and a supervisor is
     right to ask where the other 134M went. Two places, both legitimate:
     already past cutoff (the carryover figure) and settling beyond the window.
     Rather than leave the reader to subtract, the card says it. The invariant
     is not "every number is equal" — it is that every number comes from the
     same rows and the screen accounts for the difference. */
  local!beyondIdx: wherecontains(true, a!forEach(items: local!open,
    expression: and(not(index(fv!item, "isPast", false)), index(fv!item, "hrsLeft", 0) >= 12))),
  local!beyond: if(a!isNullOrEmpty(local!beyondIdx), {}, index(local!open, local!beyondIdx, {})),
  local!outsideUsd: local!varUsd - (local!runwayTotal * 1000000),

  /* ---------------- STRAIGHT-THROUGH TREND ----------------
     Resolved cases grouped by the DAY they resolved. With a single-session
     fixture this is one cycle, and a one-point line is not a trend — the card
     renders an explicit insufficient-data state instead of drawing a line
     through a single dot and implying a direction. */
  /* A DATELESS RESOLVED CASE IS REAL, AND IT IS NOT A CYCLE. modifiedOn comes
     back NULL on every process-written case (CLAUDE.md, measured 2026-09-23),
     and a case with no usable date cannot be placed on a timeline. Both reads
     below therefore guard it identically — the guard was on cycleList and
     MISSING on cIdx, which took the entire page down with "A null parameter
     has been passed" the moment a demo run resolved anything straight through.
     The two must stay symmetric: they are the same grouping key computed twice.

     AND THE EMPTY BUCKET IS DROPPED RATHER THAN GROUPED, which is the half of
     this fix that is not about crashing. Left in, a dateless case became a
     SECOND cycle keyed "" — enough to flip haveTrend true and draw the line
     chart with a blank category, plotting a trend between a real day and a
     bucket with no date. This card's own rule is that one point is not a trend
     because it implies a direction the data cannot support; a phantom second
     point asserts the same thing less honestly.

     WHAT THE EXCLUSION COSTS: nothing outside this chart. local!resolved still
     feeds resolvedCount, stCount, stPct, avoidedUsd and the per-desk STP
     column, so a dateless straight-through case is counted in the KPI, in the
     penalties-avoided figure and in its desk's row — it is absent only from the
     by-cycle trend, which is the one place a date is the axis.

     THE FIELD QUESTION IS RULED AND THE SWAP IS DONE (2026-09-24). This groups
     by resolvedOn — the field that actually records the resolution — where it
     used to group by modifiedOn as a proxy. modifiedOn comes back NULL on every
     process-written row, so the proxy silently excluded exactly the cases a
     demo produces; resolvedOn is written by the resolution path on both lanes
     and was measured populated on all three fixtures and on the agent's
     straight-through case. The guards below stay anyway: they are cheap, and
     "resolved with no resolution date" is a state worth surviving rather than
     crashing on if a future write path ever produces one. BOTH READS MOVED
     TOGETHER — they are the same key computed twice, and splitting them is how
     the original defect happened. */
  local!cycleList: a!forEach(items: local!resolved, expression: if(a!isNullOrEmpty(index(fv!item, "resolvedOn", null)), "", text(index(fv!item, "resolvedOn", null), "yyyy-mm-dd"))),
  local!cycles: if(
    a!isNullOrEmpty(local!cycleList),
    {},
    a!flatten(a!forEach(
      items: union(local!cycleList, local!cycleList),
      expression: if(fv!item = "", {}, { fv!item })
    ))
  ),
  local!cycleRows: a!forEach(
    items: local!cycles,
    expression: a!localVariables(
      local!c: fv!item,
      local!cIdx: wherecontains(true, a!forEach(items: local!resolved, expression: if(a!isNullOrEmpty(index(fv!item, "resolvedOn", null)), "", text(index(fv!item, "resolvedOn", null), "yyyy-mm-dd")) = local!c)),
      local!cSet: if(a!isNullOrEmpty(local!cIdx), {}, index(local!resolved, local!cIdx, {})),
      a!map(
        cycle: local!c,
        n: count(local!cSet),
        pct: if(count(local!cSet) = 0, 0,
          tointeger(round(100 * sum(a!forEach(items: local!cSet, expression: if(index(fv!item, "straightThrough", false), 1, 0))) / count(local!cSet), 0)))
      )
    )
  ),
  local!haveTrend: count(local!cycleRows) >= 2,

  /* ---------------- ESCALATIONS, WITH THE REASON COMPOSED ----------------
     "Why escalated" is composed from the row at render time, in the same order
     the triage lane decides it: a reason override first (counterparty default
     routes to a human whatever it scored), then timing, then the gate. A stored
     free-text reason would drift from the case; this cannot. */
  /* SORTED OLDEST-FIRST FOR REAL, because the card header claims it. Sorting a
     dictionary array goes through todatasubset + a!pagingInfo(sort:) — the
     Function Recipes form; a!sortInfo's own page prohibits it and is wrong
     (appian-supplemental §1: a working example outranks a general prohibition,
     proven by render). */
  local!escRowsUnsorted: a!forEach(
    items: local!escalated,
    expression: a!localVariables(
      local!e: fv!item,
      local!waitHrs: if(a!isNullOrEmpty(index(local!e, "modifiedOn", null)), 0.0,
        todecimal(index(local!e, "modifiedOn", null) - now()) * -24),
      local!lag: todecimal(index(local!e, "lag", 0)),
      local!hrs: todecimal(index(local!e, "hrsLeft", 0)),
      local!timingFails: and(index(local!e, "hasLag", false), or(index(local!e, "isPast", false), local!lag >= local!hrs)),
      a!map(
        caseId: index(local!e, "caseId", null),
        tradeId: index(local!e, "tradeId", ""),
        ticker: index(local!e, "ticker", "—"),
        instName: index(local!e, "instName", ""),
        desk: index(local!e, "desk", "—"),
        reasonLabel: index(local!e, "reasonLabel", "—"),
        failReason: index(local!e, "failReason", ""),
        money: rule!SO_fmtMoney(amount: index(local!e, "notional", 0), currency: index(local!e, "ccy", ""), compact: true),
        why: if(
          index(local!e, "failReason", "") = "counterparty_default",
          "Credit decision required",
          if(local!timingFails, "Confirmation lag exceeds window", "Held below the release gate")
        ),
        whyNote: if(
          index(local!e, "failReason", "") = "counterparty_default",
          "counterparty-default cases route to a human regardless of score",
          if(
            local!timingFails,
            if(
              index(local!e, "isPast", false),
              text(round(local!lag, 1), "0.0") & "h lag · cutoff passed at " & index(local!e, "atText", "") & " — fail management, not remediation",
              text(round(local!lag, 1), "0.0") & "h lag · " & text(round(local!hrs, 1), "0.0") & "h to cutoff — cannot complete straight-through"
            ),
            if(
              a!isNullOrEmpty(index(local!e, "confidence", null)),
              "no auto-release score on this case",
              "auto-release score " & tointeger(round(100 * todecimal(index(local!e, "confidence", 0)), 0)) & " below the gate at " & tointeger(round(100 * cons!SO_CONFIDENCE_THRESHOLD, 0))
            )
          )
        ),
        waitHrs: local!waitHrs,
        waitText: floor(local!waitHrs) & "h " & text(floor((local!waitHrs - floor(local!waitHrs)) * 60), "00") & "m",
        waitColor: if(local!waitHrs >= 2, "#B3261E", if(local!waitHrs >= 1, "#96590A", "#1B2330"))
      )
    )
  ),
  local!escRows: if(
    count(local!escRowsUnsorted) = 0,
    {},
    todatasubset(local!escRowsUnsorted, a!pagingInfo(startIndex: 1, batchSize: 100,
      sort: a!sortInfo(field: "waitHrs", ascending: false))).data
  ),

  a!formLayout(
    backgroundColor: "#F3F5F8",
    contentsWidth: "FULL",
    focusOnFirstInput: false,
    contents: {
      /* ================= PAGE HEAD ================= */
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "Supervisor Command", color: "#1B2330", size: "MEDIUM", style: "STRONG"),
          a!richTextItem(
            text: "    " & if(count(local!desks) = 1, "1 desk", count(local!desks) & " desks")
              & "  ·  settlement cycle " & rule!SO_fmtDayDate(value: today()) & "  ·  T+1",
            color: "#454F5C", size: "SMALL"
          )
        }
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        marginBelow: "STANDARD",
        tooltip: "Fail probabilities and predicted reasons are read live from Snowflake; case state is Appian's.",
        value: {
          rule!SO_snowflakeMark(showWhen: true),
          a!richTextItem(text: " Predictions live from Snowflake", color: "#3E7396", size: "SMALL", style: "STRONG"),
          /* THE DESK COUNT IS WHAT THE READER CAN SEE, not a hardcoded five.
             Under an analyst's row security this line honestly says "1 desk". */
          a!richTextItem(
            text: "  ·  house view across " & count(local!desks) & if(count(local!desks) = 1, " desk", " desks")
              & "  ·  " & count(local!rows) & " cases in scope  ·  read " & text(now(), "hh:mm:ss"),
            color: "#454F5C", size: "SMALL"
          )
        }
      ),

      /* ================= KPI BAND OF SIX ================= */
      a!columnsLayout(
        marginBelow: "STANDARD",
        columns: {
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Predicted fails — open",
            value: local!openCount & "",
            valueColor: "#1B2330",
            unit: "",
            /* CARRYOVER, and the honest version of the mockup's sub-line. There
               is no "vs yesterday" and no "10-day average" in a single-session
               fixture, so neither is invented; carried-over means open and
               already past its own cutoff, which is a real state on this book.
               The days-late figure is a labelled 500-row sample. */
            /* ONE LINE. Six tiles are only equal height while every sub fits
               one line, and this one was 65 characters against a ~37-character
               budget in a sixth of 1400px. The sampling qualification is not
               deleted — it moves to the tooltip, where length is free. */
            sub: count(local!carried) & " carried over"
              & if(a!isNullOrEmpty(local!avgDaysLate), "",
                  " · avg " & text(round(local!avgDaysLate, 1), "0.0") & "d late"),
            accentColor: "#9AA6B3",
            snowMarked: false,
            tooltip: "Carried over = open and already past its own cutoff, so it did not clear in its own cycle."
              & if(a!isNullOrEmpty(local!avgDaysLate), "",
                  " Days late is the mean DAYS_LATE over the " & count(local!lateSample)
                  & " most recent settled fails in SETTLEMENT_HISTORY — a sample of the history, not all of it.")
          )),
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Value at risk",
            value: rule!SO_fmtMoney(amount: local!varUsd, currency: "", compact: true),
            valueColor: "#1B2330",
            unit: "USD eq.",
            sub: "across " & local!openCount & " open item" & if(local!openCount = 1, "", "s"),
            accentColor: "#3E7396",
            snowMarked: true,
            /* THE CONVERSION BASIS BELONGS WITH THE PROVENANCE NOTE, not in the
               sub-line. SO_kpiCard composes the two into one tooltip, so a reader
               who hovers the Snowflake mark gets both facts at once: where the
               number came from, and what was done to it. */
            tooltip: "Cross-currency total: the book runs EUR, GBP, JPY and CHF, and nothing in the source data carries an FX rate. Converted at indicative static rates (SO_fxToUsd) for aggregation only — not a market feed, not a rate of record."
          )),
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Inside critical window",
            value: count(local!inside) & "",
            valueColor: if(count(local!inside) > 0, "#96590A", "#17715B"),
            unit: "",
            sub: "cutoff within 4h · " & rule!SO_fmtMoney(amount: local!insideUsd, currency: "", compact: true) & " USD eq.",
            accentColor: "#C98A2B",
            snowMarked: false,
            tooltip: ""
          )),
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Escalations awaiting action",
            value: count(local!escalated) & "",
            valueColor: if(count(local!escalated) > 0, "#B3261E", "#17715B"),
            unit: "",
            sub: if(
              count(local!escalated) = 0,
              "nothing waiting on a supervisor",
              "oldest waiting " & floor(local!oldestEscHrs) & "h "
                & text(floor((local!oldestEscHrs - floor(local!oldestEscHrs)) * 60), "00") & "m · SLA 1h"
            ),
            accentColor: "#B3261E",
            snowMarked: false,
            tooltip: "SLA is one hour from the escalation write. Waiting is measured from that write, not from when the case was created."
          )),
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Straight-through today",
            value: if(local!resolvedCount = 0, "—", local!stPct & ""),
            valueColor: if(local!resolvedCount = 0, "#6E7885", if(local!stPct >= 60, "#17715B", "#96590A")),
            unit: if(local!resolvedCount = 0, "", "%"),
            sub: if(local!resolvedCount = 0, "nothing resolved yet today",
              local!stCount & " of " & local!resolvedCount & " resolved · gate at "
                & tointeger(round(100 * cons!SO_CONFIDENCE_THRESHOLD, 0))),
            accentColor: "#17715B",
            snowMarked: false,
            tooltip: ""
          )),
          a!columnLayout(contents: rule!SO_kpiCard(
            label: "Penalties avoided (est.)",
            value: rule!SO_fmtMoney(amount: local!avoidedUsd, currency: "", compact: true),
            valueColor: "#17715B",
            unit: "USD eq. / day",
            sub: local!resolvedCount & if(local!resolvedCount = 1, " fail prevented", " fails prevented") & " · CSDR est.",
            accentColor: "#17715B",
            snowMarked: false,
            tooltip: "One day of CSDR-style accrual on each resolved case, had it failed — the same SO_penaltyAccrual the case screen uses, so the house figure and the case figure cannot disagree."
          ))
        }
      ),

      /* ============ WORK ZONE — wide left, rail right ============
         LAYOUT RULED BY SCOTT, 2026-09-09, AND IT DEPARTS FROM THE MOCKUP.
         Recorded here because a structural delta is a delta: the mockup's own
         DOM (supervisor_command.html) puts the straight-through chart BESIDE the
         runway in a two-card `.trendband` row, and puts reasons + analyst queues
         in a `.midrow` INSIDE the left column, with only the Ask panel in the
         360px rail. The first build followed that DOM. This build does not: one
         two-column zone, everything narrow moved into the rail, Ask at its top.

         THE MOCKUP IS STILL THE STRUCTURAL AUTHORITY, so it is now out of date
         with the build — logged, and it needs the same edit in the pre-Phase-5
         mockup pass or the next session will "restore" the old shape from it.

         Why the rail reads better, for the record: the runway and the desk grid
         are the two WIDE artefacts and they now share a column sized for them,
         instead of the runway being squeezed to 1.6fr beside a chart that only
         needed 1fr. Everything that is a list — ask, trend, reasons, queues —
         is narrow by nature and stacks.

         ===== BOTTOM-ALIGNING THE TWO COLUMNS IS NOT NATIVELY ACHIEVABLE =====
         Checked properly rather than guessed at. THE MECHANISM THAT EXISTS:
         a!cardLayout HAS a `height` parameter — EXTRA_SHORT / SHORT / SHORT_PLUS
         / MEDIUM / MEDIUM_PLUS / TALL / TALL_PLUS / EXTRA_TALL / AUTO (default).
         THE MECHANISM THAT DOES NOT: there is no "stretch to fill the column"
         and no cross-column bottom-align. `alignVertical` on a!columnsLayout
         positions content within the row; it does not stretch a card.

         AND THE HEIGHT PARAMETER IS THE WRONG TOOL HERE, by its own
         documentation: "When set to a fixed value, the card contents will
         SCROLL if they don't fit within the selected height." A fixed height is
         therefore clipping with a scrollbar — precisely what was excluded. A
         supervisor scrolling inside a 300px card to find the fourth analyst
         queue is worse than an uneven column edge.

         a!cardGroupLayout(cardHeight:) equalises cards WITH EACH OTHER, which
         would make the four rail cards mutually equal — it still cannot make
         their total match the left column, and it inherits the same scroll
         behaviour.

         WHAT WAS DONE INSTEAD: shortened the left column at its only elastic
         point (the chart, TALL -> MEDIUM), which also pulls Escalations toward
         the fold. Any residual is absorbed by SPACING — each rail card carries
         marginBelow STANDARD, which is the lever with the finest granularity
         that does not touch content. The residual gap CANNOT be quantified from
         a session: chart and card heights are named enums with no documented
         pixel values, and the render tree carries no geometry at all. It is a
         browser measurement, and it is on the gate C checklist. */
      a!columnsLayout(
        marginBelow: "STANDARD",
        alignVertical: "TOP",
        columns: {
          a!columnLayout(width: "AUTO", contents: {
            a!cardLayout(
                        padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
                        contents: {
                          a!sideBySideLayout(
                            alignVertical: "MIDDLE", marginBelow: "STANDARD",
                            items: {
                              a!sideBySideItem(item: a!richTextDisplayField(
                                labelPosition: "COLLAPSED",
                                value: a!richTextItem(text: "CUTOFF RUNWAY — NEXT 12 HOURS", color: "#454F5C", size: "SMALL", style: "STRONG")
                              )),
                              a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                                labelPosition: "COLLAPSED", align: "RIGHT",
                                value: a!richTextItem(text: "USD eq. settling per hour, at risk only", color: "#6E7885", size: "SMALL")
                              ))
                            }
                          ),
                          a!richTextDisplayField(
                            showWhen: local!runwayTotal = 0,
                            labelPosition: "COLLAPSED",
                            value: a!richTextItem(
                              text: "Nothing at risk in the next twelve hours." & if(count(local!carried) = 0, "",
                                "  " & count(local!carried) & if(count(local!carried) = 1, " case is", " cases are") & " already past cutoff and shown as carryover."),
                              color: "#6E7885", size: "STANDARD"
                            )
                          ),
                          /* COLUMN CHART, NOT BAR. a!barChartField draws HORIZONTAL bars — the
                             hours would have run down the side as rows, and an empty hour
                             would have been a labelled empty row rather than a gap in a
                             skyline. a!columnChartField is the vertical one. This was NOT a
                             measured choice originally; "bar" was reached for without
                             checking which axis Appian puts the categories on, and the docs
                             are explicit both ways ("Displays numerical data as horizontal
                             bars" / "as vertical bars"). Corrected 2026-09-09.
                             HEIGHT "MEDIUM", NOT "TALL" (changed 2026-09-09).
                             TALL was reaching for balance with the four-card
                             rail and overshot in both directions at once: it
                             lengthened the left column AND pushed the
                             Escalations card — the last node on the page, and
                             the one a supervisor most needs — further below the
                             fold. Shortening the chart fixes the second problem
                             outright and most of the first. See the work-zone
                             note for what remains and why it cannot be closed
                             natively. */
                          a!columnChartField(
                            showWhen: local!runwayTotal > 0,
                            labelPosition: "COLLAPSED",
                            categories: local!runwayCats,
                            series: {
                              a!chartSeries(label: "Predicted fail, unresolved", data: local!runwayUnresolved, color: "#B3564E"),
                              a!chartSeries(label: "In remediation", data: local!runwayRemediation, color: "#DDA94E")
                            },
                            stacking: "NORMAL",
                            yAxisTitle: "M USD eq.",
                            showLegend: true,
                            showDataLabels: false,
                            allowDecimalAxisLabels: true,
                            height: "MEDIUM",
                            colorScheme: a!colorSchemeCustom(colors: { "#B3564E", "#DDA94E" })
                          ),
                          /* THE MOCKUP'S THIRD BAND — grey "on track" — IS NOT BUILDABLE and
                             is not faked. It needs total settlement value per hour across the
                             whole book, and EXPECTED_SETTLEMENT_DATE is a DATE with no time
                             component, so an hourly split of everything settling today does
                             not exist in the data at all. Only cases carry an intraday
                             cutoff. The chart therefore shows what IS at risk rather than
                             at-risk as a share of an invented denominator. */
                              /* "settling in the next 12 hours", NOT "in this
                                 window". THE PHRASE COLLIDED with the KPI band's
                                 "Inside critical window", which means the FOUR-hour
                                 cutoff window — two different windows on one screen,
                                 one of them unnamed. Naming the horizon in hours
                                 removes the ambiguity outright. */
                          a!richTextDisplayField(
                            showWhen: local!runwayTotal > 0,
                            labelPosition: "COLLAPSED",
                            value: {
                              a!richTextItem(
                                text: rule!SO_fmtMoney(amount: local!runwayTotal * 1000000, currency: "", compact: true) & " USD eq. settling in the next 12 hours",
                                color: "#1B2330", size: "SMALL", style: "STRONG"
                              ),
                              a!richTextItem(
                                text: if(
                                  local!outsideUsd <= 0,
                                  "  —  the whole open book settles inside twelve hours.",
                                  "  ·  " & rule!SO_fmtMoney(amount: local!outsideUsd, currency: "", compact: true)
                                    & " outside them (" & count(local!carried) & " past cutoff, "
                                    & count(local!beyond) & " settling later) — the two make up the "
                                    & rule!SO_fmtMoney(amount: local!varUsd, currency: "", compact: true) & " headline."
                                ),
                                color: "#454F5C", size: "SMALL"
                              ),
                              char(10),
                              a!richTextItem(
                                text: "At-risk value only — the book's total hourly settlement volume is not derivable (settlement dates carry no time of day).",
                                color: "#6E7885", size: "SMALL"
                              )
                            }
                          )
                        }
                      ),
            a!cardLayout(
                          padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
                          contents: {
                            a!sideBySideLayout(
                              alignVertical: "MIDDLE", marginBelow: "STANDARD",
                              items: {
                                a!sideBySideItem(item: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED",
                                  value: a!richTextItem(text: "EXPOSURE BY DESK", color: "#454F5C", size: "SMALL", style: "STRONG")
                                )),
                                a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT",
                                  tooltip: "Value at risk is Snowflake-sourced notional, converted at indicative static rates.",
                                  value: {
                                    rule!SO_snowflakeMark(showWhen: true),
                                    a!richTextItem(text: " value at risk", color: "#3E7396", size: "SMALL", style: "STRONG")
                                  }
                                ))
                              }
                            ),
                            a!gridField(
                              labelPosition: "COLLAPSED",
                              data: local!deskRows,
                              spacing: "DENSE",
                              borderStyle: "LIGHT",
                              shadeAlternateRows: false,
                              columns: {
                                /* HEADERS: A GRID HEADER HAS NO WRAP CONTROL AT ALL.
                                   a!gridColumn's `label` is a plain Text parameter —
                                   no preventWrapping on it and none on the column, so
                                   the only levers are the WIDTH and the WORD.
                                   "Escalated" broke mid-word in a NARROW column
                                   ("Escalate / d") — the gate-A defect in a new grid.
                                   "Inside 4h" is the SAME LENGTH and is fine, because
                                   it contains a space and breaks there. THE RULE IS
                                   ABOUT UNBREAKABLE WORDS, not length: a header that
                                   is one long word in a narrow column gets shortened,
                                   and the full term moves to helpTooltip so nothing is
                                   lost. Every header in this grid now carries an
                                   explicit width and a tooltip. */
                                a!gridColumn(label: "Desk", width: "NARROW", 
                                  helpTooltip: "Trading desk. Analysts are scoped to their own desk; a supervisor sees them all.",
                                  value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", preventWrapping: true,
                                  value: a!richTextItem(text: index(fv!row, "desk", "—"), color: "#2E5A88", style: "STRONG", size: "STANDARD"))),
                                a!gridColumn(label: "Open", width: "NARROW", align: "END", 
                                  helpTooltip: "Cases not yet resolved on this desk.",
                                  value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                                  value: a!richTextItem(text: index(fv!row, "open", 0), color: "#1B2330", style: "STRONG", size: "STANDARD"))),
                                /* VALUE-AT-RISK BAR AS RICH-TEXT GLYPHS — the proven pattern.
                                   A native progress bar cannot sit inside a grid cell beside
                                   its own number, and twelve cells scale cleanly against the
                                   heaviest desk. preventWrapping is CORRECT here and only
                                   here: this cell IS one line by construction, with no
                                   char(10) in it to collapse. */
                                a!gridColumn(label: "Value at risk", width: "AUTO", align: "END", value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                                  value: a!localVariables(
                                    local!fill: tointeger(max({ 0, min({ 12, tointeger(round(12 * todecimal(index(fv!row, "usd", 0)) / local!maxDeskUsd, 0)) }) })),
                                    {
                                      a!forEach(items: enumerate(12) + 1, expression: a!richTextItem(
                                        text: "▇",
                                        color: if(fv!item <= local!fill, "#7FA3C4", "#EEF1F5")
                                      )),
                                      a!richTextItem(text: "  " & rule!SO_fmtMoney(amount: index(fv!row, "usd", 0), currency: "", compact: true),
                                        color: "#1B2330", style: "STRONG", size: "STANDARD")
                                    }
                                  ))),
                                a!gridColumn(label: "Inside 4h", width: "NARROW", align: "END", 
                                  helpTooltip: "Open cases whose cutoff falls within the next four hours.",
                                  value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                                  value: a!richTextItem(
                                    text: index(fv!row, "inside", 0),
                                    color: if(index(fv!row, "inside", 0) > 0, "#B3261E", "#6E7885"),
                                    style: if(index(fv!row, "inside", 0) > 0, "STRONG", "PLAIN"), size: "STANDARD"))),
                                a!gridColumn(label: "Esc.", width: "NARROW", align: "END", 
                                  helpTooltip: "Escalated — open cases awaiting a supervisor decision.",
                                  value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                                  value: a!richTextItem(
                                    text: index(fv!row, "escalated", 0),
                                    color: if(index(fv!row, "escalated", 0) > 0, "#96590A", "#6E7885"),
                                    style: if(index(fv!row, "escalated", 0) > 0, "STRONG", "PLAIN"), size: "STANDARD"))),
                                a!gridColumn(label: "STP", width: "NARROW", align: "END", 
                                  helpTooltip: "Straight-through — the share of this desk's resolved cases that cleared without a human touch.",
                                  value: a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                                  value: a!richTextItem(
                                    text: if(a!isNullOrEmpty(index(fv!row, "stPct", null)), "—", index(fv!row, "stPct", 0) & "%"),
                                    color: if(a!isNullOrEmpty(index(fv!row, "stPct", null)), "#6E7885",
                                      if(index(fv!row, "stPct", 0) >= 60, "#17715B", "#96590A")),
                                    style: "STRONG", size: "STANDARD")))
                              }
                            ),
                            /* HOUSE TOTAL AS A LINE, NOT A GRID ROW. A totals row inside a
                               locally-sourced grid is indistinguishable from a desk and
                               would be counted as one by anything reading the grid. */
                            a!richTextDisplayField(
                              labelPosition: "COLLAPSED",
                              value: {
                                a!richTextItem(text: "House   ", color: "#454F5C", size: "SMALL", style: "STRONG"),
                                a!richTextItem(
                                  text: local!openCount & " open  ·  " & rule!SO_fmtMoney(amount: local!varUsd, currency: "", compact: true)
                                    & " USD eq.  ·  " & count(local!inside) & " inside 4h  ·  " & count(local!escalated) & " escalated"
                                    & if(local!resolvedCount = 0, "", "  ·  " & local!stPct & "% straight-through"),
                                  color: "#1B2330", size: "SMALL", style: "STRONG"
                                )
                              }
                            )
                          }
                        )
          }),
          a!columnLayout(width: "MEDIUM_PLUS", contents: {
            a!cardLayout(
                        padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
                        decorativeBarPosition: "TOP", decorativeBarColor: "#3E7396",
                        contents: {
                          a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            value: {
                              rule!SO_snowflakeMark(showWhen: true),
                              a!richTextItem(text: "  ASK ACROSS THE BOOK", color: "#454F5C", size: "SMALL", style: "STRONG")
                            }
                          ),
                          a!richTextDisplayField(
                            labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                            value: a!richTextItem(
                              text: "Answers computed in Snowflake over all 50,000 trades — nothing copied, nothing synced.",
                              color: "#6E7885", size: "SMALL"
                            )
                          ),
                          /* THE THREE CHIPS ARE THE SEMANTIC MODEL'S VERIFIED QUERIES, named
                             exactly. They are inert, like the input below them. */
                          a!tagField(
                            labelPosition: "COLLAPSED",
                            marginBelow: "STANDARD",
                            tags: {
                              a!tagItem(text: "Fail rate trend", backgroundColor: "#EEF4FA", textColor: "#2E5A88"),
                              a!tagItem(text: "Top failing counterparties", backgroundColor: "#EEF4FA", textColor: "#2E5A88"),
                              a!tagItem(text: "Notional at risk", backgroundColor: "#EEF4FA", textColor: "#2E5A88")
                            }
                          ),
                          /* NO SPECIMEN ANSWER IN THE THREAD, and that is a deliberate
                             departure from the mockup, which shows a full Cortex reply with
                             a counterparty table and figures. Rendering that here would put
                             a fabricated answer on screen wearing "Answered by Snowflake
                             Cortex Analyst" — a machine-attributed claim that no machine
                             made. It is the same error as the forged escalation, in a
                             friendlier costume. The shell holds the shape; the answer
                             arrives in Phase 6 when the call is real. */
                          a!cardLayout(
                            padding: "STANDARD", shape: "SEMI_ROUNDED", style: "#FAFBFC", showBorder: false,
                            marginBelow: "STANDARD",
                            contents: a!richTextDisplayField(
                              labelPosition: "COLLAPSED",
                              value: a!richTextItem(
                                text: "Pick a question above, or ask your own.",
                                color: "#6E7885", size: "SMALL"
                              )
                            )
                          ),
                          a!textField(
                            labelPosition: "COLLAPSED",
                            placeholder: "Ask about the book — fails, exposure, counterparties, trends…",
                            value: null,
                            saveInto: {},
                            disabled: true,
                            marginBelow: "NONE"
                          )
                        }
                      ),
            a!cardLayout(
                        padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
                        contents: {
                          a!richTextDisplayField(
                            labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                            value: a!richTextItem(text: "STRAIGHT-THROUGH RATE BY CYCLE", color: "#454F5C", size: "SMALL", style: "STRONG")
                          ),
                          /* ONE CYCLE IS NOT A TREND. Drawing a line through a single point
                             implies a direction the data cannot support, so the card says
                             what it has and what it would need. */
                          a!richTextDisplayField(
                            showWhen: not(local!haveTrend),
                            labelPosition: "COLLAPSED",
                            value: {
                              a!richTextItem(
                                text: if(local!resolvedCount = 0, "No resolved cases yet", count(local!cycleRows) & " cycle on record"),
                                color: "#6E7885", style: "STRONG", size: "STANDARD"
                              ),
                              char(10),
                              a!richTextItem(
                                text: "A trend needs at least two settlement cycles. Today's rate is "
                                  & if(local!resolvedCount = 0, "not yet measurable", local!stPct & "% (" & local!stCount & " of " & local!resolvedCount & ")")
                                  & ", against a target of 60%.",
                                color: "#454F5C", size: "SMALL"
                              )
                            }
                          ),
                          a!lineChartField(
                            showWhen: local!haveTrend,
                            labelPosition: "COLLAPSED",
                            categories: a!forEach(items: local!cycleRows, expression: index(fv!item, "cycle", "")),
                            series: a!chartSeries(label: "Straight-through %", data: a!forEach(items: local!cycleRows, expression: index(fv!item, "pct", 0))),
                            yAxisMin: 0, yAxisMax: 100,
                            referenceLines: a!chartReferenceLine(label: "target 60%", value: 60, color: "#B3261E", style: "DASH"),
                            showLegend: false,
                            height: "SHORT",
                            colorScheme: a!colorSchemeCustom(colors: { "#2E5A88" })
                          ),
                          a!richTextDisplayField(
                            showWhen: local!haveTrend,
                            labelPosition: "COLLAPSED",
                            value: a!richTextItem(
                              text: "Gate held at " & tointeger(round(100 * cons!SO_CONFIDENCE_THRESHOLD, 0)) & " throughout.",
                              color: "#6E7885", size: "SMALL"
                            )
                          )
                        }
                      ),
            a!cardLayout(
                              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
                              contents: {
                                a!sideBySideLayout(
                                  alignVertical: "MIDDLE", marginBelow: "STANDARD",
                                  items: {
                                    a!sideBySideItem(item: a!richTextDisplayField(
                                      labelPosition: "COLLAPSED",
                                      value: a!richTextItem(text: "OPEN FAILS BY PREDICTED REASON", color: "#454F5C", size: "SMALL", style: "STRONG")
                                    )),
                                    a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                                      labelPosition: "COLLAPSED", align: "RIGHT",
                                      tooltip: "Live from Snowflake — the model's predicted fail reason on each open case.",
                                      value: {
                                        rule!SO_snowflakeMark(showWhen: true),
                                        a!richTextItem(text: " predicted reasons", color: "#3E7396", size: "SMALL", style: "STRONG")
                                      }
                                    ))
                                  }
                                ),
                                /* ---- REASON ROWS: THE GLYPH BUDGET IS SIZED TO THE
                                   RAIL, and the previous version was not.
                                   It put 16 glyphs in a FLEXIBLE middle
                                   sideBySideItem between two fixed 3X siblings, so
                                   the fixed siblings claimed their width first, the
                                   glyph run got whatever remained of MEDIUM_PLUS,
                                   and preventWrapping turned that overflow into an
                                   ellipsis — a bar chart ending in "…". Same
                                   starvation family as the gate-A ticker beside a
                                   MINIMIZE sibling, and the canon rule is the same:
                                   a fixed-glyph run must own its line, not compete
                                   for it.

                                   BUDGET 14, taken from evidence rather than
                                   arithmetic: the Analyst Queues card directly below
                                   renders 14 glyphs in this same MEDIUM_PLUS rail
                                   followed by a LONGER trailer ("   9 open  ·  oldest
                                   7.4h  ·  3 inside 4h", ~41 characters) and does not
                                   truncate. This row's trailer is ~16 characters
                                   ("   8  ·  489.5M"), so it sits well inside a
                                   budget already proven in the same column.

                                   NO preventWrapping HERE. It carries a char(10), and
                                   preventWrapping collapses char(10) paragraphs into
                                   one truncated line (§2) — which is what it is being
                                   removed to avoid. */
                                a!forEach(
                                  items: local!reasonRows,
                                  expression: a!localVariables(
                                    local!r: fv!item,
                                    local!fill: tointeger(max({ 0, min({ 14, tointeger(round(14 * tointeger(index(local!r, "n", 0)) / local!maxReasonN, 0)) }) })),
                                    local!isTop: tointeger(index(local!r, "n", 0)) = local!maxReasonN,
                                    a!richTextDisplayField(
                                      labelPosition: "COLLAPSED",
                                      marginBelow: "LESS",
                                      value: {
                                        a!richTextItem(text: index(local!r, "label", "—"), color: "#1B2330", size: "STANDARD", style: "STRONG"),
                                        char(10),
                                        a!forEach(items: enumerate(14) + 1, expression: a!richTextItem(
                                          text: "▇",
                                          color: if(fv!item <= local!fill, if(local!isTop, "#A8574F", "#54759B"), "#EEF1F5")
                                        )),
                                        a!richTextItem(text: "   " & index(local!r, "n", 0), color: "#1B2330", size: "STANDARD", style: "STRONG"),
                                        a!richTextItem(text: "  ·  " & rule!SO_fmtMoney(amount: index(local!r, "usd", 0), currency: "", compact: true),
                                          color: "#454F5C", size: "SMALL")
                                      }
                                    )
                                  )
                                ),
                                /* THE INSIGHT FOOTER IS COMPUTED, NOT WRITTEN. It names
                                   whichever reason actually leads and says what that implies,
                                   so it cannot go stale against the bars above it. The
                                   mockup's day-over-day deltas (▲7, ▼2) are NOT built: a
                                   single-session fixture has no prior cycle, and a delta
                                   against nothing is a fabricated number. */
                                a!richTextDisplayField(
                                  labelPosition: "COLLAPSED",
                                  value: if(
                                    or(a!isNullOrEmpty(local!topReason), local!openCount = 0),
                                    a!richTextItem(text: "No open predicted fails on the book.", color: "#6E7885", size: "SMALL"),
                                    {
                                      a!richTextItem(text: index(local!topReason, "label", ""), color: "#1B2330", size: "SMALL", style: "STRONG"),
                                      a!richTextItem(
                                        text: " leads the open book at " & index(local!topReason, "n", 0) & " of " & local!openCount
                                          & " — " & a!match(
                                            value: index(local!topReason, "reason", ""),
                                            equals: "insufficient_securities", then: "borrow-desk capacity is the constraint",
                                            equals: "funding_gap", then: "treasury timing is the constraint",
                                            equals: "operational_error", then: "instruction quality is the constraint",
                                            equals: "counterparty_default", then: "credit review is the constraint",
                                            default: "review the remediation mix"
                                          ) & ".",
                                        color: "#454F5C", size: "SMALL"
                                      )
                                    }
                                  )
                                )
                              }
                            ),
            a!cardLayout(
                              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
                              contents: {
                                a!richTextDisplayField(
                                  labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                                  value: {
                                    a!richTextItem(text: "ANALYST QUEUES", color: "#454F5C", size: "SMALL", style: "STRONG"),
                                    a!richTextItem(text: "   open work, by who holds it", color: "#6E7885", size: "SMALL")
                                  }
                                ),
                                a!richTextDisplayField(
                                  showWhen: count(local!queueRows) = 0,
                                  labelPosition: "COLLAPSED",
                                  value: a!richTextItem(text: "No open cases on the book.", color: "#6E7885", size: "STANDARD")
                                ),
                                a!forEach(
                                  items: local!queueRows,
                                  expression: a!localVariables(
                                    local!q: fv!item,
                                    local!fill: tointeger(max({ 0, min({ 14, tointeger(round(14 * tointeger(index(local!q, "n", 0)) / local!maxQueue, 0)) }) })),
                                    local!urg: tointeger(max({ 0, min({ 14, tointeger(round(14 * tointeger(index(local!q, "urgent", 0)) / local!maxQueue, 0)) }) })),
                                    a!richTextDisplayField(
                                      labelPosition: "COLLAPSED",
                                      marginBelow: "LESS",
                                      value: {
                                        a!richTextItem(
                                          text: index(local!q, "owner", ""),
                                          color: if(index(local!q, "isUnassigned", false), "#96590A", "#1B2330"),
                                          size: "STANDARD", style: "STRONG"
                                        ),
                                        a!richTextItem(text: "   " & index(local!q, "desks", ""), color: "#6E7885", size: "SMALL"),
                                        char(10),
                                        a!forEach(items: enumerate(14) + 1, expression: a!richTextItem(
                                          text: "▇",
                                          color: if(fv!item <= local!urg, "#A8574F", if(fv!item <= local!fill, "#7FA3C4", "#EEF1F5"))
                                        )),
                                        a!richTextItem(text: "   " & index(local!q, "n", 0) & " open", color: "#1B2330", size: "SMALL", style: "STRONG"),
                                        a!richTextItem(
                                          text: "  ·  oldest " & text(round(todecimal(index(local!q, "oldestHrs", 0)), 1), "0.0") & "h"
                                            & if(index(local!q, "urgent", 0) = 0, "", "  ·  " & index(local!q, "urgent", 0) & " inside 4h"),
                                          color: if(index(local!q, "urgent", 0) > 0, "#96590A", "#6E7885"), size: "SMALL"
                                        )
                                      }
                                    )
                                  )
                                ),
                                a!richTextDisplayField(
                                  showWhen: count(local!queueRows) > 0,
                                  labelPosition: "COLLAPSED",
                                  value: a!richTextItem(
                                    text: local!openCount & " in queue across " & count(local!queueRows)
                                      & if(count(local!queueRows) = 1, " holder", " holders"),
                                    color: "#6E7885", size: "SMALL"
                                  )
                                )
                              }
                            )
          })
        }
      ),

      /* ================= ESCALATIONS — FULL WIDTH ================= */
      a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
              contents: {
                a!sideBySideLayout(
                  alignVertical: "MIDDLE", marginBelow: "STANDARD",
                  items: {
                    a!sideBySideItem(item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextItem(text: "ESCALATIONS AWAITING SUPERVISOR", color: "#454F5C", size: "SMALL", style: "STRONG"),
                        a!richTextItem(text: "   held by the agent or referred by an analyst · oldest first", color: "#6E7885", size: "SMALL")
                      }
                    )),
                    a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT",
                      value: a!richTextItem(
                        text: count(local!escRows) & if(count(local!escRows) = 1, " open", " open"),
                        color: "#6E7885", size: "SMALL"
                      )
                    ))
                  }
                ),
                a!richTextDisplayField(
                  showWhen: count(local!escRows) = 0,
                  labelPosition: "COLLAPSED",
                  value: a!richTextItem(
                    text: "Nothing is waiting on a supervisor. Escalated cases appear here with the reason the agent or the analyst gave.",
                    color: "#6E7885", size: "STANDARD"
                  )
                ),
                a!gridField(
                  showWhen: count(local!escRows) > 0,
                  labelPosition: "COLLAPSED",
                  data: local!escRows,
                  spacing: "DENSE",
                  borderStyle: "LIGHT",
                  shadeAlternateRows: false,
                  columns: {
                    /* ONE DOOR: the case id is the only link out of this row. */
                    a!gridColumn(label: "Case", width: "NARROW", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: a!richTextItem(
                        text: "SO-" & index(fv!row, "caseId", ""),
                        link: if(a!isNullOrEmpty(index(fv!row, "caseId", null)), null,
                          a!recordLink(recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case', identifier: index(fv!row, "caseId", null))),
                        linkStyle: "STANDALONE",
                        color: "#2E5A88", style: "STRONG", size: "STANDARD"))),
                    /* AUDITED IN THE SAME PASS. Every header here is short or
                       breaks at a space, so none wraps mid-word — but the grid
                       carried TWO "AUTO" columns and the canon allows exactly one
                       (the widest absorbs the remainder; two of them share it
                       unpredictably). Instrument is now MEDIUM; "Why escalated"
                       keeps AUTO because the composed why-note is the longest
                       content in the row. */
                    a!gridColumn(label: "Instrument", width: "MEDIUM", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: {
                        a!richTextItem(text: index(fv!row, "ticker", "—"), color: "#1B2330", style: "STRONG", size: "STANDARD"),
                        a!richTextItem(text: "   " & index(fv!row, "instName", ""), color: "#454F5C", size: "SMALL")
                      })),
                    a!gridColumn(label: "Desk", width: "NARROW", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: a!richTextItem(text: index(fv!row, "desk", "—"), color: "#454F5C", size: "STANDARD"))),
                    a!gridColumn(label: "Fail reason", width: "NARROW", 
                      helpTooltip: "The model's predicted fail reason, read live from Snowflake.",
                      value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: a!richTextItem(text: index(fv!row, "reasonLabel", "—"), color: "#1B2330", size: "STANDARD"))),
                    a!gridColumn(label: "Value", width: "NARROW", align: "END", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                      value: a!richTextItem(text: index(fv!row, "money", ""), color: "#1B2330", style: "STRONG", size: "STANDARD"))),
                    /* WHY ESCALATED — headline plus the arithmetic under it. NO
                       preventWrapping on this one: it carries a char(10) and must
                       stack, which is exactly the cell that preventWrapping would
                       silently collapse into one truncated line. */
                    a!gridColumn(label: "Why escalated", width: "AUTO", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextItem(text: index(fv!row, "why", ""), color: "#1B2330", size: "STANDARD"),
                        char(10),
                        a!richTextItem(text: index(fv!row, "whyNote", ""), color: "#6E7885", size: "SMALL")
                      })),
                    a!gridColumn(label: "Waiting", width: "NARROW", align: "END", 
                      helpTooltip: "Time since the escalation was written. SLA is one hour.",
                      value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                      value: a!richTextItem(
                        text: index(fv!row, "waitText", ""),
                        color: index(fv!row, "waitColor", "#1B2330"), style: "STRONG", size: "STANDARD")))
                  }
                )
              }
            )
    }
  )
)
