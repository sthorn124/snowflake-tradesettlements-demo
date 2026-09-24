/*
 * SO_failReasonDisplay — stored snake_case fail reason -> screen label.
 *
 * The four stored values are canon (SETTLEMENT_HISTORY / TRADE_PREDICTIONS) and
 * are what SO_remediationForReason and the agent read. This rule only renders.
 *
 * Two registers, both taken from the mockups:
 *   long  (analyst_watchlist.html, case_detail.html) -> "Insufficient securities"
 *   short (supervisor_command.html escalations grid) -> "Insuff. securities",
 *          "Cpty default", "Operational"
 * The short form exists because the supervisor grid carries eight columns and the
 * long labels wrap; it is a width accommodation, not a second vocabulary.
 *
 * Also returns the deliver-side note the case-detail risk banner shows beneath
 * the predicted reason ("deliver-side shortfall"), so that phrasing lives once.
 */
a!localVariables(
  local!r: a!defaultValue(ri!failReason, ""),
  local!short: a!defaultValue(ri!short, false),
  a!match(
    value: local!r,
    equals: "insufficient_securities",
      then: a!map(
        label: if(local!short, "Insuff. securities", "Insufficient securities"),
        note: "deliver-side shortfall"
      ),
    equals: "funding_gap",
      then: a!map(
        label: if(local!short, "Funding gap", "Funding gap"),
        note: "cash not in place at cutoff"
      ),
    equals: "operational_error",
      then: a!map(
        label: if(local!short, "Operational", "Operational error"),
        note: "instruction or SSI defect"
      ),
    equals: "counterparty_default",
      then: a!map(
        label: if(local!short, "Cpty default", "Counterparty default"),
        note: "credit event on the counterparty"
      ),
    /* Unrecognised reasons render verbatim with no invented note. */
    default: a!map(label: a!defaultValue(local!r, "Unknown"), note: "")
  )
)
