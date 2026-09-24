/*
 * SO_penaltyAccrual — daily CSDR-style cash penalty accrual estimate.
 *
 * CSDR settlement discipline charges a daily cash penalty on the value of a
 * failing delivery for every business day the fail persists. The rate is a
 * basis-point figure per day, held in cons!SO_PENALTY_BP_PER_DAY (1.0 bp) so it
 * is tunable live without touching this rule.
 *
 * ESTIMATE, not a calculation of record. The real regime varies the rate by
 * instrument class and uses the reference price rather than trade notional;
 * this is the desk's back-of-envelope "what does another day cost us".
 *
 * Worked check: 18,700,500 EUR at 1.0 bp/day
 *   daily   = 18,700,500 * 1.0 / 10,000 = 1,870.05  -> "~1.9K EUR / day"
 *   fiveDay = 1,870.05 * 5              = 9,350.25  -> "~9.4K EUR"
 * Both match the case-detail mockup ("~1.9K EUR / day", "~9.4K EUR").
 *
 * Null-safe: a null or empty value yields 0 rather than erroring, so the rule is
 * safe on a case whose trade could not be read (§4).
 */
a!localVariables(
  local!v: a!defaultValue(todecimal(ri!value), 0),
  local!bp: a!defaultValue(todecimal(cons!SO_PENALTY_BP_PER_DAY), 1.0),
  local!ccy: a!defaultValue(ri!currency, ""),

  local!daily: local!v * local!bp / 10000,
  local!fiveDay: local!daily * 5,

  /* Compact desk formatting: 1.9K / 2.3M.
     round() BEFORE text(): MEASURED 2026-09-02 — text(1.87005, "0.0") returns
     "1.8", not "1.9". Appian's text() TRUNCATES to the format's precision, it
     does not round, so the mockup's "~1.9K" is only reachable by rounding first.
     abs() keeps a negative from printing as "13-0" (§4: text(-130,"0") does
     exactly that). */
  local!fmt: a!forEach(
    items: { local!daily, local!fiveDay },
    expression: a!localVariables(
      local!n: abs(todecimal(fv!item)),
      if(
        local!n >= 1000000,
        text(round(local!n / 1000000, 1), "0.0") & "M",
        if(
          local!n >= 1000,
          text(round(local!n / 1000, 1), "0.0") & "K",
          text(round(local!n, 2), "0.00")
        )
      )
    )
  ),

  a!map(
    daily: local!daily,
    fiveDay: local!fiveDay,
    currency: local!ccy,
    bpPerDay: local!bp,
    dailyDisplay: "~" & index(local!fmt, 1, "0") & if(local!ccy = "", "", " " & local!ccy) & " / day",
    fiveDayDisplay: "~" & index(local!fmt, 2, "0") & if(local!ccy = "", "", " " & local!ccy)
  )
)
