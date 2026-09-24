/*
 * SO_railFact — one labelled fact, in the rail's ONE type scale.
 *
 * THE SCALE COMES FROM THE MOCKUP, MEASURED, not invented. In
 * mockups/analyst_watchlist.html the whole selection rail lives inside a FOUR
 * PIXEL range: labels 11–11.5px, values and prose 12.5–13.5px, and a single
 * 15px element (the ticker). Mapped to the nearest platform sizes that is
 * SMALL for labels, STANDARD for values, MEDIUM for the ticker — and nothing
 * else. There is no large tier here, and an earlier build that introduced one
 * made the rail worse in three separate ways at once: a giant countdown chip
 * that read as a headline rather than a status, a notional truncated to
 * "38...." by the preventWrapping that large type needed to survive, and sizes
 * jumping line to line so the panel had no calm baseline to scan against.
 *
 *   LABEL   SMALL,    plain,  #6E7885 (muted)
 *   VALUE   STANDARD, STRONG, #1B2330 (ink) — EVERY value: notional, score,
 *           lag, counterparty, settles, side. Semantic colour only where
 *           meaning demands it (warn).
 *
 * EMPHASIS IS CARRIED BY WEIGHT AND COLOUR, NEVER BY SIZE. This is already a
 * deliberate correction to the mockup, which renders its values in a thin
 * mid-grey; ink + STRONG is heavier and darker on purpose, and that is the
 * whole readability fix. If a render still reads flat, the escalation path is
 * weight and spacing — never a third size.
 *
 * The rail's TWO exceptions are not expressible here and must not be: the
 * ticker, and the probability and live-countdown values. They are rendered
 * inline by SO_watchlistPreviewRail precisely because they are named
 * one-offs, both short by construction, and giving this object a "make it
 * bigger" parameter is what produced the tier that had to be deleted.
 *
 * NOTE ON WEIGHT: the mockup distinguishes 650 (values) from 700 (ticker,
 * chip). SAIL rich text has ONE bold — `style: "STRONG"` — so that two-step
 * distinction cannot be reproduced and both land on STRONG. Logged as a
 * mockup delta, not worked around.
 *
 * NO preventWrapping HERE. A value like "SELL 42,900 shares" or "Arrange cover
 * borrow / partial release" is multi-word and SHOULD wrap across lines; at
 * STANDARD every value in this rail fits its column anyway. preventWrapping on
 * a value that does not fit produces a truncation ("38...."), which is a worse
 * failure than a second line.
 *
 * Rich text sizes are the platform's own enumerated set, named by the
 * validator itself: SMALL, STANDARD, MEDIUM, MEDIUM_PLUS, LARGE, LARGE_PLUS,
 * EXTRA_LARGE. There is no STANDARD_PLUS.
 */
a!richTextDisplayField(
  /* showWhen is a declared input, not an inherited one: an interface rule only
     accepts the parameters it declares, so a caller that wants to hide a fact
     has to be able to say so here. */
  showWhen: a!defaultValue(ri!showWhen, true),
  labelPosition: "COLLAPSED",
  marginBelow: "STANDARD",
  value: {
    a!richTextItem(
      text: a!defaultValue(ri!key, ""),
      color: "#6E7885",
      size: "SMALL"
    ),
    char(10),
    a!richTextItem(
      text: a!defaultValue(ri!val, "—"),
      color: if(a!defaultValue(ri!warn, false), "#96590A", "#1B2330"),
      style: "STRONG",
      size: "STANDARD"
    ),
    /* A trailing qualifier — "· 12 mo · High tier" — at the same size as the
       value it qualifies, one step down in colour. The mockup renders these as
       one continuous dd, so they are one line here too. */
    a!richTextItem(
      showWhen: not(a!isNullOrEmpty(ri!sub)),
      text: "  " & a!defaultValue(ri!sub, ""),
      color: if(a!defaultValue(ri!warn, false), "#96590A", "#454F5C"),
      style: "STRONG",
      size: "STANDARD"
    )
  }
)
