/*
 * SO_casePriority — risk x time-to-cutoff, 1..100.
 * A medium-risk trade settling in 90 minutes outranks a high-risk trade settling Thursday.
 *
 * Arithmetic notes (appian-supplemental §4): DateTime - DateTime yields an Interval, so the
 * difference is coerced with todecimal() before scaling to hours; floor() is used rather than
 * tointeger() because tointeger() ROUNDS and we need truncation; the result is wrapped in
 * tointeger() so the return is a true Integer, not a Decimal.
 *
 * Null handling is done by SUBSTITUTION, not by an if() guard: validation evaluates BOTH
 * branches of an if (§3), so a guarded branch would still hit floor(null) and fail at save.
 * A null cutoff is treated as far-future (lowest urgency factor), never as urgent.
 */
a!localVariables(
  local!cutoff: a!defaultValue(ri!cutoffTs, now() + 9999),
  local!hoursRaw: todecimal(local!cutoff - now()) * 24,
  local!hoursToCutoff: max({0, floor(local!hoursRaw)}),
  local!urgencyFactor: if(
    local!hoursToCutoff < 2,
    1.0,
    if(
      local!hoursToCutoff < 8,
      0.8,
      if(local!hoursToCutoff < 24, 0.6, 0.4)
    )
  ),
  tointeger(
    max({
      1,
      round(todecimal(a!defaultValue(ri!failProbability, 0)) * local!urgencyFactor * 100, 0)
    })
  )
)
