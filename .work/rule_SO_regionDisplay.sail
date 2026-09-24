/*
 * SO_regionDisplay — the ONLY place a stored counterparty region becomes
 * screen text. Sibling of SO_assetClassDisplay, and it exists for the same
 * reason: "NA" on a screen reads as "not available", which is not what the
 * column means. Stored values are unchanged.
 *
 * APAC IS DELIBERATELY LEFT AS APAC — it is the term a settlements desk uses,
 * not an unexpanded code, and expanding it would be less authentic, not more.
 *
 * The default returns the stored value rather than a dash: an unmapped region
 * is still information, and its appearance on screen is the tell that this
 * mapping is missing a case.
 */
a!localVariables(
  local!raw: upper(trim(a!defaultValue(ri!region, ""))),
  if(
    a!isNullOrEmpty(local!raw),
    "—",
    a!match(
      value: local!raw,
      equals: "NA", then: "North America",
      equals: "EU", then: "Europe",
      equals: "UK", then: "United Kingdom",
      equals: "APAC", then: "APAC",
      equals: "LATAM", then: "Latin America",
      equals: "EMEA", then: "EMEA",
      default: a!defaultValue(ri!region, "—")
    )
  )
)
