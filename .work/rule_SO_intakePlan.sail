/*
 * SO_intakePlan — which trades in a demo run get a case.
 *
 * CASE-CREATION CRITERION (ruled 2026-09-10, packet-spec §3): RISK_TIER is
 * High or Critical, READ FROM THE PREDICTION ROWS. There is no id list here;
 * that the three seeded stories qualify is a consequence of their tiers.
 *
 * SCOPE: only this run's fifteen packet ids, derived exactly as the Snowflake
 * procedures derive them — 'TRD9' || upper(run name without dashes) || 01..15 —
 * so another run's trades can never be picked up, at any code length.
 *
 * STORY ATTRIBUTES (packet-spec §4): the fail reason and the cutoff offset are
 * Appian-authored per story, keyed by the two-digit sequence. This table is
 * their ONE home. A High/Critical trade with no story row gets NO case and is
 * reported under noStory — a fail reason is never invented.
 *
 * IDEMPOTENCY: a trade that already has a case in this run, in ANY status, is
 * reported under alreadyCased and left out of toCreate. (The create path's own
 * guard only sees OPEN cases, so a straight-through case resolved minutes ago
 * would otherwise be created again on a re-run.)
 */
a!localVariables(
  local!fTradeId: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ba723c14-124b-48ff-ab51-02bf948242f8}tradeId',
  local!fTier: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier',
  local!fProb: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability',
  local!fDesk: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions.relationships.{b043f244-ac93-4a94-b022-bf7e4b302e6c}trade.fields.{343aa2d4-b980-4120-80d2-7222e8d2a0cd}desk',
  local!fCaseTrade: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
  local!fCaseSession: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID',

  local!name: a!defaultValue(ri!runName, ""),
  local!code: upper(substitute(local!name, "-", "")),
  local!packetIds: if(
    a!isNullOrEmpty(local!code),
    {},
    a!forEach(items: enumerate(15) + 1, expression: "TRD9" & local!code & text(fv!item, "00"))
  ),

  local!stories: {
    a!map(seq: "01", failReason: "insufficient_securities", cutoffMinutes: 185),
    a!map(seq: "02", failReason: "funding_gap", cutoffMinutes: 150),
    a!map(seq: "03", failReason: "operational_error", cutoffMinutes: 540)
  },
  local!storySeqs: a!forEach(items: local!stories, expression: fv!item.seq),

  local!atRisk: if(
    a!isNullOrEmpty(local!packetIds),
    {},
    a!queryRecordType(
      recordType: 'recordType!{b1967741-7f64-4259-a3af-ef2c6ea2e3bf}SO Trade Predictions',
      fields: { local!fTradeId, local!fTier, local!fProb, local!fDesk },
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: local!fTradeId, operator: "in", value: local!packetIds),
          a!queryFilter(field: local!fTier, operator: "in", value: { "High", "Critical" })
        },
        ignoreFiltersWithEmptyValues: false
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50)
    ).data
  ),

  local!casedTradeIds: if(
    a!isNullOrEmpty(local!name),
    {},
    a!forEach(
      items: a!queryRecordType(
        recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
        fields: { local!fCaseTrade },
        filters: a!queryFilter(field: local!fCaseSession, operator: "=", value: local!name),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
      ).data,
      expression: tostring(fv!item[local!fCaseTrade])
    )
  ),

  local!rows: a!forEach(
    items: local!atRisk,
    expression: a!localVariables(
      local!id: tostring(fv!item[local!fTradeId]),
      local!pos: wherecontains(right(local!id, 2), local!storySeqs),
      local!story: if(a!isNullOrEmpty(local!pos), null, index(local!stories, index(local!pos, 1, 0), null)),
      a!map(
        tradeId: local!id,
        riskTier: fv!item[local!fTier],
        failProbability: fv!item[local!fProb],
        desk: fv!item[local!fDesk],
        failReason: if(a!isNullOrEmpty(local!story), null, index(local!story, "failReason", null)),
        cutoffMinutes: if(a!isNullOrEmpty(local!story), null, index(local!story, "cutoffMinutes", null)),
        alreadyCased: if(a!isNullOrEmpty(local!casedTradeIds), false, contains(local!casedTradeIds, local!id))
      )
    )
  ),

  a!map(
    runName: local!name,
    atRiskTradeIds: a!forEach(items: local!rows, expression: fv!item.tradeId),
    alreadyCased: a!flatten(a!forEach(items: local!rows, expression: if(fv!item.alreadyCased, fv!item.tradeId, {}))),
    noStory: a!flatten(a!forEach(items: local!rows, expression: if(a!isNullOrEmpty(fv!item.failReason), fv!item.tradeId, {}))),
    toCreate: a!flatten(a!forEach(
      items: local!rows,
      expression: if(or(fv!item.alreadyCased, a!isNullOrEmpty(fv!item.failReason)), {}, fv!item)
    ))
  )
)