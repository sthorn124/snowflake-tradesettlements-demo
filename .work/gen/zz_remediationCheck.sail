/* zz_SO_p006_check — throwaway (prompts/006), version 2: the LIVE rule against the table, and against an inline copy of the rule as it was before 2026-11-13. Truth table for the side-aware
   remediation rule and for SO_failSide. ri!control true flips one expectation,
   so the harness must then report exactly one FAIL. */
a!localVariables(
  local!borrow: "Arrange cover borrow / partial release",
  local!borrowOnward: "Arrange cover borrow for onward deliveries / accept partial delivery",
  local!partial: if(a!defaultValue(ri!control, false), "Accept partial delivery", "Accept partial delivery / chase counterparty"),
  local!treasury: "Treasury funding chase",
  local!chase: "Chase counterparty for funding",
  local!rows: {
    a!map(r: "insufficient_securities", d: "SELL", o: 0, rem: local!borrow, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "insufficient_securities", d: "SELL", o: 3, rem: local!borrow, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "insufficient_securities", d: "SELL", o: null, rem: local!borrow, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "insufficient_securities", d: "BUY", o: 1, rem: local!borrowOnward, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "insufficient_securities", d: "BUY", o: 4, rem: local!borrowOnward, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "insufficient_securities", d: "BUY", o: 0, rem: local!partial, u: "HIGH", st: "Settled - Partial Release"),
    a!map(r: "insufficient_securities", d: "BUY", o: null, rem: "Accept partial delivery / chase counterparty", u: "HIGH", st: "Settled - Partial Release"),
    a!map(r: "funding_gap", d: "BUY", o: 0, rem: local!treasury, u: "HIGH", st: "Settled - Funding Received"),
    a!map(r: "funding_gap", d: "BUY", o: 2, rem: local!treasury, u: "HIGH", st: "Settled - Funding Received"),
    a!map(r: "funding_gap", d: "SELL", o: 0, rem: local!chase, u: "HIGH", st: "Settled - Funding Received"),
    a!map(r: "funding_gap", d: "SELL", o: 2, rem: local!chase, u: "HIGH", st: "Settled - Funding Received"),
    a!map(r: "counterparty_default", d: "BUY", o: 0, rem: "Credit-risk escalation", u: "CRITICAL", st: null),
    a!map(r: "counterparty_default", d: "SELL", o: 2, rem: "Credit-risk escalation", u: "CRITICAL", st: null),
    a!map(r: "operational_error", d: "BUY", o: 0, rem: "Correct & resubmit", u: "MEDIUM", st: "Settled - Corrected"),
    a!map(r: "operational_error", d: "SELL", o: 2, rem: "Correct & resubmit", u: "MEDIUM", st: "Settled - Corrected"),
    a!map(r: "something_else", d: "BUY", o: 0, rem: "Manual review", u: "MEDIUM", st: null),
    a!map(r: null, d: "SELL", o: 1, rem: "Manual review", u: "MEDIUM", st: null),
    a!map(r: "insufficient_securities", d: "buy", o: 0, rem: "Accept partial delivery / chase counterparty", u: "HIGH", st: "Settled - Partial Release"),
    a!map(r: "funding_gap", d: " sell ", o: 0, rem: local!chase, u: "HIGH", st: "Settled - Funding Received"),
    a!map(r: "insufficient_securities", d: "HOLD", o: 0, rem: local!borrow, u: "HIGH", st: "Settled - Borrow Executed"),
    a!map(r: "funding_gap", d: "HOLD", o: 2, rem: local!treasury, u: "HIGH", st: "Settled - Funding Received")
  },
  local!tableLines: a!forEach(
    items: local!rows,
    expression: a!localVariables(
      local!got: rule!SO_remediationForReason(failReason: fv!item.r, direction: fv!item.d, onwardDeliveries: fv!item.o),
      local!ok: and(
        tostring(local!got.remediation) = fv!item.rem,
        tostring(local!got.urgency) = fv!item.u,
        a!defaultValue(local!got.stDisposition, "(null)") = a!defaultValue(fv!item.st, "(null)")
      ),
      if(local!ok, "PASS", "FAIL") & " | " & a!defaultValue(fv!item.r, "(null)") & " | " & fv!item.d & " | " & a!defaultValue(tostring(fv!item.o), "(null)")
        & " -> " & local!got.remediation & " | " & local!got.urgency & " | " & a!defaultValue(local!got.stDisposition, "(null)")
    )
  ),
  /* with no direction the new body must equal the live rule, key for key */
  local!reasons: { "insufficient_securities", "funding_gap", "counterparty_default", "operational_error", "something_else", "" },
  local!noDirLines: a!forEach(
    items: local!reasons,
    expression: a!localVariables(
      local!old: a!match(
  value: a!defaultValue(fv!item, ""),
  equals: "insufficient_securities",
  then: a!map(
    remediation: "Arrange cover borrow / partial release",
    urgency: "HIGH",
    stDisposition: "Settled - Borrow Executed"
  ),
  equals: "funding_gap",
  then: a!map(
    remediation: "Treasury funding chase",
    urgency: "HIGH",
    stDisposition: "Settled - Funding Received"
  ),
  equals: "counterparty_default",
  then: a!map(
    remediation: "Credit-risk escalation",
    urgency: "CRITICAL",
    stDisposition: null
  ),
  equals: "operational_error",
  then: a!map(
    remediation: "Correct & resubmit",
    urgency: "MEDIUM",
    stDisposition: "Settled - Corrected"
  ),
  default: a!map(
    remediation: "Manual review",
    urgency: "MEDIUM",
    stDisposition: null
  )
),
      local!a: rule!SO_remediationForReason(failReason: fv!item),
      local!b: rule!SO_remediationForReason(failReason: fv!item, direction: null, onwardDeliveries: 5),
      local!same: and(
        tostring(local!a.remediation) = tostring(local!old.remediation),
        tostring(local!a.urgency) = tostring(local!old.urgency),
        a!defaultValue(local!a.stDisposition, "(null)") = a!defaultValue(local!old.stDisposition, "(null)"),
        tostring(local!b.remediation) = tostring(local!old.remediation),
        tostring(local!b.urgency) = tostring(local!old.urgency),
        a!defaultValue(local!b.stDisposition, "(null)") = a!defaultValue(local!old.stDisposition, "(null)")
      ),
      if(local!same, "PASS", "FAIL") & " | no direction | " & if(fv!item = "", "(null)", fv!item)
        & " -> " & local!a.remediation & " | " & local!a.urgency & " | " & a!defaultValue(local!a.stDisposition, "(null)")
    )
  ),
  local!sides: {
    a!map(r: "insufficient_securities", d: "BUY", e: "theirs"),
    a!map(r: "insufficient_securities", d: "SELL", e: "ours"),
    a!map(r: "funding_gap", d: "BUY", e: "ours"),
    a!map(r: "funding_gap", d: "SELL", e: "theirs"),
    a!map(r: "operational_error", d: "BUY", e: "ours"),
    a!map(r: "operational_error", d: "SELL", e: "ours"),
    a!map(r: "counterparty_default", d: "BUY", e: "theirs"),
    a!map(r: "counterparty_default", d: "SELL", e: "theirs"),
    a!map(r: "insufficient_securities", d: null, e: "(null)"),
    a!map(r: "funding_gap", d: "HOLD", e: "(null)"),
    a!map(r: "operational_error", d: null, e: "ours"),
    a!map(r: "counterparty_default", d: null, e: "theirs"),
    a!map(r: "something_else", d: "BUY", e: "(null)"),
    a!map(r: null, d: "SELL", e: "(null)")
  },
  local!sideLines: a!forEach(
    items: local!sides,
    expression: a!localVariables(
      local!got: a!defaultValue(rule!SO_failSide(failReason: fv!item.r, direction: fv!item.d), "(null)"),
      if(local!got = fv!item.e, "PASS", "FAIL") & " | side | " & a!defaultValue(fv!item.r, "(null)") & " | " & a!defaultValue(fv!item.d, "(none)") & " -> " & local!got
    )
  ),
  local!all: a!flatten({ local!tableLines, local!noDirLines, local!sideLines }),
  local!fails: length(wherecontains("FAIL", a!forEach(items: local!all, expression: left(fv!item, 4)))),
  "rows " & length(local!all) & ", fails " & local!fails & char(10) & joinarray(local!all, char(10))
)
