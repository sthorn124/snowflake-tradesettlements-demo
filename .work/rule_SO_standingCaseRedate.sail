/*
 * SO_standingCaseRedate — the stamps and the record values for one re-date of
 * the standing cases, from the offsets in SO_standingCaseOffsets.
 *
 * ONE CLOCK. Every stamp is an offset from ri!clock. With no clock passed, the
 * clock is now, rounded down to the hour in UTC. The process works it out once
 * and passes the same value to all three writes, so a run that crosses the hour
 * cannot date its tables on two clocks, and a second run in the same hour
 * writes the same values again.
 *
 * THE CLOCK IS BUILT FROM WHOLE NUMBERS, NOT FROM A FRACTION OF A DAY AND NOT
 * FROM intervalds(hours): intervalds() wraps past about 24.8 days (measured
 * 2026-11-12: 7,566 hours came back as 17 days), and a day fraction is not
 * exact to the second. Minute offsets here stay under two days, where
 * intervalds() is exact.
 *
 * EVERY WRITE NAMES ITS IDS. `missing` lists any id in the table that this
 * account cannot read on the site; the process writes nothing unless it is
 * empty, because Write Records re-creates an id that no longer exists as a
 * blank row (measured 2026-11-12).
 *
 * No event is written for a re-date: it is maintenance, not a business change.
 */
a!localVariables(
  local!t: rule!SO_standingCaseOffsets(),
  local!anchor: datetime(2026, 1, 1, 0, 0, 0),
  local!hoursSince: tointeger(floor(24 * (todecimal(now()) - todecimal(local!anchor)) + 0.000001)),
  local!day: date(2026, 1, 1) + tointeger(floor(local!hoursSince / 24)),
  local!clock: if(
    a!isNullOrEmpty(ri!clock),
    datetime(year(local!day), month(local!day), day(local!day), mod(local!hoursSince, 24), 0, 0),
    ri!clock
  ),

  /* per case: every stamp, in minutes from the clock */
  local!plan: a!forEach(
    items: local!t.cases,
    expression: a!localVariables(
      local!triage: tointeger(min(local!t.triageMin, fv!item.cutoffMin - local!t.triageBeforeCutoffMin)),
      a!map(
        caseId: fv!item.caseId,
        cutoffTs: local!clock + intervalds(0, fv!item.cutoffMin, 0),
        triageAt: local!clock + intervalds(0, local!triage, 0),
        triageMin: local!triage,
        createdOn: local!clock + intervalds(0, local!triage - local!t.createdBeforeTriageMin, 0),
        resolvedOn: if(a!isNullOrEmpty(fv!item.resolvedMin), null, local!clock + intervalds(0, fv!item.resolvedMin, 0))
      )
    )
  ),
  local!planIds: a!forEach(items: local!plan, expression: fv!item.caseId),
  local!commentPlan: a!forEach(
    items: local!t.comments,
    expression: a!map(
      id: fv!item.id,
      caseId: fv!item.caseId,
      createdOn: index(local!plan, index(wherecontains(fv!item.caseId, local!planIds), 1, 0), null).triageAt
    )
  ),
  local!eventPlan: a!forEach(
    items: local!t.events,
    expression: a!map(
      id: fv!item.id,
      caseId: fv!item.caseId,
      timestamp: local!clock + intervalds(
        0,
        index(local!plan, index(wherecontains(fv!item.caseId, local!planIds), 1, 0), null).triageMin + fv!item.afterTriageMin,
        0
      )
    )
  ),

  /* what the site holds, read by the ids in the table and by nothing else */
  local!commentIds: a!forEach(items: local!commentPlan, expression: fv!item.id),
  local!eventIds: a!forEach(items: local!eventPlan, expression: fv!item.id),
  local!foundCases: a!forEach(
    items: a!queryRecordType(recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case', fields: { 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID' },
      filters: a!queryFilter(field: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID', operator: "in", value: local!planIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)).data,
    expression: tointeger(fv!item['recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID'])
  ),
  local!foundComments: a!forEach(
    items: a!queryRecordType(recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment', fields: { 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{fe1abf25-394d-44ad-a3d6-3903b1f3012c}id', 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId' },
      filters: a!queryFilter(field: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{fe1abf25-394d-44ad-a3d6-3903b1f3012c}id', operator: "in", value: local!commentIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)).data,
    expression: fv!item['recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{fe1abf25-394d-44ad-a3d6-3903b1f3012c}id'] & ":" & fv!item['recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId']
  ),
  local!foundEvents: a!forEach(
    items: a!queryRecordType(recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History', fields: { 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8}id', 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId' },
      filters: a!queryFilter(field: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8}id', operator: "in", value: local!eventIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)).data,
    expression: fv!item['recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8}id'] & ":" & fv!item['recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId']
  ),
  local!missingCases: a!flatten(a!forEach(items: local!planIds, expression:
    if(contains(a!flatten({ -1, local!foundCases }), fv!item), {}, "case " & fv!item))),
  local!missingComments: a!flatten(a!forEach(items: local!commentPlan, expression:
    if(contains(a!flatten({ "-", local!foundComments }), fv!item.id & ":" & fv!item.caseId), {}, "comment " & fv!item.id & " on case " & fv!item.caseId))),
  local!missingEvents: a!flatten(a!forEach(items: local!eventPlan, expression:
    if(contains(a!flatten({ "-", local!foundEvents }), fv!item.id & ":" & fv!item.caseId), {}, "event " & fv!item.id & " on case " & fv!item.caseId))),
  local!missing: a!flatten({ local!missingCases, local!missingComments, local!missingEvents }),

  a!map(
    clock: local!clock,
    clockUtc: text(gmt(local!clock), "yyyy-mm-dd hh:mm") & " UTC",
    caseCount: count(local!planIds),
    commentCount: count(local!commentIds),
    eventCount: count(local!eventIds),
    missing: if(a!isNullOrEmpty(local!missing), "", joinarray(local!missing, "; ")),
    caseRecords: a!forEach(
      items: local!plan,
      expression: if(
        a!isNullOrEmpty(fv!item.resolvedOn),
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case'('recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID': fv!item.caseId, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs': fv!item.cutoffTs, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn': fv!item.createdOn, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4ac3036c-ab51-4940-a5d5-363e4f2a8a09}modifiedOn': fv!item.triageAt),
        'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case'('recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID': fv!item.caseId, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs': fv!item.cutoffTs, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{10200e99-176e-44ce-a5dc-3c5c45847da5}createdOn': fv!item.createdOn, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4ac3036c-ab51-4940-a5d5-363e4f2a8a09}modifiedOn': fv!item.triageAt, 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{a0a31026-e28d-4526-9c51-19b314a2fb33}resolvedOn': fv!item.resolvedOn)
      )
    ),
    commentRecords: a!forEach(items: local!commentPlan, expression: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment'('recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{fe1abf25-394d-44ad-a3d6-3903b1f3012c}id': fv!item.id, 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{4143f703-c044-40d9-a2fd-927d6a67795d}createdOn': fv!item.createdOn)),
    eventRecords: a!forEach(items: local!eventPlan, expression: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History'('recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8}id': fv!item.id, 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{2997cf09-138c-489d-a6ff-221de2e77243}timestamp': fv!item.timestamp)),
    /* the same stamps as text in UTC, one line per row, for checking a run */
    expected: a!flatten({
      a!forEach(items: local!plan, expression: "case " & fv!item.caseId
        & " cutoff=" & text(gmt(fv!item.cutoffTs), "yyyy-mm-dd hh:mm:ss")
        & " created=" & text(gmt(fv!item.createdOn), "yyyy-mm-dd hh:mm:ss")
        & " modified=" & text(gmt(fv!item.triageAt), "yyyy-mm-dd hh:mm:ss")
        & " resolved=" & if(a!isNullOrEmpty(fv!item.resolvedOn), "", text(gmt(fv!item.resolvedOn), "yyyy-mm-dd hh:mm:ss"))),
      a!forEach(items: local!commentPlan, expression: "comment " & fv!item.id & " created=" & text(gmt(fv!item.createdOn), "yyyy-mm-dd hh:mm:ss")),
      a!forEach(items: local!eventPlan, expression: "event " & fv!item.id & " at=" & text(gmt(fv!item.timestamp), "yyyy-mm-dd hh:mm:ss"))
    })
  )
)
