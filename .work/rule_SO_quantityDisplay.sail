/*
 * SO_quantityDisplay — quantity worded per asset class.
 *
 * CLAUDE.md canon, and a rule the demo is judged on by anyone who has worked a
 * settlements desk: quantity display language follows the asset class.
 *   equity, etf -> "shares"    ("210,000 shares")
 *   bond        -> "face"      ("5,000,000 face")
 *   fx_forward  -> NOTIONAL ONLY — a forward has no unit count, so rendering a
 *                  quantity for one is wrong even when the column holds a number.
 * Never render a bond quantity as shares.
 *
 * Asset-class values MEASURED 2026-09-03 against INSTRUMENTS (200 rows):
 *   bond 67, equity 75, etf 26, fx_forward 32.
 * Anything else returns a bare grouped number with no unit word — inventing a
 * unit for an unknown asset class is how a bond ends up reading as shares.
 *
 * Returns hasQuantity so callers can drop the line entirely on an FX forward
 * rather than printing an empty label.
 */
a!localVariables(
  local!ac: lower(a!defaultValue(ri!assetClass, "")),
  local!q: todecimal(a!defaultValue(ri!quantity, null)),
  local!hasQ: not(a!isNullOrEmpty(local!q)),
  /* Six thousands groups for the same reason as SO_fmtMoney: text() returns the
     literal "N/A" once a number outgrows the groups written (§4). */
  local!qText: text(round(a!defaultValue(local!q, 0), 0), "#,###,###,###,###,##0"),

  local!unit: a!match(
    value: local!ac,
    equals: "equity", then: "shares",
    equals: "etf", then: "shares",
    equals: "bond", then: "face",
    equals: "fx_forward", then: "",
    default: ""
  ),

  /* An FX forward has no unit count to show at all, regardless of the column. */
  local!showable: and(local!hasQ, local!ac <> "fx_forward"),

  a!map(
    hasQuantity: local!showable,
    unit: local!unit,
    /* "210,000 shares" / "5,000,000 face" / "" for an FX forward. */
    display: if(
      not(local!showable),
      "",
      local!qText & if(local!unit = "", "", " " & local!unit)
    ),
    assetClass: local!ac
  )
)
