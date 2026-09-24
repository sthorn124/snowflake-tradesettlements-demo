/*
 * SO_kpiCard — one KPI tile, used by every KPI band in the application.
 *
 * The mockups render a KPI as a white card with a 3px coloured bar down its LEFT
 * edge. That is not an approximation in SAIL: a!cardLayout's
 * decorativeBarPosition "START" with decorativeBarColor is exactly that bar.
 *
 * Shape follows the mockup: label (with the provenance glyph when the figure is
 * Snowflake intelligence), then the value with an optional small unit beside it,
 * then a secondary line. Every caller passes an already-formatted value string —
 * this rule does no arithmetic and no number formatting, so there is exactly one
 * place money is formatted (SO_fmtMoney) and one place a KPI is laid out.
 *
 * snowMarked drives the glyph AND the card's accessible tooltip together, so a
 * marked figure can never render the mark without the explanation.
 *
 * THE SUB-LINE MUST FIT ONE LINE, and `tooltip` is what makes that affordable.
 * Six tiles in a row are only equal height while every sub is one line; one
 * caller writing a 65-character sub silently makes its own card taller and the
 * band ragged. Qualifications that do not fit — a sampling note, an FX basis —
 * go in `tooltip` rather than being deleted or crammed in. The rule composes the
 * Snowflake note and the caller's note into one tooltip so a marked card never
 * loses its provenance explanation to a caller's text.
 */
a!localVariables(
  local!snowNote: if(
    a!defaultValue(ri!snowMarked, false),
    "Live from Snowflake — computed in Snowflake over the trade and prediction data, not copied here.",
    ""
  ),
  local!extra: a!defaultValue(ri!tooltip, ""),
  a!cardLayout(
  padding: "LESS",
  style: "NONE",
  showBorder: true,
  shape: "SEMI_ROUNDED",
  decorativeBarPosition: "START",
  decorativeBarColor: a!defaultValue(ri!accentColor, "#9AA6B3"),
  contents: {
    a!richTextDisplayField(
      labelPosition: "COLLAPSED",
      tooltip: local!snowNote
        & if(and(len(local!snowNote) > 0, len(local!extra) > 0), "  ", "")
        & local!extra,
      value: {
        a!richTextItem(
          text: a!defaultValue(ri!label, ""),
          color: "#454F5C",
          size: "SMALL",
          style: "STRONG"
        ),
        /* The provenance mark comes from SO_snowflakeMark and from nowhere
           else, so the asset and its accessibility fallback live in one object.
           The mark carries no tooltip of its own, so the explanation rides on
           this field's tooltip above. showWhen keeps it off unmarked cards. */
        a!richTextItem(text: if(a!defaultValue(ri!snowMarked, false), "  ", "")),
        rule!SO_snowflakeMark(showWhen: a!defaultValue(ri!snowMarked, false)),
        char(10),
        a!richTextItem(
          text: a!defaultValue(ri!value, "—"),
          color: a!defaultValue(ri!valueColor, "#1B2330"),
          size: "LARGE",
          style: "STRONG"
        ),
        a!richTextItem(
          text: if(a!isNullOrEmpty(ri!unit), "", " " & ri!unit),
          color: "#454F5C",
          size: "SMALL",
          style: "STRONG"
        ),
        char(10),
        a!richTextItem(
          text: a!defaultValue(ri!sub, ""),
          color: "#454F5C",
          size: "SMALL"
        )
      }
    )
  }
)
)
