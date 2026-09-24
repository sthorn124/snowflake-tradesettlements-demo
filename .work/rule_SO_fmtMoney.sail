/*
 * SO_fmtMoney — the ONE money formatter for every screen (appian-supplemental §12:
 * shared logic implemented once, variation as a parameter).
 *
 * WHY THIS RULE EXISTS AT ALL. text() neither rounds nor groups beyond what the
 * format literally spells out, and both failures produce plausible-looking output:
 *   MEASURED 2026-09-03 through a render probe on TRADES:
 *     text(154671040, "#,##0")        -> "154671,040"   (one group only)
 *     text(1.87005, "0.0")            -> "1.8"          (truncates, not rounds)
 *   and raw concatenation of a DOUBLE emits scientific notation:
 *     "" & 154671040                  -> "1.54671e+08"
 * So: round() BEFORE text(), and never hand a raw notional to & .
 *
 * compact = true  -> desk shorthand: "154.7M EUR", "88.0K EUR", "2.3B USD"
 * compact = false -> full precision:  "154,671,040 EUR"
 *
 * The full form spells SIX thousands groups ("#,###,###,###,###,##0"), one wider
 * than any value this data can hold, because once a number outgrows the groups
 * written text() returns the literal string "N/A" (§4).
 *
 * Null/empty value yields an em dash, never "0" — a missing figure and a zero
 * figure are different facts on a settlements screen. Null currency is omitted
 * rather than printed as "null".
 */
a!localVariables(
  local!raw: todecimal(a!defaultValue(ri!amount, null)),
  local!ccy: if(a!isNullOrEmpty(ri!currency), "", " " & ri!currency),
  local!compact: a!defaultValue(ri!compact, true),
  local!n: abs(a!defaultValue(local!raw, 0)),
  local!sign: if(a!defaultValue(local!raw, 0) < 0, "-", ""),

  /* Magnitude bands. abs() first so a negative never prints as "13-0" (§4). */
  local!compactBody: if(
    local!n >= 1000000000,
    text(round(local!n / 1000000000, 1), "0.0") & "B",
    if(
      local!n >= 1000000,
      text(round(local!n / 1000000, 1), "0.0") & "M",
      if(
        local!n >= 1000,
        text(round(local!n / 1000, 1), "0.0") & "K",
        text(round(local!n, 0), "0")
      )
    )
  ),

  local!fullBody: text(round(local!n, 0), "#,###,###,###,###,##0"),

  if(
    a!isNullOrEmpty(local!raw),
    "—",
    local!sign & if(local!compact, local!compactBody, local!fullBody) & local!ccy
  )
)
