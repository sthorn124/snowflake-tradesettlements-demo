/*
 * SO_analystWatchlist — the settlement analyst's pre-settlement queue.
 * Display target: mockups/analyst_watchlist.html (v5, banked 2026-09-23).
 * Data: live record reads only; every figure on this screen is computed.
 *
 * WHAT v5 CHANGED. The flat open-queue grid became THREE stacked queues —
 * NEEDS YOUR ACTION, ESCALATED, CLEARED THIS BATCH — with a Latest scoring
 * batch band between the KPI strip and the queues. The rail is unchanged.
 *
 * DESK SCOPING IS NOT IMPLEMENTED HERE AND MUST NOT BE. Record-level security
 * on SO Trade and SO Settlement Case already restricts SO Analysts to their
 * desk and lets SO Supervisors see every row, so this interface contains no
 * desk filter, no desk condition and no mention of a desk in any query. What
 * each persona sees is a property of the record type, inherited
 * (appian-supplemental §12). THE BATCH QUERY READS SO TRADE, NOT SO TRADE
 * PREDICTIONS, FOR EXACTLY THIS REASON: security is defined on the Trade, so
 * anchoring the batch there makes the band desk-scoped by construction rather
 * than by a filter this screen would have to be trusted to keep correct.
 *
 * ONE DEFINITION OF "OPEN", SHARED BY THE KPI AND THE QUEUES. local!openStatuses
 * is the five open statuses; local!caseRows is that query and nothing else.
 * The open-fails KPI counts it; the two case queues PARTITION it (escalated /
 * not escalated). They therefore agree by construction — the KPI cannot drift
 * from the rows beneath it, because it is not computed separately.
 *
 * ONE DEFINITION OF "THE BATCH". local!batchTrades is SO Trade filtered to the
 * reserved TRD9 packet range — the same predicate the demo console uses for its
 * "demo trades" count, so console and watchlist cannot disagree about what is
 * loaded. local!hasBatch governs three things at once: the band, the cleared
 * queue, and the straight-through KPI. With no run loaded all three say nothing
 * rather than saying zero (see the no-run note on the band).
 *
 * THE REFRESH BEAT. local!caseRows and local!batchTrades carry refreshInterval
 * 0.5 (30 seconds, the platform's shortest permitted interval) with
 * refreshAlways, so the queues pick up feed-created cases with no user
 * interaction and no browser reload — the Act 1 moment. local!lastRead watches
 * caseRows and carries the interval too, because a refresh returning identical
 * data would otherwise leave the timestamp stale.
 * NOTE: a variable with refreshInterval CANNOT be saved into, which is why the
 * selection and the view-all toggle live in separate plain locals.
 *
 * PROVENANCE. The mark is rendered by rule!SO_snowflakeMark and by nothing else
 * on this screen. It marks Snowflake INTELLIGENCE only — the model's predicted
 * reason and fail probability, the value-at-risk aggregate, the scoring batch
 * itself, and the "cleared by Snowflake scoring" disposition. Trade id,
 * counterparty and notional are Snowflake-RESIDENT and carry no mark.
 *
 * THE TWO VERBS IN THE CLEARED QUEUE STAY DISTINCT, AND THAT IS THE POINT OF
 * THE QUEUE. "Cleared by Snowflake scoring · no case needed" means the model
 * scored the trade below the case threshold and NOTHING ELSE HAPPENED — no
 * case, no agent, no analyst. "Agent resolved · score N" means a case existed
 * and the agent closed it straight through. Rendering scored-clear trades as
 * agent activity would inflate the agent's apparent work by the whole
 * background packet, which is the opposite of the governance argument.
 */
a!localVariables(
  /* The five open statuses. isOpen in SO_statusDisplay is the same definition;
     this list exists because a query filter needs literals, not a rule call. */
  local!openStatuses: {"New", "Agent Triage", "Pending Analyst", "In Remediation", "Escalated"},
  /* NEEDS YOUR ACTION is this set MINUS Escalated, expressed as the isEscalated
     partition below rather than as a second literal list, so the two queues
     cannot drift apart or double-count a status. */
  local!resolvedStatuses: {"Resolved - Straight Through", "Resolved - Analyst"},
  /* How many rows NEEDS YOUR ACTION shows before the view-all footer. The
     mockup shows four nearest cutoffs of twelve; this is that number. */
  local!nearest: 4,

  local!caseRows: a!refreshVariable(
    value: a!queryRecordType(
      recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
      fields: {
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt'
      },
      filters: a!queryFilter(
        field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
        operator: "in",
        value: local!openStatuses
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 500,
        sort: a!sortInfo(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs', ascending: true)
      )
    ).data,
    refreshInterval: 0.5,
    refreshAlways: true
  ),

  local!lastRead: a!refreshVariable(
    value: now(),
    refreshOnVarChange: local!caseRows,
    refreshInterval: 0.5
  ),

  /* THE BATCH. Anchored on SO Trade so desk security applies (header note), and
     filtered on the reserved TRD9 packet range — the same predicate the demo
     console uses to count demo trades. A run that is loaded is in this range by
     construction; a baseline trade never is (every baseline id is TRD0*). */
  local!batchTrades: a!refreshVariable(
    value: a!queryRecordType(
      recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade',
      fields: {
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier',
        'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt'
      },
      filters: a!queryFilter(
        field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId',
        operator: "starts with",
        value: "TRD9"
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 100,
        sort: a!sortInfo(field: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId', ascending: true)
      )
    ).data,
    refreshInterval: 0.5,
    refreshAlways: true
  ),

  /* The batch's RESOLVED cases. Scoped by trade id rather than by a date, so it
     cannot include a standing resolved case and cannot miss a batch case that
     resolved either side of midnight. */
  local!batchResolved: a!refreshVariable(
    value: a!queryRecordType(
      recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
      fields: {
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation',
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn'
      },
      filters: {
        a!queryFilter(
          field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
          operator: "starts with",
          value: "TRD9"
        ),
        a!queryFilter(
          field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
          operator: "in",
          value: local!resolvedStatuses
        )
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100)
    ).data,
    refreshInterval: 0.5,
    refreshAlways: true
  ),

  /* ---------------------------------------------------------------------------
     ENRICHMENT. One map per case carrying everything the queues, the KPIs and
     the preview rail need, so each display rule runs ONCE per row rather than
     once per consumer. Record rows are NOT keyed by plain field name —
     index(row, "tradeId", ...) silently returns the default (MEASURED) — so
     every read below is a fully qualified bracket reference.
     --------------------------------------------------------------------------- */
  local!rows: a!forEach(
    items: local!caseRows,
    expression: a!localVariables(
      local!ac: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass'],
      local!prob: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability'],
      local!cutoff: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs'],
      local!tid: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID'],
      local!status: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status'],
      local!reason: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason'],
      local!remed: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation'],
      local!scored: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt'],
      local!co: rule!SO_cutoffDisplay(cutoffTs: local!cutoff),
      local!st: rule!SO_statusDisplay(status: local!status),
      local!fr: rule!SO_failReasonDisplay(failReason: local!reason, short: false),
      local!qty: rule!SO_quantityDisplay(quantity: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity'], assetClass: local!ac),
      local!pri: rule!SO_casePriority(failProbability: local!prob, cutoffTs: local!cutoff),
      local!band: rule!SO_priorityBand(priority: local!pri),
      /* status goes in because the LANE is a stored decision, not a
         re-derivation from the score: a counterparty-default case can score
         high and still be escalated by reason override. */
      local!ar: rule!SO_autoReleaseDisplay(confidenceScore: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore'], status: local!status),
      local!lag: todecimal(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs']),
      local!hrsLeft: index(local!co, "hoursRemaining", null),
      local!isPast: index(local!co, "isPast", false),
      local!hasScore: index(local!ar, "hasScore", false),
      local!score: index(local!ar, "score", 0),
      local!gate: index(local!ar, "gate", 80),
      /* THE BATCH TAG. A row belongs to the loaded packet if its trade sits in
         the reserved TRD9 range — the same test the batch query uses, so the
         tag and the band can never disagree about which rows are new. The tag
         shows the SCORING stamp, not the case's own creation time: the batch is
         a scoring event, and the case is its consequence. */
      local!isBatch: and(not(a!isNullOrEmpty(local!tid)), left(local!tid, 4) = "TRD9"),
      /* The agent cell. Three shapes, keyed to what the record actually holds:
         a score with the case still in the analyst's hands (HELD), a
         remediation already in flight (PROPOSED), or a case triage has not
         reached yet (no score at all). */
      local!agentShape: if(
        not(local!hasScore),
        "UNSCORED",
        if(local!status = "In Remediation", "PROPOSED", "HELD")
      ),
      a!map(
        caseId: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'],
        caseRef: "SO-" & fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'],
        tradeId: local!tid,
        desk: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk'],
        direction: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'],
        sideLabel: if(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'] = "BUY", "B", "S"),
        sideColor: if(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'] = "BUY", "#17715B", "#4A5462"),
        ticker: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker'],
        instrumentName: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name'],
        assetClass: local!ac,
        counterparty: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name'],
        /* COUNTERPARTIES.RISK_TIER is stored lower-case while
           TRADE_PREDICTIONS.RISK_TIER is capitalised (MEASURED). One mapping
           rule, so one screen never shows both casings. */
        cptyRiskTier: rule!SO_riskTierDisplay(riskTier: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier']),
        cptyFailRate: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate'],
        notional: todecimal(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional']),
        currency: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency'],
        valueDisplay: rule!SO_fmtMoney(amount: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional'], currency: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency'], compact: true),
        valueFull: rule!SO_fmtMoney(amount: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional'], currency: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency'], compact: false),
        quantityDisplay: index(local!qty, "display", ""),
        hasQuantity: index(local!qty, "hasQuantity", false),
        /* Probability as a percentage, never the stored 0-1 decimal. */
        probPct: if(a!isNullOrEmpty(local!prob), null, tointeger(round(100 * local!prob, 0))),
        probDisplay: if(a!isNullOrEmpty(local!prob), "—", tointeger(round(100 * local!prob, 0)) & "%"),
        riskTier: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier'],
        tierColor: a!match(
          value: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier'],
          equals: "Critical", then: "#B3261E",
          equals: "High", then: "#96590A",
          default: "#4A5462"
        ),
        scoredAt: local!scored,
        isBatch: local!isBatch,
        batchTag: if(or(not(local!isBatch), a!isNullOrEmpty(local!scored)), "", text(local!scored, "hh:mm")),
        failReason: local!reason,
        failReasonLabel: index(local!fr, "label", ""),
        failReasonNote: index(local!fr, "note", ""),
        remediation: local!remed,
        status: local!status,
        statusLabel: index(local!st, "label", ""),
        statusColor: index(local!st, "color", "#454F5C"),
        isEscalated: local!status = "Escalated",
        settles: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate'],
        cutoffTs: local!cutoff,
        countdown: index(local!co, "countdown", ""),
        cutoffAt: index(local!co, "atText", ""),
        cutoffSeverity: index(local!co, "severity", "NONE"),
        cutoffColor: index(local!co, "color", "#1B2330"),
        hoursRemaining: local!hrsLeft,
        inWindow: index(local!co, "insideCriticalWindow", false),
        /* isPast is carried, not re-derived downstream: the rail branches on it
           to keep a NEGATIVE number away from text(), which mangles the sign. */
        isPast: local!isPast,
        hasCutoff: index(local!co, "hasCutoff", false),
        /* 99999 keeps a null cutoff at the BOTTOM of a cutoff-ascending sort
           instead of the top, where a null would read as most urgent. */
        cutoffSortKey: a!defaultValue(local!hrsLeft, 99999),
        priority: local!pri,
        priorityLabel: index(local!band, "label", ""),
        priorityColor: index(local!band, "color", "#4A5462"),
        lagHrs: local!lag,
        lagFits: if(or(a!isNullOrEmpty(local!lag), a!isNullOrEmpty(local!hrsLeft)), null, local!lag < local!hrsLeft),
        lagSlackHrs: if(or(a!isNullOrEmpty(local!lag), a!isNullOrEmpty(local!hrsLeft)), null, local!hrsLeft - local!lag),
        confidenceScore: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore'],
        arLine: index(local!ar, "line", ""),
        arPill: index(local!ar, "pill", ""),
        arPillColor: index(local!ar, "pillColor", "#6E7885"),
        arScore: local!score,
        arGate: local!gate,
        arHasScore: local!hasScore,
        arCleared: index(local!ar, "cleared", false),
        lane: index(local!ar, "lane", "UNSCORED"),
        arLaneNote: index(local!ar, "laneNote", ""),
        /* AGENT COLUMN (needs-action queue). Score on the 0-100 scale per the
           display canon — "confidence" is governance vocabulary and the stored
           decimal never reaches an analyst screen. */
        agentLine: a!match(
          value: local!agentShape,
          equals: "HELD", then: "Held · " & local!score,
          equals: "PROPOSED", then: "Proposed",
          default: "Not yet scored"
        ),
        agentSub: a!match(
          value: local!agentShape,
          equals: "HELD", then: if(index(local!ar, "cleared", false), "at or above the " & local!gate & " release gate", "below the " & local!gate & " release gate"),
          equals: "PROPOSED", then: a!defaultValue(local!remed, ""),
          default: "awaiting triage"
        ),
        agentColor: a!match(
          value: local!agentShape,
          equals: "HELD", then: "#96590A",
          equals: "PROPOSED", then: "#1B2330",
          default: "#6E7885"
        ),
        /* ESCALATION COLUMN (escalated queue). The CONDITION that holds, never
           an actor: "By policy" would name an attributor this screen cannot
           read, since the escalating event's text lives in the audit trail and
           reading it per row would be a query per grid row. Both branches below
           are checked against the same two inputs the escalation policy itself
           uses (CLAUDE.md, escalation policy), so the line is an explanation of
           the stored Escalated status, not a re-decision of it. */
        escLine: if(
          a!defaultValue(local!reason, "") = "counterparty_default",
          "Reason override",
          if(
            and(not(a!isNullOrEmpty(local!lag)), local!lag > 0, not(a!isNullOrEmpty(local!hrsLeft)), local!lag >= local!hrsLeft),
            "Window breached",
            "Agent escalated"
          )
        ),
        escSub: if(
          a!defaultValue(local!reason, "") = "counterparty_default",
          "counterparty default — credit decision required",
          if(
            and(not(a!isNullOrEmpty(local!lag)), local!lag > 0, not(a!isNullOrEmpty(local!hrsLeft)), local!lag >= local!hrsLeft),
            "confirm lag " & text(local!lag, "0.0") & "h · " & if(local!isPast, "past cutoff", text(local!hrsLeft, "0.0") & "h to cutoff"),
            if(local!hasScore, "score " & local!score & " · referred to supervisor", "referred to supervisor")
          )
        ),
        /* Assign is offered only where assigning is a real move. */
        canAssign: not(or(
          local!status = "Escalated",
          local!status = "Resolved - Straight Through",
          local!status = "Resolved - Analyst"
        )),
        /* SETTLES IS THE CUTOFF'S OWN CALENDAR DATE, not the trade's stored
           expectedSettlementDate: the cutoff IS the settlement-date cutoff, so
           deriving it here makes the two incapable of contradicting each other.
           text() renders LOCAL while date-part functions return UTC, so the
           calendar date is rebuilt from the LOCAL rendering. */
        settlesDisplay: if(
          a!isNullOrEmpty(local!cutoff),
          "—",
          rule!SO_fmtDayDate(value: date(
            tointeger(text(local!cutoff, "yyyy")),
            tointeger(text(local!cutoff, "mm")),
            tointeger(text(local!cutoff, "dd"))
          ))
        ),
        assignee: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee'],
        ownerLabel: if(
          a!isNullOrEmpty(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee']),
          "Unassigned",
          user(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee'], "firstName") & " " & user(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee'], "lastName")
        ),
        ownerIsMe: fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee'] = loggedInUser(),
        ownerUnassigned: a!isNullOrEmpty(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee'])
      )
    )
  ),

  /* ---------------------------------------------------------------------------
     THE BATCH, CLASSIFIED. Every packet trade on this desk lands in exactly one
     bucket, so the band's chips sum to the batch's trade count by construction.
     A trade with no case and a tier below the High floor is the scored-clear
     case — Snowflake decided nothing needed opening. A trade with no case and a
     tier AT or above the floor is intake in flight (or intake failed), and it
     gets its own chip rather than being quietly absorbed into another.
     --------------------------------------------------------------------------- */
  local!batch: a!forEach(
    items: local!batchTrades,
    expression: a!localVariables(
      local!tid: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId'],
      local!tier: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier'],
      local!prob: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability'],
      local!scored: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt'],
      local!ac: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass'],
      /* The open case for this trade, if any — read from the SAME assembled row
         set the queues render, so a trade and its queue row cannot disagree. */
      local!openMatch: index(
        a!flatten(a!forEach(items: local!rows, expression: if(index(fv!item, "tradeId", "") = local!tid, { fv!item }, {}))),
        1, null
      ),
      local!resMatch: index(
        a!flatten(a!forEach(
          items: local!batchResolved,
          expression: if(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID'] = local!tid, { fv!item }, {})
        )),
        1, null
      ),
      local!caseStatus: if(
        not(a!isNullOrEmpty(local!openMatch)),
        index(local!openMatch, "status", ""),
        if(a!isNullOrEmpty(local!resMatch), "", local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status'])
      ),
      local!resScore: if(
        a!isNullOrEmpty(local!resMatch),
        null,
        local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore']
      ),
      local!klass: if(
        local!caseStatus = "",
        if(or(local!tier = "High", local!tier = "Critical"), "UNCASED", "SCORED_CLEAR"),
        a!match(
          value: local!caseStatus,
          equals: "Resolved - Straight Through", then: "AGENT",
          equals: "Resolved - Analyst", then: "ANALYST",
          equals: "Escalated", then: "ESCALATED",
          default: "NEEDS"
        )
      ),
      local!qty: rule!SO_quantityDisplay(quantity: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity'], assetClass: local!ac),
      a!map(
        tradeId: local!tid,
        klass: local!klass,
        direction: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'],
        sideLabel: if(fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'] = "BUY", "B", "S"),
        sideColor: if(fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction'] = "BUY", "#17715B", "#4A5462"),
        ticker: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker'],
        quantityDisplay: index(local!qty, "display", ""),
        counterparty: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name'],
        valueDisplay: rule!SO_fmtMoney(amount: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional'], currency: fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency'], compact: true),
        riskTier: local!tier,
        tierColor: a!match(value: local!tier, equals: "Critical", then: "#B3261E", equals: "High", then: "#96590A", default: "#4A5462"),
        /* Numeric sort keys beside their formatted twins: a column that sorts
           on "634,800 EUR" or "18%" sorts lexically, which is a silently wrong
           order rather than an error. */
        notional: todecimal(fv!item['recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional']),
        probPct: if(a!isNullOrEmpty(local!prob), null, tointeger(round(100 * local!prob, 0))),
        probDisplay: if(a!isNullOrEmpty(local!prob), "—", tointeger(round(100 * local!prob, 0)) & "%"),
        scoredAt: local!scored,
        scoredSortKey: if(a!isNullOrEmpty(local!scored), "", text(local!scored, "yyyymmddhhmmss")),
        timeDisplay: a!match(
          value: local!klass,
          equals: "AGENT", then: if(
            or(a!isNullOrEmpty(local!resMatch), a!isNullOrEmpty(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn'])),
            "",
            text(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn'], "hh:mm")
          ),
          equals: "ANALYST", then: if(
            or(a!isNullOrEmpty(local!resMatch), a!isNullOrEmpty(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn'])),
            "",
            text(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn'], "hh:mm")
          ),
          default: if(a!isNullOrEmpty(local!scored), "", text(local!scored, "hh:mm"))
        ),
        /* THE TWO VERBS. Never interchangeable: one is the model declining to
           open a case, the other is the agent closing one it was given. */
        dispLine: a!match(
          value: local!klass,
          equals: "AGENT", then: "Agent resolved · score " & tointeger(round(100 * a!defaultValue(todecimal(local!resScore), 0), 0)),
          equals: "ANALYST", then: "Analyst resolved",
          default: "Cleared by Snowflake scoring"
        ),
        dispSub: a!match(
          value: local!klass,
          /* The disposition is a stored CODE from the canon and is rendered
             exactly as stored. Lower-casing it to read as a sub-clause would be
             a casing trick standing in for a mapping, which is the one thing
             the display-vocabulary rule forbids. */
          equals: "AGENT", then: if(
            a!isNullOrEmpty(local!resMatch),
            "",
            a!defaultValue(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition'], "")
          ),
          equals: "ANALYST", then: if(
            a!isNullOrEmpty(local!resMatch),
            "",
            a!defaultValue(local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition'], "")
          ),
          default: "no case needed"
        ),
        dispColor: a!match(value: local!klass, equals: "AGENT", then: "#17715B", equals: "ANALYST", then: "#454F5C", default: "#3E7396"),
        isSnowCleared: local!klass = "SCORED_CLEAR",
        clearedCaseId: if(a!isNullOrEmpty(local!resMatch), null, local!resMatch['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'])
      )
    )
  ),

  /* ---------------------------------------------------------------------------
     THE THREE QUEUE POPULATIONS. Queues 1 and 2 PARTITION the open case set, so
     their counts sum to the open-fails KPI by construction. Queue 3 is the
     batch's cleared trades and belongs to a different universe entirely — it
     counts TRADES, not cases, which is why it never joins that sum.
     --------------------------------------------------------------------------- */
  local!needsAll: todatasubset(
    a!flatten(a!forEach(items: local!rows, expression: if(index(fv!item, "isEscalated", false), {}, { fv!item }))),
    a!pagingInfo(startIndex: 1, batchSize: 500, sort: a!sortInfo(field: "cutoffSortKey", ascending: true))
  ).data,
  local!escalated: todatasubset(
    a!flatten(a!forEach(items: local!rows, expression: if(index(fv!item, "isEscalated", false), { fv!item }, {}))),
    a!pagingInfo(startIndex: 1, batchSize: 500, sort: a!sortInfo(field: "cutoffSortKey", ascending: true))
  ).data,
  local!cleared: todatasubset(
    a!flatten(a!forEach(
      items: local!batch,
      expression: if(
        or(index(fv!item, "klass", "") = "SCORED_CLEAR", index(fv!item, "klass", "") = "AGENT", index(fv!item, "klass", "") = "ANALYST"),
        { fv!item },
        {}
      )
    )),
    /* Agent and analyst outcomes first — they are the ones a reader opens this
       section to find — then the scored-clear run in trade-id order. */
    a!pagingInfo(startIndex: 1, batchSize: 500, sort: { a!sortInfo(field: "isSnowCleared", ascending: true), a!sortInfo(field: "tradeId", ascending: true) })
  ).data,

  local!needsCount: count(local!needsAll),
  local!escalatedCount: count(local!escalated),
  local!batchCount: count(local!batch),
  local!hasBatch: local!batchCount > 0,
  local!snowClearedCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "SCORED_CLEAR", 1, 0))), 0),
  local!agentResolvedCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "AGENT", 1, 0))), 0),
  local!analystResolvedCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "ANALYST", 1, 0))), 0),
  local!batchNeedsCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "NEEDS", 1, 0))), 0),
  local!batchEscalatedCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "ESCALATED", 1, 0))), 0),
  local!uncasedCount: a!defaultValue(sum(a!forEach(items: local!batch, expression: if(index(fv!item, "klass", "") = "UNCASED", 1, 0))), 0),
  /* No analyst touched these: the model declined to open a case, or the agent
     closed one without referral. An analyst-resolved case is NOT in this number
     — that is the whole point of stating the split honestly. */
  local!noTouchCount: local!snowClearedCount + local!agentResolvedCount,
  /* THE BATCH STAMP. Taken from the batch's own latest scoring time by sorting
     the assembled rows, never by max() over a date list — min()/max() over
     Dates return a Decimal (MEASURED), which then cannot be rendered as a time. */
  local!batchStamp: if(
    local!hasBatch,
    index(
      index(
        todatasubset(local!batch, a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: "scoredSortKey", ascending: false))).data,
        1, null
      ),
      "scoredAt", null
    ),
    null
  ),

  /* ---------------------------------------------------------------------------
     KPIs. The first three read the SAME assembled open-case set the queues
     render. The fourth is BATCH-scoped by the prompt's definition — the latest
     batch's no-analyst-touch outcomes — so with no batch loaded it says so
     rather than reporting a number from a different question.
     --------------------------------------------------------------------------- */
  local!openCount: count(local!rows),
  local!varTotal: a!defaultValue(sum(a!forEach(items: local!rows, expression: a!defaultValue(index(fv!item, "notional", 0), 0))), 0),
  local!inWindowCount: a!defaultValue(sum(a!forEach(items: local!rows, expression: if(index(fv!item, "inWindow", false), 1, 0))), 0),
  local!inWindowValue: a!defaultValue(
    sum(a!forEach(items: local!rows, expression: if(index(fv!item, "inWindow", false), a!defaultValue(index(fv!item, "notional", 0), 0), 0))),
    0
  ),

  /* ---------------------------------------------------------------------------
     VIEW STATE. Plain locals, not refresh variables — a variable carrying
     refreshInterval cannot be a save target.
     --------------------------------------------------------------------------- */
  local!selectedCaseId,
  local!showAllNeeds: false,

  local!needsVisible: if(
    or(local!showAllNeeds, local!needsCount <= local!nearest),
    local!needsAll,
    todatasubset(local!needsAll, a!pagingInfo(startIndex: 1, batchSize: local!nearest)).data
  ),

  /* The row index of the selected case within the CURRENTLY VISIBLE needs-action
     list. selectionValue on a locally-sourced grid is a ROW INDEX (MEASURED);
     deriving it from the stable case id each render keeps the highlight correct
     when the view-all toggle changes the list length. */
  local!selectedIndex: if(
    a!isNullOrEmpty(local!selectedCaseId),
    null,
    index(
      a!flatten(a!forEach(items: local!needsVisible, expression: if(index(fv!item, "caseId", -1) = local!selectedCaseId, { fv!index }, {}))),
      1, null
    )
  ),

  /* The rail follows the selection. It is resolved from the WHOLE open row set,
     not from the visible page, so collapsing the view-all toggle never blanks a
     rail that is already showing a case. */
  local!selected: if(
    a!isNullOrEmpty(local!selectedCaseId),
    null,
    index(
      a!flatten(a!forEach(items: local!rows, expression: if(index(fv!item, "caseId", -1) = local!selectedCaseId, { fv!item }, {}))),
      1, null
    )
  ),

  /* The selected case's stored agent assessment. Written by the triage lane as
     an SO Case Comment; the most recent one is the assessment for this case. */
  local!assessment: if(
    a!isNullOrEmpty(local!selectedCaseId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment',
        fields: { 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{2bb72559-6a2b-4624-b156-efc8237287ce}commentText', 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn' },
        filters: a!queryFilter(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId', operator: "=", value: local!selectedCaseId),
        pagingInfo: a!pagingInfo(
          startIndex: 1, batchSize: 1,
          sort: a!sortInfo(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn', ascending: false)
        )
      ).data,
      1, null
    )
  ),

  /* ===================== TOP-LEVEL LAYOUT =====================
     a!formLayout, NOT a!headerContentLayout: the latter has NO width parameter
     at all (MEASURED), so an interface built on it renders as a centred
     fixed-width band. contentsWidth "FULL" renders as formWidth "FULL".
     validateExpression ACCEPTS contentsWidth on a!headerContentLayout with no
     errors; only the object validator rejects it. */
  a!formLayout(
    backgroundColor: "#F3F5F8",
    contentsWidth: "FULL",
    focusOnFirstInput: false,
    contents: {
      /* ===================== PAGE HEAD ===================== */
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "Pre-Settlement Watchlist", size: "MEDIUM_PLUS", style: "STRONG", color: "#1B2330"),
          a!richTextItem(text: "    Settlement cycle " & rule!SO_fmtDayDate(value: today()) & " · T+1", size: "STANDARD", color: "#454F5C")
        }
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        tooltip: "Predictions are computed in Snowflake and read live; nothing is copied or synced.",
        value: {
          rule!SO_snowflakeMark(showWhen: true),
          a!richTextItem(text: " Predictions live from Snowflake", color: "#3E7396", size: "SMALL", style: "STRONG"),
          a!richTextItem(text: "  ·  last read " & text(local!lastRead, "hh:mm:ss") & "  ·  refreshes every 30s", color: "#6E7885", size: "SMALL")
        }
      ),

      /* ===================== KPI BAND ===================== */
      /* cardGroupLayout, not columnsLayout-of-cards: its cardHeight AUTO levels
         every card to the TALLEST, where cardLayout height AUTO would size each
         card to its own contents and leave the row ragged. */
      a!cardGroupLayout(
        cardWidth: "NARROW",
        cardHeight: "AUTO",
        fillContainer: true,
        marginBelow: "STANDARD",
        cards: {
          rule!SO_kpiCard(
            label: "Predicted fails — open",
            value: local!openCount,
            valueColor: "#1B2330",
            unit: "",
            sub: local!needsCount & " need action · " & local!escalatedCount & " escalated",
            accentColor: "#9AA6B3",
            snowMarked: false
          ),
          rule!SO_kpiCard(
            label: "Value at risk",
            value: rule!SO_fmtMoney(amount: local!varTotal, currency: "", compact: true),
            valueColor: "#1B2330",
            unit: "USD eq.",
            sub: "across " & local!openCount & " open item" & if(local!openCount = 1, "", "s"),
            accentColor: "#3E7396",
            snowMarked: true
          ),
          rule!SO_kpiCard(
            label: "Inside critical window",
            value: local!inWindowCount,
            valueColor: if(local!inWindowCount > 0, "#B3261E", "#1B2330"),
            unit: "",
            sub: "cutoff within 4h · " & rule!SO_fmtMoney(amount: local!inWindowValue, currency: "", compact: true) & " USD eq.",
            accentColor: "#B3261E",
            snowMarked: false
          ),
          rule!SO_kpiCard(
            label: "Straight-through today",
            value: if(local!hasBatch, local!noTouchCount, "—"),
            valueColor: if(local!hasBatch, "#17715B", "#6E7885"),
            unit: "",
            sub: if(
              local!hasBatch,
              local!noTouchCount & " of " & local!batchCount & " in latest batch · no analyst touch",
              "no scoring batch on your desk"
            ),
            accentColor: "#17715B",
            snowMarked: false
          )
        }
      ),

      /* ===================== LATEST SCORING BATCH BAND =====================
         ONE BAND, TIMESTAMPED, NOT THE FRAME OF THE PAGE. It states what the
         most recent scoring run did on this desk and then gets out of the way;
         the queues below are the work.

         THE NO-RUN STATE IS TO HIDE, AND THAT IS A DELIBERATE READING OF THE
         TWO OPTIONS THE BRIEF ALLOWED. Every value in this band is a fact about
         a batch — a stamp, a trade count, four dispositions — so with no batch
         loaded the honest rendering is silence, not a row of zeroes. The
         alternative, "collapse to whatever the latest scoring state truthfully
         is", would mean reporting the newest scoredAt across the 50,000
         baseline predictions: real, but not a batch, and an absurd thing to put
         under the words "latest scoring batch". local!hasBatch governs this
         band, the cleared queue and the straight-through KPI together, so the
         three can never disagree about whether a batch exists. */
      a!cardLayout(
        showWhen: local!hasBatch,
        padding: "LESS",
        style: "#EFF5F9",
        showBorder: true,
        shape: "SEMI_ROUNDED",
        marginBelow: "STANDARD",
        contents: a!sideBySideLayout(
          alignVertical: "MIDDLE",
          items: {
            a!sideBySideItem(
              width: "MINIMIZE",
              item: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                preventWrapping: true,
                tooltip: "Scored in Snowflake on arrival, not overnight — the packet is scored as it lands.",
                value: {
                  rule!SO_snowflakeMark(showWhen: true),
                  a!richTextItem(text: "  Latest scoring batch", style: "STRONG", color: "#1B2330", size: "STANDARD"),
                  a!richTextItem(
                    text: "  " & if(a!isNullOrEmpty(local!batchStamp), "time not recorded", text(local!batchStamp, "hh:mm")) & " today  ·  " & local!batchCount & " trade" & if(local!batchCount = 1, "", "s") & " on your desk",
                    color: "#4A5462",
                    size: "SMALL"
                  )
                }
              )
            ),
            a!sideBySideItem(
              item: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                align: "RIGHT",
                value: {
                  a!richTextItem(text: local!snowClearedCount & " cleared by Snowflake", color: "#17715B", style: "STRONG", size: "SMALL"),
                  a!richTextItem(text: "   " & local!agentResolvedCount & " agent-resolved", color: "#17715B", style: "STRONG", size: "SMALL"),
                  a!richTextItem(text: "   " & local!analystResolvedCount & " analyst-resolved", color: "#17715B", style: "STRONG", size: "SMALL", showWhen: local!analystResolvedCount > 0),
                  a!richTextItem(text: "   " & local!batchNeedsCount & " need" & if(local!batchNeedsCount = 1, "s", "") & " review", color: "#B3261E", style: "STRONG", size: "SMALL"),
                  a!richTextItem(text: "   " & local!batchEscalatedCount & " escalated", color: "#96590A", style: "STRONG", size: "SMALL"),
                  /* Only ever non-zero while intake is still running, or if it
                     failed. Silent otherwise, and impossible to miss when it is
                     not — the chips always sum to the trade count. */
                  a!richTextItem(text: "   " & local!uncasedCount & " awaiting intake", color: "#B3261E", style: "STRONG", size: "SMALL", showWhen: local!uncasedCount > 0)
                }
              )
            )
          }
        )
      ),

      /* ===================== WORKBENCH ===================== */
      a!columnsLayout(
        alignVertical: "TOP",
        columns: {
          a!columnLayout(
            width: "AUTO",
            contents: {

              /* ---------- QUEUE 1: NEEDS YOUR ACTION ---------- */
              a!cardLayout(
                padding: "NONE",
                showBorder: true,
                style: "NONE",
                shape: "SEMI_ROUNDED",
                marginBelow: "STANDARD",
                contents: {
                  a!cardLayout(
                    padding: "LESS",
                    style: "#FAFBFC",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextIcon(icon: "circle", color: "#B3261E", size: "SMALL"),
                        a!richTextItem(text: "  NEEDS YOUR ACTION ", style: "STRONG", size: "SMALL", color: "#454F5C"),
                        a!richTextItem(text: "(" & local!needsCount & ")", style: "STRONG", size: "SMALL", color: "#6E7885"),
                        a!richTextItem(text: "  ·  sorted by time to cutoff", size: "SMALL", color: "#6E7885")
                      }
                    )
                  ),
                  /* PROVENANCE LEGEND. The mark belongs on the two model-output
                     columns, but a!gridColumn's label is a TEXT parameter: a
                     component placed there renders as its serialized object
                     graph (MEASURED). Repeating the image per cell would imply
                     the VALUE is Snowflake intelligence rather than the COLUMN.
                     So the mark appears once here and names its columns, and
                     both headers keep a helpTooltip saying so on hover. */
                  a!cardLayout(
                    padding: "EVEN_LESS",
                    style: "NONE",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      tooltip: "Fail reason and fail risk are model output, computed in Snowflake and read live.",
                      value: {
                        rule!SO_snowflakeMark(showWhen: true),
                        a!richTextItem(text: "  Fail reason", color: "#3E7396", size: "SMALL", style: "STRONG"),
                        a!richTextItem(text: " and ", color: "#6E7885", size: "SMALL"),
                        a!richTextItem(text: "Fail risk", color: "#3E7396", size: "SMALL", style: "STRONG"),
                        a!richTextItem(text: " are model output — computed in Snowflake, read live, never copied here.", color: "#6E7885", size: "SMALL")
                      }
                    )
                  ),
                  a!gridField(
                    labelPosition: "COLLAPSED",
                    data: local!needsVisible,
                    emptyGridMessage: "Nothing needs your action. The scoring batch has raised nothing on your book — or the feed has not arrived yet.",
                    pageSize: 50,
                    spacing: "DENSE",
                    borderStyle: "LIGHT",
                    selectable: true,
                    maxSelections: 1,
                    /* SUBTLE_HIGHLIGHT, not ROW_HIGHLIGHT: the solid fill made
                       every semantic colour in the row unreadable at once — the
                       red countdown, the amber agent cell, the status colours.
                       The row's meaning is carried by those colours. */
                    selectionStyle: "SUBTLE_HIGHLIGHT",
                    selectionValue: local!selectedIndex,
                    selectionSaveInto: a!save(
                      local!selectedCaseId,
                      if(
                        a!isNullOrEmpty(save!value),
                        null,
                        index(index(local!needsVisible, index(save!value, 1, 0), null), "caseId", null)
                      )
                    ),
                    columns: {
                      a!gridColumn(
                        label: "Trade",
                        width: "NARROW_PLUS",
                        sortField: "tradeId",
                        /* A LINK COMPONENT MUST NEVER SIT IN A TEXT CONTEXT.
                           a!gridColumn's value is Text-typed, so a bare
                           a!recordLink VALIDATES CLEAN and renders its
                           serialized object graph in the cell (MEASURED twice).
                           The working form is always a rich text component
                           carrying the link in a!richTextItem(link: ...). */
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(
                              text: index(fv!row, "tradeId", ""),
                              style: "STRONG",
                              link: a!recordLink(
                                recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
                                identifier: index(fv!row, "caseId", null)
                              )
                            ),
                            a!richTextItem(
                              text: "  " & index(fv!row, "batchTag", ""),
                              color: "#3E7396",
                              size: "SMALL",
                              style: "STRONG",
                              showWhen: index(fv!row, "batchTag", "") <> ""
                            )
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Instrument",
                        width: "AUTO",
                        sortField: "ticker",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "sideLabel", ""), color: index(fv!row, "sideColor", "#4A5462"), style: "STRONG", size: "SMALL"),
                            a!richTextItem(text: "  " & index(fv!row, "ticker", ""), style: "STRONG"),
                            a!richTextItem(text: "  " & index(fv!row, "instrumentName", ""), color: "#454F5C", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Counterparty",
                        width: "NARROW_PLUS",
                        sortField: "counterparty",
                        value: index(fv!row, "counterparty", "")
                      ),
                      a!gridColumn(
                        label: "Value",
                        width: "NARROW",
                        align: "END",
                        sortField: "notional",
                        value: index(fv!row, "valueDisplay", "")
                      ),
                      a!gridColumn(
                        label: "Fail risk",
                        width: "NARROW",
                        align: "END",
                        sortField: "probPct",
                        helpTooltip: "Live from Snowflake — the model's fail probability and risk tier for this trade.",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          align: "RIGHT",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(text: index(fv!row, "probDisplay", "—"), color: index(fv!row, "tierColor", "#4A5462"), style: "STRONG"),
                            char(10),
                            a!richTextItem(text: index(fv!row, "riskTier", ""), color: index(fv!row, "tierColor", "#4A5462"), size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Agent",
                        width: "NARROW_PLUS",
                        sortField: "agentLine",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "agentLine", ""), color: index(fv!row, "agentColor", "#454F5C"), style: "STRONG", size: "SMALL"),
                            char(10),
                            a!richTextItem(text: index(fv!row, "agentSub", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Cutoff",
                        width: "NARROW",
                        sortField: "cutoffSortKey",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(text: index(fv!row, "countdown", ""), color: index(fv!row, "cutoffColor", "#1B2330"), style: "STRONG"),
                            char(10),
                            a!richTextItem(text: index(fv!row, "cutoffAt", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Status",
                        width: "NARROW",
                        sortField: "statusLabel",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "statusLabel", ""), color: index(fv!row, "statusColor", "#454F5C"), style: "STRONG", size: "SMALL"),
                            char(10),
                            a!richTextItem(text: index(fv!row, "ownerLabel", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      )
                    }
                  ),
                  /* THE FOOTER IS THE PAGER. A grid pageSize of four would page
                     the whole queue four rows at a time; what the queue wants is
                     a short default view of the nearest cutoffs with everything
                     one click away, which is a toggle over the assembled list,
                     not a page control. Hidden entirely when everything fits. */
                  a!cardLayout(
                    showWhen: local!needsCount > local!nearest,
                    padding: "LESS",
                    style: "#FAFBFC",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextItem(
                          text: if(local!showAllNeeds, "showing all " & local!needsCount, "showing " & local!nearest & " nearest cutoffs"),
                          color: "#4A5462",
                          size: "SMALL"
                        ),
                        a!richTextItem(text: "     ", size: "SMALL"),
                        a!richTextItem(
                          text: if(local!showAllNeeds, "Show nearest " & local!nearest, "View all " & local!needsCount),
                          style: "STRONG",
                          size: "SMALL",
                          link: a!dynamicLink(
                            value: not(local!showAllNeeds),
                            saveInto: local!showAllNeeds
                          )
                        )
                      }
                    )
                  )
                }
              ),

              /* ---------- QUEUE 2: ESCALATED — WITH SUPERVISOR ----------
                 MUTED, AND WITH NO ACTION AFFORDANCES, BECAUSE THE WORK IS NOT
                 THE ANALYST'S. These cases left their book for a supervisor's
                 credit decision; the queue exists so the analyst can see where
                 they went, not so anything can be done to them here. The rows
                 are therefore not selectable — selecting one would open a rail
                 whose whole purpose is deciding a case this analyst may not
                 decide. */
              a!cardLayout(
                showWhen: local!escalatedCount > 0,
                padding: "NONE",
                showBorder: true,
                style: "NONE",
                shape: "SEMI_ROUNDED",
                marginBelow: "STANDARD",
                contents: {
                  a!cardLayout(
                    padding: "LESS",
                    style: "#FAFBFC",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextIcon(icon: "circle", color: "#96590A", size: "SMALL"),
                        a!richTextItem(text: "  ESCALATED — WITH SUPERVISOR ", style: "STRONG", size: "SMALL", color: "#454F5C"),
                        a!richTextItem(text: "(" & local!escalatedCount & ")", style: "STRONG", size: "SMALL", color: "#6E7885"),
                        a!richTextItem(text: "  ·  raised from your book, no action needed", size: "SMALL", color: "#6E7885")
                      }
                    )
                  ),
                  a!gridField(
                    labelPosition: "COLLAPSED",
                    data: local!escalated,
                    emptyGridMessage: "Nothing escalated.",
                    pageSize: 25,
                    spacing: "DENSE",
                    borderStyle: "LIGHT",
                    selectable: false,
                    columns: {
                      a!gridColumn(
                        label: "Trade",
                        width: "NARROW_PLUS",
                        sortField: "tradeId",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(
                              text: index(fv!row, "tradeId", ""),
                              color: "#5A7392",
                              link: a!recordLink(
                                recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
                                identifier: index(fv!row, "caseId", null)
                              )
                            ),
                            a!richTextItem(
                              text: "  " & index(fv!row, "batchTag", ""),
                              color: "#3E7396",
                              size: "SMALL",
                              showWhen: index(fv!row, "batchTag", "") <> ""
                            )
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Instrument",
                        width: "AUTO",
                        sortField: "ticker",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "sideLabel", ""), color: "#6E7885", size: "SMALL"),
                            a!richTextItem(text: "  " & index(fv!row, "ticker", ""), color: "#454F5C"),
                            a!richTextItem(text: "  " & index(fv!row, "instrumentName", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Counterparty",
                        width: "NARROW_PLUS",
                        sortField: "counterparty",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: a!richTextItem(text: index(fv!row, "counterparty", ""), color: "#454F5C", size: "SMALL")
                        )
                      ),
                      a!gridColumn(
                        label: "Value",
                        width: "NARROW",
                        align: "END",
                        sortField: "notional",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          align: "RIGHT",
                          value: a!richTextItem(text: index(fv!row, "valueDisplay", ""), color: "#454F5C", size: "SMALL")
                        )
                      ),
                      a!gridColumn(
                        label: "Fail risk",
                        width: "NARROW",
                        align: "END",
                        sortField: "probPct",
                        helpTooltip: "Live from Snowflake — the model's fail probability and risk tier for this trade.",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          align: "RIGHT",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(text: index(fv!row, "probDisplay", "—"), color: index(fv!row, "tierColor", "#4A5462"), style: "STRONG", size: "SMALL"),
                            a!richTextItem(text: "  " & index(fv!row, "riskTier", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Escalation",
                        width: "MEDIUM",
                        sortField: "escLine",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "escLine", ""), color: "#B3261E", style: "STRONG", size: "SMALL"),
                            char(10),
                            a!richTextItem(text: index(fv!row, "escSub", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      ),
                      a!gridColumn(
                        label: "Status",
                        width: "NARROW",
                        sortField: "statusLabel",
                        value: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!row, "statusLabel", ""), color: "#6E7885", style: "STRONG", size: "SMALL"),
                            char(10),
                            a!richTextItem(text: "cutoff " & index(fv!row, "cutoffAt", ""), color: "#6E7885", size: "SMALL")
                          }
                        )
                      )
                    }
                  )
                }
              ),

              /* ---------- QUEUE 3: CLEARED THIS BATCH ----------
                 COLLAPSED BY DEFAULT AND COUNTING TRADES, NOT CASES. The summary
                 line is the whole point: it states the split between what
                 Snowflake's scoring decided on its own and what the agent
                 resolved, and then how much of the batch went through with no
                 analyst at all. Those are three different claims and the line
                 makes all three separately checkable.
                 THE ROWS ARE NOT SELECTABLE, deliberately: most of them have no
                 case at all — "no case needed" is literal — so there is nothing
                 for the preview rail to preview. The one or two rows that DO
                 have a case carry a record link on the trade id instead, which
                 is the honest affordance: a resolved case opens, a
                 never-opened case does not pretend to. */
              a!cardLayout(
                showWhen: local!hasBatch,
                padding: "NONE",
                showBorder: true,
                style: "NONE",
                shape: "SEMI_ROUNDED",
                contents: {
                  a!cardLayout(
                    padding: "LESS",
                    style: "#FAFBFC",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextIcon(icon: "circle", color: "#17715B", size: "SMALL"),
                        a!richTextItem(text: "  CLEARED THIS BATCH ", style: "STRONG", size: "SMALL", color: "#454F5C"),
                        a!richTextItem(text: "(" & count(local!cleared) & ")", style: "STRONG", size: "SMALL", color: "#6E7885"),
                        a!richTextItem(text: "  ·  scoring and agent together", size: "SMALL", color: "#6E7885")
                      }
                    )
                  ),
                  a!cardLayout(
                    padding: "LESS",
                    style: "NONE",
                    showBorder: false,
                    contents: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextItem(text: local!snowClearedCount, style: "STRONG", color: "#1B2330", size: "SMALL"),
                        a!richTextItem(text: " cleared by Snowflake scoring", color: "#4A5462", size: "SMALL"),
                        a!richTextItem(text: "   ·   ", color: "#9AA6B3", size: "SMALL"),
                        a!richTextItem(text: local!agentResolvedCount, style: "STRONG", color: "#1B2330", size: "SMALL"),
                        a!richTextItem(text: " resolved by the agent", color: "#4A5462", size: "SMALL"),
                        a!richTextItem(text: "   ·   ", color: "#9AA6B3", size: "SMALL", showWhen: local!analystResolvedCount > 0),
                        a!richTextItem(text: local!analystResolvedCount, style: "STRONG", color: "#1B2330", size: "SMALL", showWhen: local!analystResolvedCount > 0),
                        a!richTextItem(text: " resolved by an analyst", color: "#4A5462", size: "SMALL", showWhen: local!analystResolvedCount > 0),
                        a!richTextItem(text: "   ·   ", color: "#9AA6B3", size: "SMALL"),
                        a!richTextItem(text: local!noTouchCount & " of " & local!batchCount & " without analyst touch", style: "STRONG", color: "#17715B", size: "SMALL")
                      }
                    )
                  ),
                  a!sectionLayout(
                    label: "Show the " & count(local!cleared) & " cleared trade" & if(count(local!cleared) = 1, "", "s"),
                    labelSize: "EXTRA_SMALL",
                    labelColor: "SECONDARY",
                    isCollapsible: true,
                    isInitiallyCollapsed: true,
                    marginBelow: "NONE",
                    contents: a!gridField(
                      labelPosition: "COLLAPSED",
                      data: local!cleared,
                      emptyGridMessage: "Nothing cleared in this batch.",
                      pageSize: 25,
                      spacing: "DENSE",
                      borderStyle: "LIGHT",
                      selectable: false,
                      columns: {
                        a!gridColumn(
                          label: "Trade",
                          width: "NARROW_PLUS",
                          sortField: "tradeId",
                          value: a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            preventWrapping: true,
                            value: {
                              /* A scored-clear trade has no case, so its id is
                                 plain text: there is nothing to open, and a
                                 dead link would be worse than no link. */
                              a!richTextItem(
                                text: index(fv!row, "tradeId", ""),
                                color: "#454F5C",
                                showWhen: a!isNullOrEmpty(index(fv!row, "clearedCaseId", null))
                              ),
                              a!richTextItem(
                                text: index(fv!row, "tradeId", ""),
                                style: "STRONG",
                                link: a!recordLink(
                                  recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
                                  identifier: index(fv!row, "clearedCaseId", null)
                                ),
                                showWhen: not(a!isNullOrEmpty(index(fv!row, "clearedCaseId", null)))
                              )
                            }
                          )
                        ),
                        a!gridColumn(
                          label: "Instrument",
                          width: "AUTO",
                          sortField: "ticker",
                          value: a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            value: {
                              a!richTextItem(text: index(fv!row, "sideLabel", ""), color: index(fv!row, "sideColor", "#4A5462"), style: "STRONG", size: "SMALL"),
                              a!richTextItem(text: "  " & index(fv!row, "ticker", ""), color: "#454F5C"),
                              a!richTextItem(text: "  " & index(fv!row, "quantityDisplay", ""), color: "#6E7885", size: "SMALL")
                            }
                          )
                        ),
                        a!gridColumn(
                          label: "Counterparty",
                          width: "NARROW_PLUS",
                          sortField: "counterparty",
                          value: index(fv!row, "counterparty", "")
                        ),
                        a!gridColumn(
                          label: "Value",
                          width: "NARROW",
                          align: "END",
                          sortField: "notional",
                          value: index(fv!row, "valueDisplay", "")
                        ),
                        a!gridColumn(
                          label: "Fail risk",
                          width: "NARROW",
                          align: "END",
                          sortField: "probPct",
                          helpTooltip: "Live from Snowflake — the model's fail probability and risk tier for this trade.",
                          value: a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            align: "RIGHT",
                            preventWrapping: true,
                            value: {
                              a!richTextItem(text: index(fv!row, "probDisplay", "—"), color: index(fv!row, "tierColor", "#4A5462"), style: "STRONG", size: "SMALL"),
                              a!richTextItem(text: "  " & index(fv!row, "riskTier", ""), color: "#6E7885", size: "SMALL")
                            }
                          )
                        ),
                        a!gridColumn(
                          label: "Disposition",
                          width: "MEDIUM",
                          sortField: "dispLine",
                          value: a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            value: {
                              /* The mark rides the scored-clear verb only. It is
                                 the one disposition on this screen that IS a
                                 Snowflake decision; the agent's is not. */
                              rule!SO_snowflakeMark(showWhen: index(fv!row, "isSnowCleared", false)),
                              a!richTextItem(text: " ", size: "SMALL", showWhen: index(fv!row, "isSnowCleared", false)),
                              a!richTextItem(text: index(fv!row, "dispLine", ""), color: index(fv!row, "dispColor", "#454F5C"), style: "STRONG", size: "SMALL"),
                              char(10),
                              a!richTextItem(text: index(fv!row, "dispSub", ""), color: "#6E7885", size: "SMALL")
                            }
                          )
                        ),
                        a!gridColumn(
                          label: "Time",
                          width: "NARROW",
                          /* Sorts on what the column SHOWS. A scored-clear row
                             shows its scoring time and an agent-resolved row
                             shows when it resolved, so sorting on the scoring
                             stamp would order the column by a value one of its
                             row kinds never displays. */
                          sortField: "timeDisplay",
                          value: a!richTextDisplayField(
                            labelPosition: "COLLAPSED",
                            preventWrapping: true,
                            value: a!richTextItem(text: index(fv!row, "timeDisplay", ""), color: "#6E7885", size: "SMALL")
                          )
                        )
                      }
                    )
                  )
                }
              )
            }
          ),

          /* ---------- PREVIEW RAIL ----------
             Unchanged in structure and unchanged in contract: it takes one
             assembled row map plus the stored assessment. What changed beneath
             it is which grid feeds the selection — NEEDS YOUR ACTION, the only
             queue whose rows are a decision the analyst still owns. */
          a!columnLayout(
            width: "NARROW_PLUS",
            contents: rule!SO_watchlistPreviewRail(
              row: local!selected,
              assessmentText: if(
                a!isNullOrEmpty(local!assessment),
                null,
                local!assessment['recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{2bb72559-6a2b-4624-b156-efc8237287ce}commentText']
              ),
              assessmentAt: if(
                a!isNullOrEmpty(local!assessment),
                null,
                local!assessment['recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn']
              )
            )
          )
        }
      )
    }
  )
)
