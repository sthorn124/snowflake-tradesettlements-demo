/*
 * SO_fmtDayDate — a date as the desk writes it: "Thu 3 Sep".
 *
 * WHY THIS RULE EXISTS. The mockups render settlement dates as "Tue 1 Sep", and
 * the obvious format string for that is wrong in a way that renders plausibly:
 *   MEASURED 2026-09-03 (a Thursday) —
 *     text(today(), "ddd")   -> "3rd"        <- ORDINAL DAY OF MONTH, not a weekday
 *     text(today(), "dddd")  -> "Thursday"
 *     text(today(), "ww" / "www" / "wwww")   -> passed through literally
 * So "ddd d mmm" produces "3rd 3 Sep", not "Thu 3 Sep", and there is NO
 * three-letter weekday token on this platform. The working form takes the first
 * three characters of the full weekday name.
 *
 * THE INPUT IS TYPED Date, DELIBERATELY, AND MUST NOT BE WIDENED TO Date and
 * Time. MEASURED 2026-09-03: with the input declared Date and Time, passing
 * today() coerced the Date to midnight and text() then rendered it in the
 * display frame (UTC-4), producing "Wed 2 Sep" ON A THURSDAY — a date off by one
 * day, with nothing erroring. Passed as a Date it renders "Thu 3 Sep" correctly.
 * Cutoff TIMESTAMPS are not formatted here at all; SO_cutoffDisplay owns those
 * and does its own display-frame arithmetic.
 *
 * A null date returns an em dash rather than a formatted epoch.
 */
a!localVariables(
  local!d: ri!value,
  if(
    a!isNullOrEmpty(local!d),
    "—",
    left(text(local!d, "dddd"), 3) & " " & text(local!d, "d mmm")
  )
)
