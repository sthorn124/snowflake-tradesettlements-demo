/*
 * SO_cutoffDisplay — a cutoff timestamp -> the countdown cell every screen shows.
 *
 * Mockup form (analyst_watchlist.html, case_detail.html):
 *     3h 05m          <- countdown, bold, severity-coloured
 *     12:46           <- the wall-clock cutoff, small, underneath
 *     05:21 +1        <- "+1" when the cutoff falls on a later calendar day
 *
 * ============================ CLOCK BASIS ============================
 * MEASURED 2026-09-03 on this instance, and the reason the day-offset below is
 * built the way it is. A cutoff STORED as 2026-09-03 16:45 read back as:
 *     text(cutoff, "yyyy-mm-dd hh:mm")  -> "2026-09-03 12:45"   (LOCAL, UTC-4)
 *     text(now(),  "yyyy-mm-dd hh:mm")  -> "2026-09-03 12:08"   (LOCAL)
 *     gmt(now())                        ->  2026-09-03 16:08    (so now() is UTC)
 *     todecimal(cutoff - now()) * 24    ->  0.616 h             (= 16:45 - 16:08)
 *     hour(cutoff) -> 16      hour(now()) -> 16                 (UTC hours)
 * So DATETIME SUBTRACTION HAPPENS IN UTC while text() RENDERS IN LOCAL TIME, and
 * hour()/day() return the UTC parts, NOT the parts text() displays. Both frames
 * are individually consistent; mixing them is what breaks.
 *
 * Consequence, and the first bug this comment exists to prevent recurring: the
 * "+1" suffix MUST be computed in the DISPLAY frame, or it contradicts the wall
 * clock printed beside it. A cutoff stored 2026-09-04 00:10 displays as 20:10 on
 * the 3rd; day(cutoff)=4 against today()=3 would stamp it "+1" while the time
 * beside it says 20:10 today. So both sides of the day comparison come from the
 * display frame, never from day()/today().
 *
 * ==================== todate() DOES NOT PARSE ISO ====================
 * The second bug, MEASURED 2026-09-03, and the reason the day offset is built
 * from date(y,m,d) rather than the obvious todate(text(dt,"yyyy-mm-dd")):
 *     todate("2026-09-04")  ->  renders "Date out of range (-20260904)"
 * It does NOT error. It yields a nonsense Date, and subtracting two of them
 * returns a number of the RIGHT MAGNITUDE WITH THE SIGN INVERTED:
 *     tointeger(todate("2026-09-04") - todate("2026-09-03"))  ->  -1
 * A next-day cutoff was therefore stamped dayOffset -1 and printed no "+1" at
 * all, with nothing failing anywhere. Same family as §4's warning that
 * text(<Date as text>, ...) returns an error STRING without erroring, but more
 * dangerous, because the arithmetic downstream still produces a plausible
 * number rather than visible garbage.
 * The working form takes the display-frame parts through text() and rebuilds a
 * real Date with date(y, m, d) — verified +1 for a next-day cutoff and 0 for a
 * same-local-day cutoff stored on the following UTC date.
 *
 * ARITHMETIC NOTES (appian-supplemental §4).
 *  - DateTime - DateTime yields an Interval, so differences are coerced with
 *    todecimal() before scaling to hours.
 *  - floor(), not tointeger(): tointeger() ROUNDS, which would report 1h 59m
 *    remaining as 2h and move the row out of the breach band.
 *  - text(-130, "0") prints "13-0", so the countdown is built from abs() values
 *    and the past case is worded, never signed.
 *  - The minute part is padded with "00" so 3h 5m reads "3h 05m", as the mockup
 *    shows, not "3h 5m".
 *
 * SEVERITY BANDS, derived from the mockup's own colouring rather than invented:
 *   1h 12m -> .breach (red)      2h 40m and 3h 05m -> .soon (amber)
 *   19h 40m -> plain
 * so the cut points the mockup pins down are BREACH under 2h and SOON under 4h.
 * "BREACH" is also the band for a cutoff already past.
 *
 * A NULL cutoff is not urgent. It returns severity "NONE" and an em dash, so a
 * case whose trade could not be read never renders as a red breach (§4: write
 * every nullable comparison null-safe so screens render under any data state).
 */
a!localVariables(
  local!cutoff: ri!cutoffTs,
  local!hasCutoff: not(a!isNullOrEmpty(local!cutoff)),
  /* Substitution, not an if() guard: validation evaluates BOTH branches of an
     if (§3), so a guarded branch would still evaluate the arithmetic on null. */
  local!safeCutoff: a!defaultValue(local!cutoff, now()),
  local!hoursRaw: todecimal(local!safeCutoff - now()) * 24,
  local!isPast: local!hoursRaw <= 0,
  local!absMinutes: floor(abs(local!hoursRaw) * 60),
  local!h: floor(local!absMinutes / 60),
  local!m: local!absMinutes - (local!h * 60),

  /* Day offset in the DISPLAY frame — see both CLOCK BASIS notes above. The
     parts come from text() (so they agree with the rendered wall clock) and are
     reassembled with date(), NOT todate() on a string, which silently inverts
     the sign. */
  local!cutoffLocalDate: date(
    tointeger(text(local!safeCutoff, "yyyy")),
    tointeger(text(local!safeCutoff, "mm")),
    tointeger(text(local!safeCutoff, "dd"))
  ),
  local!nowLocalDate: date(
    tointeger(text(now(), "yyyy")),
    tointeger(text(now(), "mm")),
    tointeger(text(now(), "dd"))
  ),
  local!dayOffset: tointeger(local!cutoffLocalDate - local!nowLocalDate),

  local!countdown: if(
    local!isPast,
    "past cutoff",
    local!h & "h " & text(local!m, "00") & "m"
  ),

  local!severity: if(
    or(local!isPast, local!hoursRaw < 2),
    "BREACH",
    if(local!hoursRaw < 4, "SOON", "NORMAL")
  ),

  a!map(
    hasCutoff: local!hasCutoff,
    countdown: if(local!hasCutoff, local!countdown, "—"),
    /* Wall clock, plus "+1"/"+2" when the cutoff is on a later day, as the
       mockup's "05:21 +1" shows. */
    atText: if(
      local!hasCutoff,
      text(local!safeCutoff, "hh:mm") & if(local!dayOffset > 0, " +" & local!dayOffset, ""),
      ""
    ),
    severity: if(local!hasCutoff, local!severity, "NONE"),
    color: if(
      not(local!hasCutoff),
      "#6E7885",
      a!match(
        value: local!severity,
        equals: "BREACH", then: "#B3261E",
        equals: "SOON", then: "#96590A",
        default: "#1B2330"
      )
    ),
    /* Signed decimal hours remaining — negative when past. Consumers doing the
       lag-vs-window arithmetic need the real number, not the display string. */
    hoursRemaining: if(local!hasCutoff, local!hoursRaw, null),
    isPast: and(local!hasCutoff, local!isPast),
    /* True when the cutoff is inside the four-hour critical window used by the
       "Inside critical window" KPI on both the analyst and supervisor screens. */
    insideCriticalWindow: and(local!hasCutoff, local!hoursRaw > 0, local!hoursRaw < 4),
    /* Local-frame hour 0..23, for the supervisor's cutoff-runway buckets. Taken
       from text() and NOT from hour(), which returns the UTC hour. */
    displayHour: if(local!hasCutoff, tointeger(text(local!safeCutoff, "HH")), null),
    dayOffset: if(local!hasCutoff, local!dayOffset, null)
  )
)
