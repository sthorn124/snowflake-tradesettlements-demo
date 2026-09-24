/*
 * SO_assetClassDisplay — the ONLY place a stored asset class becomes screen text.
 *
 * WHY THIS EXISTS. The stored values are lower-case source enums
 * (equity, bond, etf, fx_forward) and Case Detail was title-casing them inline
 * with upper(left(x,1)) & lower(mid(x,2,n)). That hack is wrong twice, not once:
 * it renders "Fx_forward" (a raw enum with a capital letter on it) and it
 * renders "Etf" (an initialism it has no way to know about). Casing is not a
 * mapping, and a mapping is what display vocabulary is.
 *
 * STORED VALUES ARE UNCHANGED — rules, the agent and every comparison still see
 * the source enum. This rule is display only, and it is the display-vocabulary
 * canon's asset-class entry in executable form.
 *
 * THE DEFAULT NEVER RETURNS THE RAW VALUE UNTOUCHED. An asset class outside the
 * four still has to render something legible rather than a blank or an enum, so
 * it comes back with the underscore spaced out and a leading capital. If that
 * branch is ever seen on screen the mapping above is missing a case — that is
 * the tell, and it is deliberately visible rather than silent.
 */
a!localVariables(
  local!raw: lower(trim(a!defaultValue(ri!assetClass, ""))),
  if(
    a!isNullOrEmpty(local!raw),
    "—",
    a!match(
      value: local!raw,
      equals: "equity", then: "Equity",
      equals: "bond", then: "Bond",
      equals: "etf", then: "ETF",
      equals: "fx_forward", then: "FX forward",
      default: a!localVariables(
        local!spaced: substitute(local!raw, "_", " "),
        upper(left(local!spaced, 1)) & mid(local!spaced, 2, 40)
      )
    )
  )
)
