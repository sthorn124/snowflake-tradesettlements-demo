/*
 * SO_railCutoffChip — how long is left, and the ONLY place the rail states the
 * cutoff clock time. The timing section below it never repeats the time.
 *
 * Extracted alongside SO_railTicker: the rail renders this either beside the
 * ticker (right-aligned, width MINIMIZE) or stacked beneath it (left-aligned,
 * full width) depending on ticker length, and the two must not drift.
 *
 * EXCEPTION 2 of the rail's type scale, live half: the countdown VALUE is
 * MEDIUM in its band colour, never more than 8 characters ("23h 59m"), so it
 * cannot wrap or truncate. PAST CUTOFF IS A STATUS, NOT A NUMBER, so it drops
 * to STANDARD bold red — the chip says where the case stands; it is not the
 * headline of the panel.
 */
a!richTextDisplayField(
  showWhen: a!defaultValue(ri!showWhen, true),
  labelPosition: "COLLAPSED",
  align: a!defaultValue(ri!align, "RIGHT"),
  preventWrapping: true,
  value: {
    a!richTextItem(
      text: if(
        a!defaultValue(ri!isPast, false),
        "Past cutoff",
        index(ri!row, "countdown", "")
      ),
      color: index(ri!row, "cutoffColor", "#1B2330"),
      style: "STRONG",
      size: if(a!defaultValue(ri!isPast, false), "STANDARD", "MEDIUM")
    ),
    char(10),
    a!richTextItem(
      text: if(
        a!defaultValue(ri!isPast, false),
        "missed " & index(ri!row, "cutoffAt", ""),
        "to cutoff · " & index(ri!row, "cutoffAt", "")
      ),
      color: "#6E7885",
      size: "SMALL"
    )
  }
)
