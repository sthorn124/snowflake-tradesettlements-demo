/*
 * SO_railTicker — the side badge and ticker, as one line that cannot break.
 *
 * Extracted from SO_watchlistPreviewRail because the rail renders it in TWO
 * arrangements — sharing line 1 with the cutoff chip when the ticker is short,
 * owning the line when it is not — and the two must be byte-identical. An
 * inline copy in each branch would drift the moment one was edited.
 *
 * MEDIUM is this rail's ceiling, not a step on the way up: the mockup's
 * .pv-head .instid .tick is 15px, the single largest thing in the panel.
 * preventWrapping keeps a ticker from breaking into characters; the CALLER is
 * responsible for giving it enough width that it never has to truncate either.
 */
a!richTextDisplayField(
  showWhen: a!defaultValue(ri!showWhen, true),
  labelPosition: "COLLAPSED",
  preventWrapping: true,
  value: {
    a!richTextItem(
      text: index(ri!row, "sideLabel", ""),
      color: index(ri!row, "sideColor", "#4A5462"),
      style: "STRONG",
      size: "SMALL"
    ),
    a!richTextItem(
      text: "  " & index(ri!row, "ticker", ""),
      size: "MEDIUM",
      style: "STRONG",
      color: "#1B2330"
    )
  }
)
