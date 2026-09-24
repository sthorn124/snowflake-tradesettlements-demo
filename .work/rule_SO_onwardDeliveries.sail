/*
 * SO_onwardDeliveries — how many of OUR sells in the same instrument settle in
 * the next two cycles after this trade's settlement date.
 *
 * Why it matters: an incoming delivery that fails can cascade. If we have sold
 * the same line onward and those sells settle immediately after, a shortfall
 * here becomes a shortfall there. Zero onward deliveries means a fail is
 * contained to one settlement; a non-zero count means it is not.
 *
 * "Two cycles" is modelled as the two calendar days following settlementDate —
 * exclusive of the date itself (same-day sells are not onward) and inclusive of
 * the second day. Calendar rather than business days is a deliberate demo
 * simplification: the dataset carries no settlement calendar, and over a two-day
 * window the difference only appears across a weekend.
 *
 * SELL side only, and same instrument only — a sell of a different line does not
 * depend on this delivery.
 *
 * SCOPE WARNING (§5): this counts trades the CALLING ACCOUNT can see. Under
 * desk-scoped row security an analyst's count is their desk's onward deliveries,
 * not the firm's. That is the right answer for an analyst screen and the wrong
 * one for a firm-wide risk number; do not reuse this rule for the latter.
 *
 * Null-safe: a missing instrument or date returns 0 rather than erroring, so it
 * is safe on a case whose trade could not be read.
 */
a!localVariables(
  local!fTradeId: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{df193874-a122-4695-9c9f-a321512a1f6d}tradeId',
  local!fInstr:   'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId',
  local!fDir:     'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
  local!fEsd:     'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate',

  local!rows: if(
    or(a!isNullOrEmpty(ri!instrumentId), a!isNullOrEmpty(ri!settlementDate)),
    {},
    a!queryRecordType(
      recordType: 'recordType!{8539c3b7-b402-4ba9-b5a0-e8c09a4980bd}SO Trade',
      fields: { local!fTradeId },
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: local!fInstr, operator: "=",  value: ri!instrumentId),
          a!queryFilter(field: local!fDir,   operator: "=",  value: "SELL"),
          a!queryFilter(field: local!fEsd,   operator: ">",  value: ri!settlementDate),
          a!queryFilter(field: local!fEsd,   operator: "<=", value: ri!settlementDate + 2)
        }
      ),
      /* batchSize 500, counted from .data — .totalCount returns -1 at small
         batch sizes and would silently answer a different question (§4). */
      pagingInfo: a!pagingInfo(1, 500)
    ).data
  ),

  if(a!isNullOrEmpty(local!rows), 0, count(local!rows))
)
