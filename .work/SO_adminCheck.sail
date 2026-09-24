/*
 * SO_adminCheck — one line of the readiness checklist, and the only place a
 * check is rendered.
 *
 * THREE STATES, NOT TWO. `ok` drives green tick / red cross, but a check whose
 * `expected` is the literal word "informational" renders NEUTRAL — a grey dot —
 * because some lines report a state rather than assert one. Reserved packet rows
 * present, fixture cases present, comment and event totals: all of those are
 * facts an operator wants before going on stage, and none of them is a failure.
 *
 * WHY THAT MATTERS MORE THAN IT LOOKS: a checklist that paints normal states red
 * teaches its reader to ignore red, and then the one line that IS a failure gets
 * ignored with the rest. Neutral is what keeps red meaningful.
 */
a!localVariables(
  local!info: a!defaultValue(ri!expected, "") = "informational",
  local!ok: a!defaultValue(ri!ok, false),
  a!richTextDisplayField(
    labelPosition: "COLLAPSED",
    marginBelow: "LESS",
    value: {
      a!richTextItem(
        text: if(local!info, "•  ", if(local!ok, "✓  ", "✕  ")),
        color: if(local!info, "#9AA6B3", if(local!ok, "#17715B", "#B3261E")),
        style: "STRONG",
        size: "STANDARD"
      ),
      a!richTextItem(
        text: a!defaultValue(ri!label, ""),
        color: "#1B2330",
        size: "STANDARD"
      ),
      a!richTextItem(text: "   ", size: "STANDARD"),
      a!richTextItem(
        text: a!defaultValue(ri!actual, "—"),
        color: if(local!info, "#454F5C", if(local!ok, "#17715B", "#B3261E")),
        size: "STANDARD",
        style: "STRONG"
      ),
      /* The expectation is shown only when it is an assertion and only when it
         FAILED — a passing check that also prints what it wanted is noise. */
      a!richTextItem(
        showWhen: and(not(local!info), not(local!ok)),
        text: "   expected " & a!defaultValue(ri!expected, ""),
        color: "#6E7885",
        size: "SMALL"
      )
    }
  )
)
