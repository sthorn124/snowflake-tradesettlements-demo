/*
 * SO_remediationForCase — what SO_remediationForReason returns for one case,
 * with the side of the trade read by the caller's own query. Written once.
 *
 * Reads the case's fail reason and, through the case's trade, its direction,
 * instrument and expected settlement date; counts the onward deliveries with
 * rule!SO_onwardDeliveries; and hands all three to rule!SO_remediationForReason.
 * Returns that rule's map unchanged: remediation, urgency, stDisposition.
 *
 * WHY IT EXISTS (2026-11-13, prompts/006 round 2). THE PROCESS IS THE AUTHORITY
 * FOR THE REMEDIATION A CASE STORES. Until then SO_triageCase node 11 stored the
 * text the agent returned and asked the rule only for the straight-through
 * code, with the fail reason alone. The agent calls the same rule as its
 * propose_remediation tool, but whether it passes the direction on a given run
 * is the agent's choice. Node 11 now reads this rule for both the text and the
 * code, so what is stored does not depend on what the agent passed. The agent's
 * tool call gives the agent the same text to reason about.
 *
 * Two outputs of node 11 call it. Both pass pv!caseId, so they cannot disagree.
 *
 * SCOPE (supplemental §5): the trade is read as the calling account. A caller
 * that cannot see the case's trade gets no direction, and the rule then returns
 * what it returns with no direction. SO_triageCase runs as its initiator, who
 * holds SO Supervisors for a demo run (project.md, Demo Admin site).
 *
 * Null-safe: no case id, or no such case, returns the rule's answer for an
 * unknown reason (Manual review, no straight-through code). It never errors.
 */
a!localVariables(
  local!fReason: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
  local!fDir: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
  local!fInstr: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId',
  local!fEsd: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate',

  local!c: if(
    a!isNullOrEmpty(ri!caseId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
        fields: { local!fReason, local!fDir, local!fInstr, local!fEsd },
        filters: a!queryFilter(
          field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
          operator: "=",
          value: ri!caseId
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!found: not(a!isNullOrEmpty(local!c)),
  local!direction: if(local!found, local!c[local!fDir], null),
  /* SO_onwardDeliveries returns 0 for a missing instrument or date */
  local!onward: if(
    local!found,
    rule!SO_onwardDeliveries(instrumentId: local!c[local!fInstr], settlementDate: local!c[local!fEsd]),
    0
  ),

  rule!SO_remediationForReason(
    failReason: if(local!found, local!c[local!fReason], null),
    direction: local!direction,
    onwardDeliveries: local!onward
  )
)
