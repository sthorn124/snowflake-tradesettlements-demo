/* zz_SO_p006_rows — THROWAWAY (prompts/006). Compact text for a list of case ids:
   the case row, its trade's side and onward deliveries, what the remediation
   rule returns for it now, its comments and its events. */
a!localVariables(
  local!rtCase: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
  local!fId: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{4712df58-1d47-4398-b6f8-16d0f00531b3}caseID',
  local!fTrade: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e030ef7d-9626-47f2-90ca-fe586a435e6f}tradeID',
  local!fSess: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{1f2150e5-7908-447c-a9a7-0483983c6693}sessionID',
  local!fStatus: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{b45a436e-95b4-4c9e-9808-65e017cb446b}status',
  local!fReason: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason',
  local!fRem: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{e88be2f5-7e27-4912-b941-278f50414fc7}proposedRemediation',
  local!fScore: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{fe73bdaa-5959-4ca5-97e9-82ccf8d7ade1}confidenceScore',
  local!fDisp: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{c01cfb58-c4ed-4c25-82b2-d819b8bc8952}disposition',
  local!fAssignee: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.fields.{9b25abd4-5dde-4c5b-805d-b9968401cf9c}assignee',
  local!fDir: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{bfa7d560-8c0e-49a4-8750-f72d72b461fa}direction',
  local!fInstr: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{ab1d7c5c-9805-4a90-ac41-ddaefa115c18}instrumentId',
  local!fEsd: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{5ba48c43-245c-40d7-8cfb-62f44526cb09}expectedSettlementDate',
  local!cId: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{fe1abf25-394d-44ad-a3d6-3903b1f3012c}id',
  local!cCase: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{387260a3-561d-4cd3-9df7-d65a5cc775b6}caseId',
  local!cText: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{2bb72559-6a2b-4624-b156-efc8237287ce}commentText',
  local!cAuthor: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment.fields.{ffa2f4eb-64b5-4a09-9f05-85fcd3f24d04}author',
  local!eId: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6a72c7d1-2c74-4a71-a21d-7c58c0b2e1f8}id',
  local!eRec: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId',
  local!eText: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{6862ba51-9181-470c-8798-9bfd1cabc8bb}comment',
  local!eUser: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.fields.{c4acbfe1-23ab-4f68-9874-464b794d360b}user',
  local!eName: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History.relationships.{b87d38c6-5839-454c-aafa-32fb0b88c887}eventType.fields.{fd5aa5de-b897-46db-97ba-1cb2e37370a3}eventName',
  local!max: if(a!isNullOrEmpty(ri!textLimit), 4000, ri!textLimit),

  joinarray(
    a!forEach(
      items: ri!caseIds,
      expression: a!localVariables(
        local!id: fv!item,
        local!c: index(a!queryRecordType(
          recordType: local!rtCase,
          fields: { local!fId, local!fTrade, local!fSess, local!fStatus, local!fReason, local!fRem, local!fScore, local!fDisp, local!fAssignee, local!fDir, local!fInstr, local!fEsd },
          filters: a!queryFilter(field: local!fId, operator: "=", value: local!id),
          pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
        ).data, 1, null),
        local!onward: if(a!isNullOrEmpty(local!c), null, rule!SO_onwardDeliveries(instrumentId: local!c[local!fInstr], settlementDate: local!c[local!fEsd])),
        local!now: if(a!isNullOrEmpty(local!c), null, rule!SO_remediationForReason(failReason: local!c[local!fReason], direction: local!c[local!fDir], onwardDeliveries: local!onward)),
        local!comments: a!queryRecordType(
          recordType: 'recordType!{c8cdbb02-1f27-4a90-933b-752f65b0f617}SO Case Comment',
          fields: { local!cId, local!cText, local!cAuthor },
          filters: a!queryFilter(field: local!cCase, operator: "=", value: local!id),
          pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: local!cId, ascending: true))
        ).data,
        local!events: a!queryRecordType(
          recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
          fields: { local!eId, local!eText, local!eUser, local!eName },
          filters: a!queryFilter(field: local!eRec, operator: "=", value: local!id),
          pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: local!eId, ascending: true))
        ).data,
        if(
          a!isNullOrEmpty(local!c),
          "CASE " & local!id & ": NOT FOUND | comments readable " & length(local!comments) & " | events readable " & length(local!events),
          "CASE " & local!id & " | " & local!c[local!fTrade] & " | " & local!c[local!fSess] & " | " & local!c[local!fStatus]
            & " | " & local!c[local!fReason] & " | " & a!defaultValue(local!c[local!fDir], "(no direction)") & " | onward " & local!onward
            & " | stored: " & a!defaultValue(local!c[local!fRem], "(none)")
            & " | rule now: " & local!now.remediation & " / " & a!defaultValue(local!now.stDisposition, "(null)")
            & " | score " & a!defaultValue(tostring(local!c[local!fScore]), "(none)")
            & " | disposition " & a!defaultValue(local!c[local!fDisp], "(none)")
            & " | assignee " & a!defaultValue(tostring(local!c[local!fAssignee]), "(none)")
            & if(a!defaultValue(local!c[local!fRem], "") = local!now.remediation, "", if(a!isNullOrEmpty(local!c[local!fRem]), "", " | DIFFERS"))
        )
        & joinarray(a!forEach(items: local!comments, expression:
            char(10) & "  comment " & fv!item[local!cId] & " [" & a!defaultValue(tostring(fv!item[local!cAuthor]), "agent") & "] " & left(a!defaultValue(fv!item[local!cText], ""), local!max)
          ), "")
        & joinarray(a!forEach(items: local!events, expression:
            char(10) & "  event " & fv!item[local!eId] & " [" & a!defaultValue(fv!item[local!eName], "?") & " / " & a!defaultValue(tostring(fv!item[local!eUser]), "no user") & "] " & left(a!defaultValue(fv!item[local!eText], ""), local!max)
          ), "")
      )
    ),
    char(10)
  )
)
