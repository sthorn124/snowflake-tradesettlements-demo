/*
 * SO_priorityBand — SO_casePriority's 1..100 integer -> the queue pill.
 *
 * SO_casePriority returns round(failProbability * urgencyFactor * 100) where
 * urgencyFactor is 1.0 under 2h to cutoff, 0.8 under 8h, 0.6 under 24h, 0.4
 * beyond. This rule only bands that number; it never recomputes it.
 *
 * Thresholds DERIVED from mockups/analyst_watchlist.html rather than chosen.
 * Recomputing SO_casePriority for all sixteen mockup rows from their printed
 * probability and cutoff gives:
 *   Urgent  rows: 87, 66, 62, 57
 *   High    rows: 52, 44, 41, 38
 *   Standard rows: 35, 22
 * The only cut points consistent with every row are Urgent >= 55 and High >= 36.
 * The tightest pair is 38 (High) against 35 (Standard), so 36 is the boundary
 * the mockup actually pins down.
 *
 * A null priority bands as Standard, never Urgent — an unknown priority must not
 * jump the queue.
 */
a!localVariables(
  local!p: tointeger(a!defaultValue(ri!priority, 0)),
  if(
    local!p >= 55,
    a!map(label: "Urgent", color: "#B3261E", rank: 3),
    if(
      local!p >= 36,
      a!map(label: "High", color: "#96590A", rank: 2),
      a!map(label: "Standard", color: "#4A5462", rank: 1)
    )
  )
)
