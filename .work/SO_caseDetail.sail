/*
 * SO_caseDetail — the settlement case record, in full.
 * Display target: mockups/case_detail.html, which is the STRUCTURAL authority
 * for this screen exactly as the watchlist mockup was for the queue.
 *
 * THIS IS A RECORD-TYPE VIEW, NOT A SITE PAGE. SO Settlement Case shipped with
 * one view — the default `summary` stub whose uiExpr was empty — and the
 * watchlist rail's "Open case →" is an a!recordLink that already routes there.
 * Populating that stub is therefore the whole wiring: no new page, no second
 * navigation path, and the one-door rule from the rail holds by construction.
 *
 * WHERE THIS SCREEN DIFFERS FROM THE RAIL, AND WHY.
 *  - The rail EXCERPTS the agent assessment and skips its identity opening,
 *    because the rail header just said the identity. THIS screen shows the
 *    assessment WHOLE, opening included: it is the standalone audit record and
 *    must identify its own subject. Same text, different obligation.
 *  - Trade id and case id BELONG here. They were removed from the rail because
 *    the trade id was already on the selected row beside it and the case id is
 *    plumbing; on the record screen the record IS the subject.
 *
 * TYPE SCALE, unchanged from the rail: SMALL muted labels, STANDARD semibold
 * ink values, and exactly two MEDIUM exceptions — the ticker, and the
 * probability and live-countdown values. Nothing exceeds STANDARD elsewhere and
 * there is no LARGE anywhere. Emphasis is weight and colour, never size.
 *
 * PROVENANCE, two tiers, via rule!SO_snowflakeMark and nothing else:
 * FIELD-level marks on Snowflake INTELLIGENCE (fail probability, predicted
 * reason, the counterparty's 12-month fail rate); a CARD-level "live read" tag
 * on the wholly-Snowflake-served Trade & counterparty and Recent fails cards.
 * Penalty accrual and onward deliveries are APPIAN-computed and carry no mark —
 * marking them would claim Snowflake decided something it did not.
 *
 * ONWARD DELIVERIES READS ZERO ON EVERY P4-VERIFY CASE, and that is the
 * mockup's own state ("None next 2 cycles — contained"), not an empty one. See
 * the build log: the fixtures point at baseline trades whose settlement dates
 * are historic and sparse, so no onward sell falls in the two-day window. The
 * non-zero "may cascade" branch is written and unexercised by fixtures.
 */
a!localVariables(
  /* EVERY QUERY ON THIS SCREEN IS GUARDED ON A NULL IDENTIFIER, and that is
     not defensive padding — THE RECORD-VIEW VALIDATOR EVALUATES THE VIEW WITH
     rv!record NULL. An unguarded a!queryFilter with operator "=" then fails
     with "value must not be null or empty" and the view will not save at all
     (MEASURED — this exact error blocked the first wiring attempt). CLAUDE.md
     records the sibling trap for a!queryRecordByIdentifier; it applies to any
     equality filter fed from the record. */
  local!hasId: not(a!isNullOrEmpty(ri!caseId)),
  local!caseRow: if(not(local!hasId), {}, a!queryRecordType(
    recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
    fields: {
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{4713f39a-5236-4b71-b895-1a703bb581f2}tradeDate', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{343aa2d4-b980-4120-80d2-7222e8d2a0cd}desk', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{215fda37-6b90-4fe8-9e52-6018dbb2ef52}isMatched', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{919f547f-434d-463c-a702-cecc8662376b}matchedAt', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{da0e54bd-1c18-408c-81ab-8076d9abc41e}counterpartyId',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{81083946-31a9-4e4f-9ff0-3a0ad8881a02}isin', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{1e559342-6615-482d-b8d9-6da82605fbc9}csd',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9c4cc4dc-4faf-4d11-b305-8b34439ada47}type', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{96fe3d9b-eb7a-4518-9854-fbc78bfd9ba9}region', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{2d747fe0-1844-409a-89ef-dab3e31889b1}opsContactName', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{2b8e27d6-28d5-4416-9cc9-a1cffb268eb8}opsContactPhone',
      'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier', 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{1ae3b327-c800-4114-bcf0-4c45fca5dc1e}scoredAt'
    },
    filters: a!queryFilter(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', operator: "=", value: ri!caseId),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
  ).data),
  local!c: index(local!caseRow, 1, null),
  local!found: not(a!isNullOrEmpty(local!c)),

  /* ---- the shared display rules, run ONCE each ---- */
  local!ac: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{27191abd-43c7-46e8-9c6a-dc38775123ad}assetClass', ""),
  local!prob: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{ae03e55e-3c7b-4d4c-9000-5ec053f552a6}failProbability', null),
  local!cutoff: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs', null),
  local!status: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status', ""),
  local!notional: todecimal(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', 0)),
  local!ccy: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency', ""),
  local!co: rule!SO_cutoffDisplay(cutoffTs: local!cutoff),
  local!st: rule!SO_statusDisplay(status: local!status),
  local!fr: rule!SO_failReasonDisplay(failReason: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason', ""), short: false),
  local!qty: rule!SO_quantityDisplay(quantity: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{d1e9cae3-2e6d-4f5d-a74a-e1a09bf924c2}quantity', null), assetClass: local!ac),
  local!pri: rule!SO_casePriority(failProbability: local!prob, cutoffTs: local!cutoff),
  local!band: rule!SO_priorityBand(priority: local!pri),
  local!ar: rule!SO_autoReleaseDisplay(confidenceScore: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore', null), status: local!status),
  local!pen: rule!SO_penaltyAccrual(value: local!notional, currency: local!ccy),
  local!onward: rule!SO_onwardDeliveries(
    instrumentId: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId', null),
    settlementDate: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate', null)
  ),
  local!lag: todecimal(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs', 0)),
  local!hrsLeft: todecimal(a!defaultValue(index(local!co, "hoursRemaining", 0), 0)),
  local!isPast: a!defaultValue(index(local!co, "isPast", false), false),
  local!lagFits: if(or(a!isNullOrEmpty(local!lag), a!isNullOrEmpty(local!hrsLeft)), null, local!lag < local!hrsLeft),
  local!scaleMax: max({ 0.1, local!hrsLeft, local!lag }),
  local!lagText: if(
    a!isNullOrEmpty(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs', null)),
    "—",
    floor(local!lag) & "h " & text(floor((local!lag - floor(local!lag)) * 60), "00") & "m"
  ),
  local!tierColor: a!match(
    value: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier', ""),
    equals: "Critical", then: "#B3261E",
    equals: "High", then: "#96590A",
    default: "#4A5462"
  ),
  /* SETTLES FROM THE CUTOFF, never the trade's stored expectedSettlementDate —
     the cutoff IS the settlement-date cutoff, so the two cannot contradict.
     Rebuilt from the LOCAL rendering because text() renders local while
     date-part functions return UTC (§4). */
  /* TRADE DATE IS DERIVED, for the same reason Settles is. The stored
     tradeDate is Snowflake baseline and never moves, so against a re-dated
     cutoff it rendered "Mon 30 Dec" beside "Settles Wed 9 Sep" — the identical
     contradiction the Settles ruling fixed. The settlement canon is T+1, and
     this screen asserts T+1 on the Settles line, so trade date IS settles
     minus one and the two cannot disagree. Appian-computed, unmarked. */
  local!settles: if(
    a!isNullOrEmpty(local!cutoff),
    null,
    date(tointeger(text(local!cutoff, "yyyy")), tointeger(text(local!cutoff, "mm")), tointeger(text(local!cutoff, "dd")))
  ),
  local!tradeDate: if(a!isNullOrEmpty(local!settles), null, local!settles - 1),

  /* ---- the agent's assessment: the LATEST comment is the assessment ---- */
  local!assessment: if(not(local!hasId), null, index(
    a!queryRecordType(
      recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment',
      fields: { 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{2bb72559-6a2b-4624-b156-efc8237287ce}commentText', 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn', 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{ffa2f4eb-64b5-4a09-9f05-85fcd3f24d04}author' },
      filters: a!queryFilter(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId', operator: "=", value: ri!caseId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn', ascending: false))
    ).data, 1, null
  )),
  local!assessmentText: if(a!isNullOrEmpty(local!assessment), null, index(local!assessment, 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{2bb72559-6a2b-4624-b156-efc8237287ce}commentText', null)),
  local!assessmentAt: if(a!isNullOrEmpty(local!assessment), null, index(local!assessment, 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn', null)),
  local!regionDisplay: rule!SO_regionDisplay(region: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{96fe3d9b-eb7a-4518-9854-fbc78bfd9ba9}region', "")),

  /* ---- THE ACTIONS ARE NOT ON THIS SCREEN AT ALL, and that is the point.
     Record Disposition, Assign, Escalate and Add Comment are RELATED-ACTION
     SHORTCUTS on the record header, beside the Summary tab — the standard
     Appian position — configured on the view (`relatedActionShortcuts`), not
     built here. The Related Actions tab is hidden, because the header now
     carries the same four and a second copy one tab away is just a second
     place to look. This card is pure identity again: ticker, name and side,
     ids, pills.

     THE VISIBILITY EXPRESSIONS ON THE RECORD TYPE ARE NOW THE ONLY GATE, and
     that is a real trade for a real gain. The in-card bar had duplicated the
     status logic here so a silently-failing visibility expression could not
     empty the toolbar unnoticed; with the bar gone that second, observable
     gate is gone too. Nothing in a session can see the header's action set —
     it is rendered outside this interface — so the status→action mapping is
     now a BROWSER check and nothing else. The sets, for that check:
       New / In triage / Awaiting review -> Assign, Record disposition, Escalate, Add comment
       In remediation                    -> Record disposition, Escalate, Add comment
       Escalated                         -> Record disposition, Add comment
       Resolved (either)                 -> Add comment only
     Two conveniences bought it: the actions sit where an Appian user already
     looks for them, and they follow the record rather than this one view. */
  local!lane: a!defaultValue(index(local!ar, "lane", "UNSCORED"), "UNSCORED"),
  local!scored: and(not(a!isNullOrEmpty(local!assessmentText)), local!lane <> "UNSCORED"),
  local!laneColor: a!defaultValue(index(local!ar, "pillColor", "#6E7885"), "#6E7885"),
  local!arScore: tointeger(a!defaultValue(index(local!ar, "score", 0), 0)),
  local!arGate: tointeger(a!defaultValue(index(local!ar, "gate", 80), 80)),
  local!arCells: 24,
  local!arFill: tointeger(max({ 0, min({ local!arCells, tointeger(round(local!arCells * local!arScore / 100, 0)) }) })),
  local!arGateCell: tointeger(max({ 1, min({ local!arCells, tointeger(round(local!arCells * local!arGate / 100, 0)) }) })),

  /* ---- recent settlement fails for THIS counterparty ----
     NO TIME WINDOW IS CLAIMED. SETTLEMENT_HISTORY spans 2023-01 to 2025-07
     against a 2026 system date, so the mockup's "last 30 days" would render
     empty for every counterparty. The card shows the N MOST RECENT with their
     real dates and says only "Recent settlement fails" (TODO, 2026-09-02). */
  local!cptyId: if(local!found, index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{da0e54bd-1c18-408c-81ab-8076d9abc41e}counterpartyId', null), null),
  local!recentFails: if(a!isNullOrEmpty(local!cptyId), {}, a!queryRecordType(
    recordType: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History',
    fields: { 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{bad6863a-6fd2-40f3-a5ea-b41f50235249}tradeId', 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{73e751ad-433c-4555-994e-266d8aac867a}actualSettlementDate', 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{1174e91d-5fbc-4c99-bbeb-3d0b34db64f9}failReason', 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency', 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker' },
    filters: a!queryLogicalExpression(operator: "AND", filters: {
      a!queryFilter(field: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{385bbbde-01e3-47dc-bfa7-0901d92838cb}counterpartyId', operator: "=", value: local!cptyId),
      a!queryFilter(field: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{7a475c04-027c-4437-8de5-926105a81572}status', operator: "=", value: "FAILED")
    }),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5, sort: a!sortInfo(field: 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{73e751ad-433c-4555-994e-266d8aac867a}actualSettlementDate', ascending: false))
  ).data),

  /* ---- activity: record events, newest first ---- */
  local!events: if(not(local!hasId), {}, a!queryRecordType(
    recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
    fields: { 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6862ba51-9181-470c-8798-9bfd1cabc8bb}comment', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName' },
    filters: a!queryFilter(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId', operator: "=", value: ri!caseId),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 25, sort: a!sortInfo(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', ascending: false))
  ).data),

  a!formLayout(
    backgroundColor: "#F3F5F8",
    contentsWidth: "FULL",
    focusOnFirstInput: false,
    contents: {
      /* ================= NOT FOUND / NO ACCESS =================
         A record view is evaluated with a null identifier by the view
         validator, and RLS can legitimately hide a case from this analyst.
         Both land here rather than on an error. */
      a!cardLayout(
        showWhen: not(local!found),
        padding: "MORE",
        shape: "SEMI_ROUNDED",
        contents: a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {
            a!richTextItem(text: "This case is not available to you.", style: "STRONG", size: "STANDARD", color: "#454F5C"),
            char(10),
            a!richTextItem(
              text: "It may have been closed, or it may sit on a desk outside your book. Settlement cases are scoped by desk.",
              size: "SMALL", color: "#6E7885"
            )
          }
        )
      ),

      /* ============ 1 · HEADER ROW — identity AND risk, ONE card ============
         The identity card and the risk banner were two stacked cards, which
         left a full-width strip carrying four short strings and then a second
         strip carrying five. Merged: identity in a fixed MEDIUM column on the
         left, the five risk cells filling everything to its right. ONE flat
         six-column layout rather than a column containing a nested layout —
         nesting would let the inner group size itself independently of the
         identity block and reintroduce the gap this removes.

         NO TRADE ID AND NO CASE ID HERE. The record header title now composes
         both from metadata ("TRD001089 — CHFJPY 1M FWD · Case SO-39"), and a
         record screen that prints its own identifiers twice is answering a
         question nobody asked twice.

         THE INSTRUMENT RECORD LINK MOVED WITH THE TICKER. The ticker line is
         gone from this card because the title owns it, so the link to
         SO Instrument now sits on the instrument NAME — same destination, and
         the requirement is that the link exists, not which word carries it.

         DECORATIVE BAR: kept from the risk banner, at START, in the cutoff
         band colour. It now reads as the urgency of the whole header rather
         than of one of two cards, which is what it always meant.

         THE TWO MEDIUM EXCEPTIONS still live here and nowhere else: the
         probability value in its tier colour, and the live countdown in its
         band colour. The identity title is STANDARD semibold — the ticker was
         the other MEDIUM exception and it is no longer on this screen. */
      a!cardLayout(
        showWhen: local!found,
        padding: "LESS",
        shape: "SEMI_ROUNDED",
        showBorder: true,
        marginBelow: "STANDARD",
        decorativeBarPosition: "START",
        decorativeBarColor: index(local!co, "color", "#3E7396"),
        contents: a!columnsLayout(
          alignVertical: "TOP",
          columns: {
            /* ---- identity ---- */
            a!columnLayout(width: "MEDIUM", contents: {
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(
                    text: if(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction', "") = "BUY", "B", "S"),
                    color: if(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction', "") = "BUY", "#17715B", "#4A5462"),
                    style: "STRONG", size: "SMALL"
                  ),
                  a!richTextItem(
                    text: "  " & index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{e2643956-8272-47e9-b49b-5ff05b40ef4d}name', ""),
                    link: if(
                      a!isNullOrEmpty(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId', null)),
                      null,
                      a!recordLink(recordType: 'recordType!{553867ce-5f08-44a8-a81c-ed5450f2897d}SO Instrument', identifier: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId', null))
                    ),
                    linkStyle: "STANDALONE",
                    color: "#1B2330", style: "STRONG", size: "STANDARD"
                  ),
                  /* An FX forward has no unit count, so the quantity clause
                     disappears entirely rather than printing "0 shares"
                     (CLAUDE.md quantity canon). */
                  a!richTextItem(
                    text: if(
                        index(local!qty, "hasQuantity", false),
                        "  ·  " & index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction', "") & " " & index(local!qty, "display", ""),
                        "  ·  " & index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction', "")
                      )
                      & "  ·  " & rule!SO_fmtMoney(amount: local!notional, currency: local!ccy, compact: true),
                    color: "#1B2330", style: "STRONG", size: "STANDARD"
                  )
                }
              ),
              a!tagField(
                labelPosition: "COLLAPSED",
                tags: {
                  a!tagItem(text: index(local!band, "label", ""), backgroundColor: index(local!band, "color", "#4A5462")),
                  a!tagItem(text: index(local!st, "label", ""), backgroundColor: index(local!st, "color", "#454F5C"))
                }
              )
            }),

            /* ---- the five risk cells ---- */
            a!columnLayout(contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              tooltip: "Live from Snowflake — the model's fail probability for this trade.",
              value: {
                a!richTextItem(text: "Fail probability ", color: "#6E7885", size: "SMALL"),
                rule!SO_snowflakeMark(showWhen: true),
                char(10),
                a!richTextItem(
                  text: if(a!isNullOrEmpty(local!prob), "—", tointeger(round(100 * local!prob, 0)) & "%"),
                  color: local!tierColor, style: "STRONG", size: "MEDIUM"
                ),
                char(10),
                a!richTextItem(text: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{7f009e9f-4b6e-4372-beb0-4b155aa300d5}tradePredictions.fields.{62c6c878-1193-4cdc-848a-b073854bb077}riskTier', "") & " tier", color: local!tierColor, size: "SMALL", style: "STRONG")
              }
            )),
            a!columnLayout(contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              tooltip: "Live from Snowflake — the model's predicted fail reason.",
              value: {
                a!richTextItem(text: "Predicted reason ", color: "#6E7885", size: "SMALL"),
                rule!SO_snowflakeMark(showWhen: true),
                char(10),
                a!richTextItem(text: index(local!fr, "label", "—"), color: "#1B2330", style: "STRONG", size: "STANDARD"),
                char(10),
                a!richTextItem(text: index(local!fr, "note", ""), color: "#6E7885", size: "SMALL")
              }
            )),
            /* THE CUTOFF CELL CARRIES NO preventWrapping, AND THAT IS THE WHOLE
               FIX. It was the only one of the five that did, and the parameter
               does exactly what the docs say: "each PARAGRAPH or list item will
               truncate to a single line". A char(10) inside a rich text value
               IS a paragraph break, so the three stacked lines were collapsed
               and truncated into one — label, value and sub run together —
               while every neighbour stacked normally.

               HOW IT SURVIVED A RENDER CHECK, which is the more useful half:
               the component tree shows the three text items separately whether
               they stack or not, because the tree carries STRUCTURE and this is
               GEOMETRY. Reading three items and reporting "stacked" was reading
               the wrong evidence. The tree DOES expose preventWrapping as an
               attribute — it was checkable and was not checked. Check the
               attribute, never the item count. */
            a!columnLayout(contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "Cutoff", color: "#6E7885", size: "SMALL"),
                char(10),
                a!richTextItem(
                  text: if(local!isPast, "Past cutoff", index(local!co, "countdown", "—")),
                  color: index(local!co, "color", "#1B2330"), style: "STRONG",
                  size: if(local!isPast, "STANDARD", "MEDIUM")
                ),
                char(10),
                a!richTextItem(
                  text: if(local!isPast, "missed " & index(local!co, "atText", ""), "·  " & index(local!co, "atText", "")),
                  color: "#6E7885", size: "SMALL"
                )
              }
            )),
            a!columnLayout(contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "Value at stake", color: "#6E7885", size: "SMALL"),
                char(10),
                a!richTextItem(text: rule!SO_fmtMoney(amount: local!notional, currency: local!ccy, compact: true), color: "#1B2330", style: "STRONG", size: "STANDARD"),
                char(10),
                a!richTextItem(
                  text: if(index(local!qty, "hasQuantity", false), index(local!qty, "display", ""), "notional"),
                  color: "#6E7885", size: "SMALL"
                )
              }
            )),
            a!columnLayout(contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "Auto-release", color: "#6E7885", size: "SMALL"),
                char(10),
                a!richTextItem(text: index(local!ar, "pill", ""), color: local!laneColor, style: "STRONG", size: "STANDARD"),
                char(10),
                a!richTextItem(
                  text: if(index(local!ar, "hasScore", false), "score " & local!arScore & " · releases at " & local!arGate, "not yet scored"),
                  color: "#6E7885", size: "SMALL"
                )
              }
            ))
          }
        )
      ),

      /* ================= COLUMNS: main + rail ================= */
      a!columnsLayout(
        showWhen: local!found,
        alignVertical: "TOP",
        columns: {
          a!columnLayout(width: "AUTO", contents: {
            /* ---- 3 · TRADE & COUNTERPARTY — wholly Snowflake-served ----
               CARD-level live-read tag: every figure in this card is read live
               from Snowflake. The counterparty's 12-month fail rate additionally
               carries a FIELD-level mark because it is the one figure here the
               model reasons over. ISIN, venue and matched state come from the
               columns Scott re-synced in Designer. */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                a!sideBySideLayout(
                  alignVertical: "MIDDLE", marginBelow: "STANDARD",
                  items: {
                    a!sideBySideItem(item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(text: "TRADE & COUNTERPARTY", color: "#454F5C", size: "SMALL", style: "STRONG")
                    )),
                    a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT",
                      tooltip: "Every figure in this card is read live from Snowflake — trade, instrument and counterparty.",
                      value: {
                        rule!SO_snowflakeMark(showWhen: true),
                        a!richTextItem(text: " live read", color: "#3E7396", size: "SMALL", style: "STRONG")
                      }
                    ))
                  }
                ),
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "TRADE", color: "#9AA6B3", size: "SMALL", style: "STRONG")),
                a!columnsLayout(columns: {
                  a!columnLayout(contents: rule!SO_railFact(key: "Trade date", val: rule!SO_fmtDayDate(value: local!tradeDate), warn: false, sub: "", showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(key: "Settles", val: rule!SO_fmtDayDate(value: local!settles), sub: "T+1", warn: false, showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(key: "Desk", val: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{0653bdd6-0407-4cb1-a790-737cd07bef85}desk', "—"), warn: false, sub: "", showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(key: "Broker confirmation lag", val: local!lagText, warn: not(a!defaultValue(local!lagFits, true)), sub: "", showWhen: true))
                }),
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "SETTLEMENT", color: "#9AA6B3", size: "SMALL", style: "STRONG")),
                a!columnsLayout(columns: {
                  a!columnLayout(contents: rule!SO_railFact(key: "ISIN", val: a!defaultValue(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{81083946-31a9-4e4f-9ff0-3a0ad8881a02}isin', ""), "—"), warn: false, sub: "", showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(key: "Settles at", val: a!defaultValue(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{1e559342-6615-482d-b8d9-6da82605fbc9}csd', ""), "—"), warn: false, sub: "", showWhen: true)),
                  a!columnLayout(contents: a!localVariables(
                    local!isMatched: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{215fda37-6b90-4fe8-9e52-6018dbb2ef52}isMatched', false),
                    local!matchedAt: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{919f547f-434d-463c-a702-cecc8662376b}matchedAt', null),
                    /* ============ THE MATCHED-TIME GATE — OPENED 2026-09-24 ============
                       The 2026-09-09 ruling withheld this stamp because matchedAt is
                       Snowflake BASELINE: never re-dated by a demo run, so beside a
                       cutoff-derived settlement date it renders a year-old timestamp and
                       asserts a contradiction the screen cannot resolve. The ruling also
                       named the condition that would open the gate, and it is NOT "the
                       field is populated" — it is "a stamp exists that was AUTHORED ON
                       THIS CLOCK". Phase 5 packet trades author MATCHED_AT on their
                       relative-to-now trade date, so that condition is now satisfiable.
                       WHY A RECENCY TEST AND NOT A NULL TEST: measured 2026-09-24, every
                       row on this instance has isMatched = Y, so PRESENCE DISCRIMINATES
                       NOTHING. The seventeen fixture cases carry baseline stamps spanning
                       2023-01-10 to 2025-05-02; the three packet cases carry 2026-09-23.
                       Recency is the only signal that separates them, and the margin is
                       enormous in both directions — ~16 months to the nearest baseline
                       stamp, ~1 day to the packet ones — so a 7-day window cannot be
                       tripped by baseline data and cannot miss a packet, including a
                       packet left loaded for several days. */
                    local!stampOnThisClock: and(
                      not(a!isNullOrEmpty(local!matchedAt)),
                      todate(local!matchedAt) >= today() - 7,
                      todate(local!matchedAt) <= today()
                    ),
                    a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                    value: {
                      a!richTextItem(text: "Matched", color: "#6E7885", size: "SMALL"),
                      char(10),
                      /* Matched is a FACT WITH A CONSEQUENCE, so it is coloured:
                         an unmatched trade this close to cutoff is a second
                         problem on top of the predicted fail. */
                      a!richTextItem(
                        text: if(local!isMatched, "Yes", "No"),
                        color: if(local!isMatched, "#17715B", "#B3261E"),
                        style: "STRONG", size: "STANDARD"
                      ),
                      /* THE STAMP CARRIES ITS DAY WHENEVER IT IS NOT TODAY'S, and that
                         is the whole point rather than a detail. A packet trade matches
                         on its TRADE date and settles on the NEXT one, so the honest
                         stamp is usually yesterday's; rendering a bare "14:12" beside a
                         cutoff of today would assert that it matched this morning — a
                         fresh instance of exactly the contradiction the 2026-09-09
                         ruling removed. "d mmm hh:mm" is the mask already in service
                         elsewhere in this build, so it is known to render here. */
                      a!richTextItem(
                        showWhen: and(local!isMatched, local!stampOnThisClock),
                        text: "  ·  " & if(
                          todate(local!matchedAt) = today(),
                          text(local!matchedAt, "hh:mm"),
                          text(local!matchedAt, "d mmm hh:mm")
                        ),
                        color: "#454F5C", size: "SMALL"
                      ),
                      /* STILL WITHHELD on baseline and fixture rows. The state is the
                         decision-relevant half and is always shown; the stamp appears
                         only where it can be supported. */
                      a!richTextItem(
                        showWhen: not(local!isMatched),
                        text: "  ·  unmatched this close to cutoff",
                        color: "#B3261E", size: "SMALL"
                      )
                    }
                  ))),
                  /* THE INSTRUMENT NAME/TICKER LINE IS GONE FROM HERE — the
                     title row owns identity and repeating it inside a
                     settlement panel is noise. ASSET CLASS STAYS, because it is
                     a settlement fact rather than an identity one (it is what
                     decides the convention), and it now goes through
                     SO_assetClassDisplay: the inline title-casing this replaces
                     rendered "Fx_forward" and would have rendered "Etf". */
                  a!columnLayout(contents: rule!SO_railFact(key: "Asset class", val: rule!SO_assetClassDisplay(assetClass: local!ac), warn: false, sub: "", showWhen: true))
                }),
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "COUNTERPARTY", color: "#9AA6B3", size: "SMALL", style: "STRONG")),
                a!columnsLayout(columns: {
                  /* NAME AND REGION ARE SEPARATE LABELLED FACTS. Region was
                     riding as the Name fact's sub-line, which reads as a
                     qualifier on the name rather than as its own column. The
                     name is also the record link to SO Counterparty — accent
                     coloured, because unlike the ticker it is not the page's
                     identity and the link is the interesting thing about it. */
                  a!columnLayout(contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                    value: {
                      a!richTextItem(text: "Name", color: "#6E7885", size: "SMALL"),
                      char(10),
                      a!richTextItem(
                        text: a!defaultValue(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name', ""), "—"),
                        link: if(
                          a!isNullOrEmpty(local!cptyId),
                          null,
                          a!recordLink(recordType: 'recordType!{caca5336-9c5e-4fd9-9a75-1e5d72316dd3}SO Counterparty', identifier: local!cptyId)
                        ),
                        linkStyle: "STANDALONE",
                        color: "#2E5A88", style: "STRONG", size: "STANDARD"
                      )
                    }
                  )),
                  a!columnLayout(contents: rule!SO_railFact(key: "Region", val: local!regionDisplay, warn: false, sub: "", showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(
                    key: "Risk tier",
                    val: if(a!isNullOrEmpty(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier', "")), "—",
                      upper(left(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier', ""), 1)) & lower(mid(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier', ""), 2, 20))),
                    warn: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{9ae9a3a0-34ab-4406-9e42-26d373c6049a}riskTier', "") = "high", sub: "", showWhen: true)),
                  a!columnLayout(contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                    tooltip: "Live from Snowflake — twelve-month settlement history for this counterparty.",
                    value: {
                      a!richTextItem(text: "12-mo fail rate ", color: "#6E7885", size: "SMALL"),
                      rule!SO_snowflakeMark(showWhen: true),
                      char(10),
                      a!richTextItem(
                        text: if(a!isNullOrEmpty(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate', null)), "—",
                          text(round(100 * todecimal(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{5a121680-38f4-4c04-9da7-7babb625c638}historicalFailRate', 0)), 1), "0.0") & "%"),
                        color: "#1B2330", style: "STRONG", size: "STANDARD"
                      )
                    }
                  )),
                  /* OPS CONTACT IS TWO LINES, not a name with a phone number
                     trailing it. SO_railFact renders `sub` inline after the
                     value, which is right for "Wed 9 Sep  T+1" and wrong for a
                     name followed by a full international number: the pair is
                     the longest text in the row and ran on. Built inline here
                     so the phone gets its own line at label weight — you read
                     the name, then you dial. */
                  a!columnLayout(contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                    value: {
                      a!richTextItem(text: "Ops contact", color: "#6E7885", size: "SMALL"),
                      char(10),
                      a!richTextItem(
                        text: a!defaultValue(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{2d747fe0-1844-409a-89ef-dab3e31889b1}opsContactName', ""), "—"),
                        color: "#1B2330", style: "STRONG", size: "STANDARD"
                      ),
                      a!richTextItem(
                        showWhen: not(a!isNullOrEmpty(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{2b8e27d6-28d5-4416-9cc9-a1cffb268eb8}opsContactPhone', ""))),
                        text: char(10) & index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{2b8e27d6-28d5-4416-9cc9-a1cffb268eb8}opsContactPhone', ""),
                        color: "#454F5C", size: "SMALL"
                      )
                    }
                  ))
                })
              }
            ),

            /* ---- 4 · EXPOSURE IF FAIL — APPIAN-COMPUTED, NOT MARKED ----
               Penalty accrual and onward deliveries are computed here from
               values that happen to live in Snowflake. Marking them would claim
               Snowflake decided something it did not; the mark means
               intelligence, not residence (CLAUDE.md provenance principle). */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "EXPOSURE IF FAIL", color: "#454F5C", size: "SMALL", style: "STRONG")),
                a!columnsLayout(columns: {
                  a!columnLayout(contents: rule!SO_railFact(
                    key: "Penalty accrual (CSDR)", val: index(local!pen, "dailyDisplay", "—"), warn: true, sub: "", showWhen: true)),
                  a!columnLayout(contents: rule!SO_railFact(
                    key: "Five-day fail cost", val: index(local!pen, "fiveDayDisplay", "—"), sub: "excl. funding", warn: false, showWhen: true)),
                  a!columnLayout(contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                    value: {
                      a!richTextItem(text: "Onward deliveries", color: "#6E7885", size: "SMALL"),
                      char(10),
                      /* A PLAIN STATEMENT, not a number to re-derive — the same
                         shape SO_caseContext gives the agent. Zero is an answer
                         ("contained"), not an empty state. */
                      a!richTextItem(
                        text: if(local!onward = 0, "None next 2 cycles — contained",
                          local!onward & if(local!onward = 1, " onward sell", " onward sells") & " next 2 cycles — may cascade"),
                        color: if(local!onward = 0, "#17715B", "#B3261E"),
                        style: "STRONG", size: "STANDARD"
                      )
                    }
                  ))
                })
              }
            ),

            /* ---- 5 · RECENT SETTLEMENT FAILS — NO TIME-WINDOW CLAIM ----
               The mockup says "last 30 days · settlement history". That window
               renders EMPTY for every counterparty: SETTLEMENT_HISTORY spans
               2023-01 to 2025-07 against a 2026 system date. The card therefore
               shows the five MOST RECENT with their real dates and claims no
               window at all (TODO decision, 2026-09-02). */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                a!sideBySideLayout(
                  alignVertical: "MIDDLE", marginBelow: "STANDARD",
                  items: {
                    a!sideBySideItem(item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(
                        text: upper(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.relationships.{eab4eb75-cb43-43fc-a4a5-bea724b02294}counterparty.fields.{fe62f734-a3ee-4804-82e1-f8ca342ef25e}name', "")) & " — RECENT SETTLEMENT FAILS",
                        color: "#454F5C", size: "SMALL", style: "STRONG")
                    )),
                    a!sideBySideItem(width: "MINIMIZE", item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT",
                      tooltip: "Live from Snowflake — this counterparty's settlement history.",
                      value: {
                        rule!SO_snowflakeMark(showWhen: true),
                        a!richTextItem(text: " live read", color: "#3E7396", size: "SMALL", style: "STRONG")
                      }
                    ))
                  }
                ),
                a!richTextDisplayField(
                  showWhen: a!isNullOrEmpty(local!recentFails),
                  labelPosition: "COLLAPSED",
                  value: a!richTextItem(
                    text: "No settled fails on record for this counterparty.",
                    color: "#6E7885", size: "STANDARD"
                  )
                ),
                a!gridField(
                  showWhen: not(a!isNullOrEmpty(local!recentFails)),
                  labelPosition: "COLLAPSED",
                  data: local!recentFails,
                  spacing: "DENSE",
                  borderStyle: "LIGHT",
                  shadeAlternateRows: false,
                  /* ============ COLUMN WIDTHS — REBALANCED 2026-09-24 ============
                     Scott's browser finding: the out-of-desk label wrapped to three
                     lines, the Instrument HEADER itself wrapped, and Value hoarded
                     width. All five columns are now RELATIVE, for two documented
                     reasons. (1) "AUTO" on a grid column does NOT absorb slack — it
                     sizes to "the length of the longest unbroken value in that
                     column", so Reason at AUTO was sized by "Insufficient" while the
                     NARROW columns beside it were free to starve. (2) The docs say
                     to AVOID mixing AUTO with weighted widths, so going relative
                     means going relative everywhere. NARROW was the other half of
                     the fault: it has NO minimum width, and a fixed column is only
                     ever "at least as wide as the longest word" — and in the
                     Instrument column the longest word was the HEADER, at ten
                     unbroken characters.
                     Budget, from the longest unbroken token each column must seat:
                     Date "Sat 5 Jul" (3) · Trade "TRD026800" (9) · Instrument header
                     "Instrument" (10) · Reason "Insufficient" (12) · Value "8.3M"
                     (4). 2X/2X/3X/4X/2X of 13X gives Reason the most and no column
                     less than ~15%.
                     GEOMETRY IS NOT VERIFIABLE FROM A SESSION (CLAUDE.md §4): what
                     is verified here is the width VALUES in the render tree. One
                     line per column at laptop width is a browser check. */
                  columns: {
                    /* "Date", not "Settled". The card is headed RECENT
                       SETTLEMENT FAILS and every row in it is a fail, so a
                       column called Settled invites the reading that these
                       ones settled. */
                    a!gridColumn(label: "Date", width: "2X", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: a!richTextItem(text: rule!SO_fmtDayDate(value: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{73e751ad-433c-4555-994e-266d8aac867a}actualSettlementDate', null)), size: "STANDARD", color: "#1B2330"))),
                    /* EACH TRADE REF IS A RECORD LINK to SO Trade. NOTE THE
                       ACCESS CONSEQUENCE, which is real and not a defect here:
                       SO Trade carries desk row-security, so a fail on this
                       counterparty booked on another desk opens as "no access"
                       for alex.analyst. That is row security working, and the
                       link existing is what was asked for. */
                    a!gridColumn(label: "Trade", width: "2X", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", preventWrapping: true,
                      value: a!richTextItem(
                        text: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{bad6863a-6fd2-40f3-a5ea-b41f50235249}tradeId', ""),
                        link: if(
                          a!isNullOrEmpty(index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{bad6863a-6fd2-40f3-a5ea-b41f50235249}tradeId', "")),
                          null,
                          a!recordLink(recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade', identifier: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{bad6863a-6fd2-40f3-a5ea-b41f50235249}tradeId', ""))
                        ),
                        linkStyle: "STANDALONE",
                        size: "STANDARD", color: "#2E5A88"))),
                    /* THE CARD SAYS WHAT IT CANNOT SEE, RATHER THAN SHOWING A
                       BLANK AND A ZERO — fixed 2026-09-24, cause measured.
                       Date, trade id and fail reason come from SO Settlement
                       History, which is NOT desk-secured, so every viewer sees
                       them. Instrument and value come through the TRADE, which
                       IS desk-secured — and a counterparty's fails are spread
                       across desks by nature. So an analyst reading a broker's
                       history legitimately cannot read most of these trades.
                       MEASURED on the same case, same five rows, two identities:
                       sam.supervisor saw "ALV GY / 2.7M EUR" where alex.analyst
                       saw "— / 0". The dash was survivable; the ZERO was not —
                       it is a fabricated number in a value column, and a reader
                       has no way to tell it from a real zero. Nothing
                       distinguishes absent from invisible unless the screen says
                       so (CLAUDE.md §4), so now it says so.
                       FORM CHOSEN, and why it is this one rather than a count
                       line: for an analyst EVERY row here is usually
                       out-of-desk, so collapsing them into "5 fails you cannot
                       see" would throw away the dates and reasons she CAN see —
                       and the reason mix is the card's entire argument, the
                       thing the summary line beneath it computes. Per-row
                       labelling keeps the argument intact and hides only the two
                       cells that are genuinely unreadable.
                       preventWrapping stays OFF on this cell. The phrase is short
                       now, so it no longer needs the room — but truncation hides
                       content where wrapping only reflows it, and this is the one
                       cell whose whole job is to say something the reader cannot
                       otherwise know.
                       LABEL SHORTENED to "Other desk" 2026-09-24 (Scott, browser):
                       "outside your desk view" wrapped to THREE lines in a NARROW
                       column. The explanation it carried did not just disappear with
                       it — it moved into the card's summary line below, which now
                       names the hidden rows explicitly when there are any. A terse
                       in-cell label is only honest while something else carries the
                       full framing. */
                    a!gridColumn(label: "Instrument", width: "3X", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: if(
                        and(a!isNullOrEmpty(index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker', null)), a!isNullOrEmpty(index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', null))),
                        a!richTextItem(text: "Other desk", size: "SMALL", color: "#6E7885"),
                        a!richTextItem(text: a!defaultValue(index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker', ""), "—"), size: "STANDARD", color: "#1B2330", style: "STRONG")
                      ))),
                    a!gridColumn(label: "Reason", width: "4X", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(
                        text: index(rule!SO_failReasonDisplay(failReason: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{1174e91d-5fbc-4c99-bbeb-3d0b34db64f9}failReason', ""), short: false), "label", "—"),
                        size: "STANDARD", color: "#454F5C"))),
                    /* NEVER A FABRICATED ZERO. The old form defaulted a null
                       notional to 0 and then FORMATTED it, so an unreadable
                       trade rendered as a real-looking "0" in a money column.
                       A value the viewer cannot read is an em dash — the null
                       convention already used across these screens — and the
                       instrument cell beside it says why. */
                    a!gridColumn(label: "Value", width: "2X", align: "END", value: a!richTextDisplayField(
                      labelPosition: "COLLAPSED", align: "RIGHT", preventWrapping: true,
                      value: if(
                        a!isNullOrEmpty(index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', null)),
                        a!richTextItem(text: "—", size: "STANDARD", color: "#6E7885"),
                        a!richTextItem(
                          text: rule!SO_fmtMoney(amount: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', 0), currency: index(fv!row, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{c5b04fca-3b01-4e51-8e23-5b1ddff6376e}currency', ""), compact: true),
                          size: "STANDARD", color: "#1B2330")
                      )))
                  }
                ),
                /* The line that makes the table an ARGUMENT rather than a list:
                   how many of these fails share this case's predicted reason. */
                a!richTextDisplayField(
                  showWhen: not(a!isNullOrEmpty(local!recentFails)),
                  labelPosition: "COLLAPSED",
                  value: a!localVariables(
                    local!same: sum(a!forEach(
                      items: local!recentFails,
                      expression: if(index(fv!item, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.fields.{1174e91d-5fbc-4c99-bbeb-3d0b34db64f9}failReason', "") = index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason', ""), 1, 0)
                    )),
                    /* THE HIDDEN-ROW COUNT, added 2026-09-24 with the "Other desk"
                       label. The in-cell phrase used to be self-explanatory
                       ("outside your desk view"); shortening it for width would have
                       left the card terse ABOUT THE ONE THING IT EXISTS TO BE EXPLICIT
                       ABOUT — that nothing distinguishes absent from invisible unless
                       the screen says so (CLAUDE.md §4). The framing moved here rather
                       than disappearing. Counted with the SAME test the Instrument cell
                       uses, so the number always equals the number of "Other desk"
                       labels the reader can see. */
                    local!hidden: sum(a!forEach(
                      items: local!recentFails,
                      expression: if(and(a!isNullOrEmpty(index(fv!item, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.relationships.{2cbb6339-86b2-4618-8f47-59aa1081075e}instrument.fields.{8efffa50-ca97-41a1-94e7-301837f8f02f}ticker', null)), a!isNullOrEmpty(index(fv!item, 'recordType!{c80aeca9-1f81-4f12-864e-1a9723566d33}SO Settlement History.relationships.{68a4ae92-1d2c-4dc1-8943-5dfcb1875738}trade.fields.{80c0a476-8c55-482c-b799-e6fbec4124ab}notional', null))), 1, 0)
                    )),
                    {
                      a!richTextItem(text: count(local!recentFails) & " most recent · ", color: "#6E7885", size: "SMALL"),
                      a!richTextItem(
                        text: local!same & " of " & count(local!recentFails) & " on " & lower(index(local!fr, "label", "")),
                        color: if(local!same > 0, "#B3261E", "#6E7885"), size: "SMALL", style: "STRONG"),
                      a!richTextItem(
                        text: if(local!same > 0, " — consistent with the predicted reason on this case", " — a different pattern from this case"),
                        color: "#6E7885", size: "SMALL"),
                      /* char(10) rides INSIDE the conditional item's text, so a case
                         with nothing hidden gets no stray blank line. */
                      a!richTextItem(
                        showWhen: local!hidden > 0,
                        text: char(10) & local!hidden & " of " & count(local!recentFails)
                          & " are booked on other desks — their dates and reasons are shown, their instrument and value are not yours to read.",
                        color: "#6E7885", size: "SMALL")
                    }
                  )
                )
              }
            ),

            /* ---- 6 · ACTIVITY — the audit trail, as events ---- */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "ACTIVITY", color: "#454F5C", size: "SMALL", style: "STRONG")),
                a!richTextDisplayField(
                  showWhen: a!isNullOrEmpty(local!events),
                  labelPosition: "COLLAPSED",
                  value: a!richTextItem(text: "No activity recorded on this case yet.", color: "#6E7885", size: "STANDARD")
                ),
                a!forEach(
                  items: local!events,
                  expression: a!localVariables(
                    /* WHO acted. An event with no user is the platform acting —
                       the triage lane runs unattended — so it is attributed to
                       the system or the agent rather than silently to nobody.
                       The AI chip is the same governance mark the assessment
                       card carries: machine-authored entries say so. */
                    /* ATTRIBUTION IS BY EVENT TYPE, not by keyword search on
                       the event name. The substring version got two of the
                       seven types wrong: "Straight-Through Resolution" and
                       "Escalated" are AGENT DECISIONS and were being chipped
                       SYS, which credits the machine's judgement to plumbing.
                       The rule, in one line: anything a person did is USR;
                       otherwise the three decision types are AI and the
                       mechanical writes (Case Created) are SYS. */
                    local!noUser: a!isNullOrEmpty(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', null)),
                    local!isAgent: and(
                      local!noUser,
                      contains(
                        { "Agent Triage Complete", "Straight-Through Resolution", "Escalated" },
                        index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName', "")
                      )
                    ),
                    a!sideBySideLayout(
                      alignVertical: "TOP",
                      marginBelow: "STANDARD",
                      items: {
                        a!sideBySideItem(width: "MINIMIZE", item: a!tagField(
                          labelPosition: "COLLAPSED",
                          tags: a!tagItem(
                            text: if(local!isAgent, "AI", if(local!noUser, "SYS", "USR")),
                            backgroundColor: if(local!isAgent, "#E7F0F6", if(local!noUser, "#ECEFF3", "#E4EDE6")),
                            textColor: if(local!isAgent, "#3E7396", if(local!noUser, "#4A5462", "#17715B"))
                          )
                        )),
                        a!sideBySideItem(item: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName', "Event"), color: "#1B2330", size: "STANDARD", style: "STRONG"),
                            a!richTextItem(
                              text: "   " & text(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp', null), "d mmm hh:mm")
                                & if(local!noUser, "", "  ·  " & user(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', null), "firstName") & " " & user(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user', null), "lastName")),
                              color: "#6E7885", size: "SMALL"),
                            a!richTextItem(
                              showWhen: not(a!isNullOrEmpty(index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6862ba51-9181-470c-8798-9bfd1cabc8bb}comment', ""))),
                              text: char(10) & index(fv!item, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6862ba51-9181-470c-8798-9bfd1cabc8bb}comment', ""),
                              color: "#454F5C", size: "SMALL")
                          }
                        ))
                      }
                    )
                  )
                )
              }
            )
          }),
          a!columnLayout(width: "MEDIUM_PLUS", contents: {
            /* ---- 7a · AGENT ASSESSMENT — the standalone record ----
               THE FULL PROSE, identity opening included. The watchlist rail
               excerpts and skips that opening because its header just said the
               identity; here the assessment IS the record and must identify its
               own subject. Same text, different obligation — and the reason the
               rail's excerpt logic lives in the rail and not in a shared rule.

               AI ATTRIBUTION heads the card: chip + agent + run time. A screen
               that renders machine-authored reasoning without saying so is
               making an implicit claim about its provenance. */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                /* THE ATTRIBUTION ONLY APPEARS WHERE THERE IS AGENT CONTENT
                   TO ATTRIBUTE. On an untriaged case the chip would name an
                   agent that has not run and stamp a time that does not exist —
                   claiming provenance for nothing, which is the same class of
                   error as claiming none for something. */
                a!sideBySideLayout(
                  showWhen: local!scored,
                  alignVertical: "MIDDLE", marginBelow: "STANDARD",
                  items: {
                    a!sideBySideItem(width: "MINIMIZE", item: a!tagField(
                      labelPosition: "COLLAPSED",
                      tags: a!tagItem(text: "AI", backgroundColor: "#E7F0F6", textColor: "#3E7396")
                    )),
                    a!sideBySideItem(item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(
                        text: "SO Triage Agent"
                          & if(a!isNullOrEmpty(local!assessmentAt), "", "  ·  " & text(local!assessmentAt, "d mmm hh:mm")),
                        color: "#6E7885", size: "SMALL"
                      )
                    ))
                  }
                ),

                /* NOT YET SCORED collapses the card to one line — no lane, no
                   bar, no empty prose frame. A case that has not been triaged
                   has no assessment, and rendering the frame around an absent
                   one reads as a broken screen. */
                a!richTextDisplayField(
                  showWhen: not(local!scored),
                  labelPosition: "COLLAPSED",
                  value: {
                    a!richTextItem(text: "AGENT ASSESSMENT", color: "#454F5C", size: "SMALL", style: "STRONG"),
                    char(10),
                    a!richTextItem(text: "Not yet scored", color: "#6E7885", style: "STRONG", size: "STANDARD"),
                    char(10),
                    a!richTextItem(
                      text: "Triage has not run on this case yet.",
                      color: "#6E7885", size: "SMALL"
                    )
                  }
                ),

                a!richTextDisplayField(
                  showWhen: local!scored,
                  labelPosition: "COLLAPSED",
                  marginBelow: "STANDARD",
                  value: a!richTextItem(text: local!assessmentText, color: "#1B2330", size: "STANDARD")
                ),
                rule!SO_railFact(
                  showWhen: local!scored,
                  key: "Proposed remediation",
                  val: a!defaultValue(index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation', ""), "—"),
                  warn: false, sub: ""
                ),
                a!columnsLayout(
                  showWhen: local!scored,
                  columns: {
                    a!columnLayout(contents: rule!SO_railFact(
                      key: "Urgency",
                      val: a!defaultValue(index(rule!SO_remediationForReason(failReason: index(local!c, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason', "")), "urgency", ""), "—"),
                      warn: true, sub: "", showWhen: true)),
                    a!columnLayout(contents: rule!SO_railFact(
                      key: "Escalation",
                      val: if(local!lane = "ESCALATED", "Required", "Not required"),
                      warn: local!lane = "ESCALATED", sub: "", showWhen: true))
                  }
                ),
                /* THE LANE FROM THE STORED DECISION, four branches, never
                   re-derived from the score — a reason override escalates a
                   high-scoring case, and a score-derived lane once announced
                   "Released without touch" beside an Escalated chip. */
                a!richTextDisplayField(
                  showWhen: local!scored,
                  labelPosition: "COLLAPSED",
                  marginBelow: "STANDARD",
                  value: {
                    a!richTextItem(text: index(local!ar, "pill", ""), color: local!laneColor, size: "STANDARD", style: "STRONG"),
                    a!richTextItem(text: char(10), showWhen: index(local!ar, "hasScore", false)),
                    a!richTextItem(text: "Auto-release score ", color: "#454F5C", size: "STANDARD", showWhen: index(local!ar, "hasScore", false)),
                    a!richTextItem(text: local!arScore, color: "#1B2330", size: "STANDARD", style: "STRONG", showWhen: index(local!ar, "hasScore", false)),
                    a!richTextItem(text: ", releases at " & local!arGate, color: "#454F5C", size: "STANDARD", showWhen: index(local!ar, "hasScore", false)),
                    a!richTextItem(text: char(10), showWhen: not(a!isNullOrEmpty(index(local!ar, "laneNote", "")))),
                    a!richTextItem(text: index(local!ar, "laneNote", ""), color: "#454F5C", size: "SMALL",
                      showWhen: not(a!isNullOrEmpty(index(local!ar, "laneNote", ""))))
                  }
                ),
                /* THE ONE GLYPH BAR ON THIS SCREEN, and the exception is
                   earned: a native progress bar cannot draw the gate marker on
                   the track, and the gate is the whole point of this bar. 24
                   cells here rather than the rail's 16 — this column is wider —
                   with preventWrapping so it can never break across lines. */
                a!richTextDisplayField(
                  showWhen: and(local!scored, index(local!ar, "hasScore", false)),
                  labelPosition: "COLLAPSED",
                  preventWrapping: true,
                  marginBelow: "STANDARD",
                  value: a!forEach(
                    items: enumerate(local!arCells) + 1,
                    expression: a!richTextItem(
                      text: if(fv!item = local!arGateCell, "┃", "▇"),
                      color: if(fv!item = local!arGateCell, "#1B2330",
                        if(fv!item <= local!arFill, local!laneColor, "#E9EDF2"))
                    )
                  )
                ),
                /* GROUNDING FOOTER — what the reasoning was built on. */
                a!richTextDisplayField(
                  showWhen: local!scored,
                  labelPosition: "COLLAPSED",
                  value: {
                    rule!SO_snowflakeMark(showWhen: true),
                    a!richTextItem(
                      text: " Grounded in live Snowflake reads — trade · prediction · counterparty history",
                      color: "#6E7885", size: "SMALL"
                    )
                  }
                )
              }
            ),

            /* ---- 7b · TIMING — two native bars on one shared scale ---- */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
              contents: {
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: a!richTextItem(text: "TIMING", color: "#454F5C", size: "SMALL", style: "STRONG")),
                a!richTextDisplayField(
                  showWhen: local!isPast,
                  labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: {
                    a!richTextItem(text: "Past cutoff", color: "#B3261E", style: "STRONG", size: "STANDARD"),
                    a!richTextItem(text: " — fail management, not remediation.", color: "#1B2330", size: "STANDARD")
                  }
                ),
                rule!SO_railFact(showWhen: local!isPast, key: "Broker confirmation lag", val: local!lagText, warn: false, sub: ""),
                a!progressBarField(
                  showWhen: not(local!isPast),
                  label: "Remaining to cutoff   " & index(local!co, "countdown", ""),
                  labelPosition: "ABOVE",
                  percentage: tointeger(max({ 0, min({ 100, tointeger(round(100 * local!hrsLeft / local!scaleMax, 0)) }) })),
                  color: index(local!co, "color", "#2E5A88"), style: "THIN", showPercentage: false, marginBelow: "STANDARD"
                ),
                a!progressBarField(
                  showWhen: not(local!isPast),
                  label: "Broker confirmation lag   " & local!lagText,
                  labelPosition: "ABOVE",
                  percentage: tointeger(max({ 0, min({ 100, tointeger(round(100 * local!lag / local!scaleMax, 0)) }) })),
                  color: "#96590A", style: "THIN", showPercentage: false, marginBelow: "STANDARD"
                ),
                a!richTextDisplayField(
                  showWhen: not(local!isPast),
                  labelPosition: "COLLAPSED",
                  value: if(
                    a!isNullOrEmpty(local!lagFits),
                    a!richTextItem(text: "Timing cannot be assessed — the trade has no confirmation lag or no cutoff recorded.", color: "#6E7885", size: "STANDARD"),
                    if(
                      local!lagFits,
                      {
                        a!richTextItem(text: "Fits the window", color: "#17715B", style: "STRONG", size: "STANDARD"),
                        a!richTextItem(
                          text: " — confirmation takes " & text(round(local!lag, 1), "0.0") & "h against "
                            & text(round(local!hrsLeft, 1), "0.0") & "h remaining, completing about "
                            & text(round(local!hrsLeft - local!lag, 1), "0.0") & "h before cutoff.",
                          color: "#1B2330", size: "STANDARD")
                      },
                      {
                        a!richTextItem(text: "Does not fit the window", color: "#B3261E", style: "STRONG", size: "STANDARD"),
                        a!richTextItem(
                          text: " — confirmation takes " & text(round(local!lag, 1), "0.0") & "h against only "
                            & text(round(local!hrsLeft, 1), "0.0") & "h remaining, so the remediation cannot complete before cutoff.",
                          color: "#1B2330", size: "STANDARD")
                      }
                    )
                  )
                )
              }
            ),

            /* ---- 7c · ASK — PHASE 6 SHELL, DELIBERATELY INERT ----
               The box and the button are here so the screen's shape is final
               and the Act 2 beat has a home, but nothing is wired: no Cortex
               call, no MCP tool, no saveInto that does anything. It is
               disabled, so it cannot pretend to work.

               NO WIRING NOTE ON SCREEN. It used to carry "Wired in Phase 6 —
               questions will run against the Snowflake semantic model", which
               is a message from the build to itself: it tells a client which
               parts of their demo are unfinished and names an internal phase
               number to do it. Build state belongs in build-log.md and TODO.md.
               The disabled field and its example question are the whole
               placeholder. */
            a!cardLayout(
              padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
              contents: {
                a!richTextDisplayField(labelPosition: "COLLAPSED", marginBelow: "STANDARD",
                  value: {
                    a!richTextItem(text: "ASK ABOUT THIS CASE   ", color: "#454F5C", size: "SMALL", style: "STRONG"),
                    rule!SO_snowflakeMark(showWhen: true)
                  }),
                a!textField(
                  labelPosition: "COLLAPSED",
                  placeholder: "e.g. How often has this counterparty failed on sells this size?",
                  value: null,
                  saveInto: {},
                  disabled: true,
                  marginBelow: "NONE"
                )
              }
            )
          })
        }
      )
    }
  )
)
