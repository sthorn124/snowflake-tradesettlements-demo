/*
 * SO_riskTierDisplay — the ONLY place a stored risk tier becomes screen text.
 * Third of the display-vocabulary rules, after SO_assetClassDisplay and
 * SO_regionDisplay, and it closes the last casing-instead-of-mapping site.
 *
 * WHY IT EXISTS WHEN THE OLD CODE WORKED. Counterparty riskTier is stored
 * lower-case (high / medium / low) and was being title-cased inline with
 * upper(left(x,1)) & lower(mid(x,2,n)) on two screens. That produced the RIGHT
 * answer on all four stored values — measured 2026-09-09 — so this is not a bug
 * fix. It is the same expression that DID leak on asset class, where it rendered
 * "Fx_forward" and would have rendered "Etf". A mapping that happens to agree
 * with a casing trick is still a mapping; the trick is one new stored value away
 * from being wrong, and it cannot be found by grep once it is inline.
 *
 * TWO SOURCES, ONE VOCABULARY. TRADE_PREDICTIONS.RISK_TIER arrives already
 * capitalised ("Critical"); COUNTERPARTIES.RISK_TIER arrives lower-case
 * ("high"). Both go through here so one screen can never show both casings —
 * which was the original reason for the inline title-casing, now handled by a
 * rule that also knows what the words are.
 *
 * The default returns the stored value rather than a dash: an unmapped tier is
 * still information, and seeing it is the tell that this mapping is short a case.
 */
a!localVariables(
  local!raw: lower(trim(a!defaultValue(ri!riskTier, ""))),
  if(
    a!isNullOrEmpty(local!raw),
    "—",
    a!match(
      value: local!raw,
      equals: "critical", then: "Critical",
      equals: "high", then: "High",
      equals: "medium", then: "Medium",
      equals: "low", then: "Low",
      default: a!defaultValue(ri!riskTier, "—")
    )
  )
)
