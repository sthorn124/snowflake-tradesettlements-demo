/*
 * SO_remediationForReason
 * The ONLY source of remediation text in the application (CLAUDE.md business rules).
 * Fail reasons are the exact 4 from SETTLEMENT_HISTORY; anything else, including null,
 * falls to the Manual review fallback rather than erroring.
 *
 * stDisposition is the disposition code a straight-through resolution stamps on the case.
 * It is NULL for counterparty_default, which makes "never straight-through a credit case"
 * a property of the data rather than something the agent has to remember. The default
 * branch is null for the same reason: an unrecognised reason is never auto-resolvable.
 */
a!match(
  value: a!defaultValue(ri!failReason, ""),
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
)
