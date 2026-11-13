/*
 * SO_remediationForReason
 * The ONLY source of remediation text in the application (project.md, Business rules).
 * Fail reasons are the exact 4 from SETTLEMENT_HISTORY; anything else, including null,
 * falls to the Manual review fallback rather than erroring.
 *
 * FROM 2026-11-13 THE FIX DEPENDS ON WHOSE FAIL IT IS (rule!SO_failSide), which
 * follows from the trade's direction. Until then every insufficient_securities
 * case was told to borrow, buy or sell. On a buy the seller is the one short of
 * the line: we cannot partially release what we are waiting to receive, and we
 * would borrow only to cover a delivery of our own that depends on it.
 *
 *   fail reason              direction  onward  remediation                                    straight-through code
 *   insufficient_securities  SELL       any     Arrange cover borrow / partial release         Settled - Borrow Executed
 *   insufficient_securities  BUY        1+      Arrange cover borrow for onward deliveries /   Settled - Borrow Executed
 *                                               accept partial delivery
 *   insufficient_securities  BUY        0       Accept partial delivery / chase counterparty   Settled - Partial Release
 *   funding_gap              BUY        any     Treasury funding chase                         Settled - Funding Received
 *   funding_gap              SELL       any     Chase counterparty for funding                 Settled - Funding Received
 *   counterparty_default, operational_error, anything else: as before, whatever the direction.
 *
 * Texts and codes ruled by Scott, 2026-11-13. Urgency does not depend on the side.
 *
 * direction and onwardDeliveries ARE OPTIONAL. With no direction (or one that is
 * not BUY or SELL) the rule returns exactly what it returned before these inputs
 * existed, so a caller that passes only the fail reason is unchanged. The
 * onward count matters on one row only (insufficient_securities on a BUY); a
 * null count is read as 0, no onward delivery known. It comes from
 * rule!SO_onwardDeliveries.
 *
 * stDisposition is the disposition code a straight-through resolution stamps on the case.
 * It is NULL for counterparty_default, which makes "never straight-through a credit case"
 * a property of the data rather than something the agent has to remember. The default
 * branch is null for the same reason: an unrecognised reason is never auto-resolvable.
 */
a!localVariables(
  local!reason: a!defaultValue(ri!failReason, ""),
  /* "ours", "theirs", or null when the direction was not passed or is not BUY / SELL */
  local!theirs: a!defaultValue(
    rule!SO_failSide(failReason: local!reason, direction: ri!direction),
    ""
  ) = "theirs",
  local!onward: a!defaultValue(ri!onwardDeliveries, 0),
  a!match(
    value: local!reason,
    equals: "insufficient_securities",
    then: if(
      local!theirs,
      /* a BUY: the seller is short */
      if(
        local!onward >= 1,
        a!map(
          remediation: "Arrange cover borrow for onward deliveries / accept partial delivery",
          urgency: "HIGH",
          stDisposition: "Settled - Borrow Executed"
        ),
        a!map(
          remediation: "Accept partial delivery / chase counterparty",
          urgency: "HIGH",
          stDisposition: "Settled - Partial Release"
        )
      ),
      /* a SELL, where we are short; and the answer when no direction is passed */
      a!map(
        remediation: "Arrange cover borrow / partial release",
        urgency: "HIGH",
        stDisposition: "Settled - Borrow Executed"
      )
    ),
    equals: "funding_gap",
    then: if(
      local!theirs,
      /* a SELL: the buyer is short of the cash */
      a!map(
        remediation: "Chase counterparty for funding",
        urgency: "HIGH",
        stDisposition: "Settled - Funding Received"
      ),
      /* a BUY, where the cash is ours to find; and the answer when no direction is passed */
      a!map(
        remediation: "Treasury funding chase",
        urgency: "HIGH",
        stDisposition: "Settled - Funding Received"
      )
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
  )
)
