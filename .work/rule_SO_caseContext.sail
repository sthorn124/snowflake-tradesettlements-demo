/*
 * SO_caseContext — assembles the complete triage context for one case as a labeled
 * plain-text block, for the SO Triage Agent's caseContext input.
 *
 * Why process-side: an Agent Studio record-data tool returns its record type's OWN
 * fields only and does not traverse relationships (measured 2026-08-31). Assembling
 * here gives one query instead of four tool calls, deterministic field order and
 * wording, and keeps the read in the process's security context.
 *
 * Every field is null-safe (§4). A missing counterparty renders "not found" rather
 * than erroring; the agent's grounding rule handles the gap from there.
 * fields: is passed explicitly and completely (§4) — omit it and every related field
 * returns null with no error, which is precisely the failure this rule replaces.
 */
a!localVariables(
  local!fCaseId: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
  local!fStatus: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
  local!fDesk: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk',
  local!fReason: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
  local!fCutoff: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs',
  local!fTradeId: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId',
  local!fInstr: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId',
  local!fDir: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
  local!fNotional: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional',
  local!fCcy: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency',
  local!fEsd: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate',
  local!fTdesk: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{343aa2d4-b980-4120-80d2-7222e8d2a0cd}desk',
  local!fLag: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs',
  local!fTicker: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker',
  local!fIName:  'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name',
  local!fIsin:   'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{81083946-31a9-4e4f-9ff0-3a0ad8881a02}isin',
  local!fCsd:    'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{1e559342-6615-482d-b8d9-6da82605fbc9}csd',
  local!fMatched:  'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{215fda37-6b90-4fe8-9e52-6018dbb2ef52}isMatched',
  local!fMatchedAt:'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{919f547f-434d-463c-a702-cecc8662376b}matchedAt',
  local!fProb: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability',
  local!fTier: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier',
  local!fScored: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt',
  local!fCpName: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name',
  local!fCpType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9c4cc4dc-4faf-4d11-b305-8b34439ada47}type',
  local!fCpRegion: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{96fe3d9b-eb7a-4518-9854-fbc78bfd9ba9}region',
  local!fCpTier: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier',
  local!fCpRate: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate',

  local!c: a!queryRecordByIdentifier(
    recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
    identifier: ri!caseId,
    fields: {
      local!fCaseId, local!fStatus, local!fDesk, local!fReason, local!fCutoff,
      local!fTradeId, local!fInstr, local!fDir, local!fNotional, local!fCcy,
      local!fEsd, local!fTdesk, local!fLag,
      local!fTicker, local!fIName, local!fIsin, local!fCsd,
      local!fMatched, local!fMatchedAt,
      local!fProb, local!fTier, local!fScored,
      local!fCpName, local!fCpType, local!fCpRegion, local!fCpTier, local!fCpRate
    }
  ),

  local!cutoff: local!c[local!fCutoff],
  local!hrs: floor(todecimal(a!defaultValue(local!cutoff, now()) - now()) * 24),
  local!cpName: local!c[local!fCpName],

  local!caseLine: "CASE: SO-" & a!defaultValue(local!c[local!fCaseId], 0)
    & " | status " & a!defaultValue(local!c[local!fStatus], "not available")
    & " | desk " & a!defaultValue(local!c[local!fDesk], "not available")
    & " | fail reason " & a!defaultValue(local!c[local!fReason], "not available")
    & " | cutoff " & if(
        a!isNullOrEmpty(local!cutoff),
        "not available",
        text(a!defaultValue(local!cutoff, now()), "yyyy-mm-dd hh:mm") & " (" & local!hrs & " hours from now)"
      ),

  local!tradeLine: "TRADE: " & a!defaultValue(local!c[local!fTradeId], "not found")
    & " | instrument " & a!defaultValue(local!c[local!fInstr], "not available")
    & " | " & a!defaultValue(local!c[local!fDir], "not available")
    /* MEASURED 2026-09-02: text() applies only as many thousands groups as are
       LITERALLY written in the format, and returns "N/A" once the number
       outgrows them. "#,##0.00" rendered 18700500 as "18700,500.00"; three
       groups cover to billions and are harmless below. */
    & " | notional " & text(a!defaultValue(local!c[local!fNotional], 0), "#,###,###,##0.00") & " " & a!defaultValue(local!c[local!fCcy], "")
    & " | expected settlement " & if(
        a!isNullOrEmpty(local!c[local!fEsd]),
        "not available",
        text(a!defaultValue(local!c[local!fEsd], today()), "yyyy-mm-dd")
      )
    & " | desk " & a!defaultValue(local!c[local!fTdesk], "not available")
    & " | broker confirmation lag " & a!defaultValue(local!c[local!fLag], 0) & "h",

  /* INSTRUMENT — so the agent names the line the way a desk does ("SAP GY /
     SAP SE") instead of reciting an internal id, and knows where it settles.
     ISIN is legitimately null on an FX forward (not a securities issue), so it
     renders "no ISIN (not a securities issue)" rather than "not available" —
     the agent must not read a structural absence as missing data. */
  local!instrLine: "INSTRUMENT: " & a!defaultValue(local!c[local!fTicker], "not available")
    & if(
        a!isNullOrEmpty(local!c[local!fIName]),
        "",
        " — " & local!c[local!fIName]
      )
    & " | instrument id " & a!defaultValue(local!c[local!fInstr], "not available")
    & " | ISIN " & if(
        a!isNullOrEmpty(local!c[local!fIsin]),
        "no ISIN (not a securities issue, e.g. an FX forward)",
        local!c[local!fIsin]
      )
    & " | settles at " & a!defaultValue(local!c[local!fCsd], "not available"),

  /* MATCHING — an unmatched trade at T+1 is a fail precursor in its own right,
     and the agent should weigh it separately from the model's probability. */
  local!matchLine: "MATCHING: " & if(
    a!isNullOrEmpty(local!c[local!fMatched]),
    "matched status not available",
    if(
      local!c[local!fMatched],
      "matched" & if(
        a!isNullOrEmpty(local!c[local!fMatchedAt]),
        "",
        " at " & text(local!c[local!fMatchedAt], "yyyy-mm-dd hh:mm")
      ),
      "NOT MATCHED — the trade is still unmatched, which is itself a fail precursor"
    )
  ),

  /* ONWARD DELIVERIES — whether a fail here stops at this settlement or cascades
     into our own sells of the same line. Rendered as a plain statement because
     the agent should reason about the consequence, not re-derive the count. */
  local!onward: rule!SO_onwardDeliveries(
    instrumentId: local!c[local!fInstr],
    settlementDate: local!c[local!fEsd]
  ),
  local!onwardLine: "ONWARD DELIVERIES: " & if(
    a!defaultValue(local!onward, 0) = 0,
    "no onward deliveries of this instrument in the next 2 settlement cycles — a fail here would be contained to this settlement",
    local!onward & " onward deliver" & if(local!onward = 1, "y", "ies")
      & " of this instrument settle in the next 2 settlement cycles — a fail may cascade"
  ),

  local!predLine: "PREDICTION: fail probability " & a!defaultValue(local!c[local!fProb], "not available")
    & " | risk tier " & a!defaultValue(local!c[local!fTier], "not available")
    & " | scored " & if(
        a!isNullOrEmpty(local!c[local!fScored]),
        "not available",
        text(a!defaultValue(local!c[local!fScored], now()), "yyyy-mm-dd hh:mm")
      )
    & " | predicted reason " & a!defaultValue(local!c[local!fReason], "not available") & " (from the case record; TRADE_PREDICTIONS carries no reason field)",

  local!cptyLine: if(
    a!isNullOrEmpty(local!cpName),
    "COUNTERPARTY: not found",
    "COUNTERPARTY: " & a!defaultValue(local!cpName, "")
      & " | type " & a!defaultValue(local!c[local!fCpType], "not available")
      & " | region " & a!defaultValue(local!c[local!fCpRegion], "not available")
      & " | counterparty risk tier " & a!defaultValue(local!c[local!fCpTier], "not available")
      & " | historical fail rate " & a!defaultValue(local!c[local!fCpRate], "not available")
  ),

  local!caseLine & char(10) & local!tradeLine & char(10) & local!instrLine & char(10)
    & local!matchLine & char(10) & local!predLine & char(10) & local!cptyLine
    & char(10) & local!onwardLine
)
