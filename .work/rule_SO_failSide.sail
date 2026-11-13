/*
 * SO_failSide — whose fail it is: "ours" or "theirs". Written once.
 *
 * A settlement fails because one side cannot do its part. Which side that is
 * follows from the fail reason and from which way the trade faces us:
 *
 *   fail reason               BUY       SELL
 *   insufficient_securities   theirs    ours     the seller is short of the line
 *   funding_gap               ours      theirs   the buyer is short of the cash
 *   operational_error         ours      ours     our instruction is wrong
 *   counterparty_default      theirs    theirs   the counterparty has defaulted
 *
 * Ruled by Scott, 2026-11-13.
 *
 * READ BY SO_remediationForReason, which proposes a different fix when the
 * shortfall is the counterparty's. The case screen's penalty figure is to read
 * it too (who pays), in a later session.
 *
 * Returns null when it cannot say: a fail reason outside the four, or
 * insufficient_securities / funding_gap with no direction (or a direction that
 * is not BUY or SELL). operational_error and counterparty_default do not depend
 * on the direction, so they answer without one. A caller treats null as
 * "not known", never as "ours".
 *
 * The direction is compared in upper case with spaces trimmed. The stored
 * values on SO Trade are BUY and SELL.
 */
a!localVariables(
  local!reason: a!defaultValue(ri!failReason, ""),
  local!dir: upper(trim(a!defaultValue(ri!direction, ""))),
  a!match(
    value: local!reason,
    equals: "insufficient_securities",
    then: a!match(
      value: local!dir,
      equals: "SELL", then: "ours",
      equals: "BUY", then: "theirs",
      default: null
    ),
    equals: "funding_gap",
    then: a!match(
      value: local!dir,
      equals: "BUY", then: "ours",
      equals: "SELL", then: "theirs",
      default: null
    ),
    equals: "operational_error",
    then: "ours",
    equals: "counterparty_default",
    then: "theirs",
    default: null
  )
)
