/*
 * SO_watchlistPreviewRail — the selection rail beside the analyst queue.
 * Display target: the .preview column of mockups/analyst_watchlist.html.
 *
 * Takes ONE pre-enriched row map from SO_analystWatchlist plus the case's stored
 * agent assessment prose. It performs no queries and no business arithmetic: the
 * display rules already ran once per row during enrichment, so nothing here can
 * disagree with the grid row it describes.
 *
 * ================================ TYPE SCALE =================================
 * THE MOCKUP IS THE STRUCTURAL TYPE AUTHORITY. mockups/analyst_watchlist.html
 * puts this entire rail inside a FOUR PIXEL range — labels 11–11.5px, values
 * and prose 12.5–13.5px, one 15px element (.pv-head .instid .tick, the
 * ticker). Mapped to the nearest platform sizes:
 *
 *   LABEL  SMALL,    plain,  #6E7885
 *   VALUE  STANDARD, STRONG, #1B2330 — every value in the rail
 *
 * plus exactly TWO named exceptions at MEDIUM, both short by construction so
 * neither can wrap or truncate:
 *   1. the TICKER (mockup 15px/700), one line, preventWrapping;
 *   2. the PROBABILITY value and the LIVE COUNTDOWN value, in semantic colour.
 *      Their context — the tier word, "to cutoff · 15:00" — stays STANDARD or
 *      SMALL, because it is context and not the number.
 *
 * NOTHING ELSE EXCEEDS STANDARD, AND THERE IS NO LARGE ANYWHERE. A previous
 * build added a large "key number" tier and it made the rail worse in three
 * ways at once: the countdown chip read as a headline instead of a status, the
 * notional truncated to "38...." because large type needed preventWrapping to
 * survive its column, and sizes jumped line to line so nothing had a calm
 * baseline to scan against. EMPHASIS IS WEIGHT AND COLOUR, NEVER SIZE — and if
 * a render still reads flat the escalation is weight and spacing, never a
 * third size.
 *
 * The rail is already a deliberate correction to the mockup: its values are a
 * thin mid-grey, and these are ink and STRONG. That correction is the
 * readability fix; the sizes are not.
 *
 * PROSE BUDGET IS ONE SENTENCE — the timing verdict, and within it only the
 * VERDICT PHRASE is bold and coloured ("Fits the window —"), the remainder
 * plain ink. That is the mockup's own .verdict/.verdict b pattern. Everything
 * else in the rail is a label-value pair, including the lag.
 *
 * ============================ THE LANE IS STORED =============================
 * The recommendation card renders the case's STORED DECISION — its status —
 * and never re-derives the lane from the score. See SO_autoReleaseDisplay for
 * the defect that forced this: a counterparty-default case legitimately carries
 * a high score AND is escalated, and a score-derived lane announced "Released
 * without touch · score 95" beside an Escalated chip. With no assessment on the
 * case the whole card collapses to one line; there is no half-rendered state.
 *
 * BARS. The two TIMING bars are native a!progressBarField; the AUTO-RELEASE bar
 * is glyphs. That split was arrived at by failure: both were glyph runs and in
 * this 320px rail they WRAPPED TO TWO LINES, which reads as two bars and is
 * worse than no bar. A progress bar cannot wrap, so the timing pair uses it —
 * both expressed as a percentage of the SAME maximum, because comparing lag
 * against the window is the entire point of the pair. The auto-release bar
 * keeps glyphs ONLY because a progress bar cannot draw the gate marker on the
 * track, on a hard 16-glyph budget that cannot reach the rail width at any
 * score.
 *
 * PAST CUTOFF IS SAID ONCE. The countdown chip owns "Past cutoff / missed
 * 09:00"; the timing section states the consequence and the lag, and does not
 * repeat the clock time. It is also a correctness branch: hoursRemaining is
 * negative there and text() MANGLES a negative (MEASURED: text(round(-115.27,
 * 1), "0.0") renders "11-5.3"), so branching keeps every negative away from
 * text() rather than trying to format one safely.
 *
 * EMPTY STATE. Nothing selected is the normal opening state of this screen, and
 * on a reset baseline there is nothing to select at all. Both read as an
 * invitation, not an error.
 */
a!localVariables(
  local!r: ri!row,
  local!has: not(a!isNullOrEmpty(local!r)),

  local!hrsLeft: todecimal(a!defaultValue(index(local!r, "hoursRemaining", 0), 0)),
  local!lag: todecimal(a!defaultValue(index(local!r, "lagHrs", 0), 0)),
  local!isPast: a!defaultValue(index(local!r, "isPast", false), false),
  local!scaleMax: max({ 0.1, local!hrsLeft, local!lag }),
  local!remainPct: tointeger(max({ 0, min({ 100, tointeger(round(100 * local!hrsLeft / local!scaleMax, 0)) }) })),
  local!lagPct: tointeger(max({ 0, min({ 100, tointeger(round(100 * local!lag / local!scaleMax, 0)) }) })),
  /* Lag is a STATIC property of the trade and must read exactly as stored —
     this is the number the agent reasoned over. floor()+padded minutes, never
     tointeger() (which rounds). */
  local!lagText: if(
    a!isNullOrEmpty(index(local!r, "lagHrs", null)),
    "—",
    floor(local!lag) & "h " & text(floor((local!lag - floor(local!lag)) * 60), "00") & "m"
  ),

  /* The stored lane, and whether there is anything to show for it. A case with
     no recorded assessment has not been through triage, so the card collapses
     rather than rendering an action, a lane and a bar that mean nothing yet. */
  /* THE FULL TICKER ALWAYS WINS LINE 1. The chip is width MINIMIZE, which
     claims what it needs FIRST, so a long ticker beside it was truncating
     ("CHFJPY 1…"). The graceful fix would be reflow, but `shouldWrap` on
     a!sideBySideLayout is rejected by the object validator (MEASURED — it is in
     the rendered tree and validateExpression accepts it, only the object
     validator refuses), so the decision is made HERE, deterministically, on the
     one thing that actually drives it: how long the ticker is.
     Short equity/ETF tickers ("ENGI FP", "ULVR LN" — 7 chars) share line 1 with
     the chip. Everything longer — every FX forward ("CHFJPY 1M FWD", 13) and
     every bond ("PHILIP 4.412 06/29", 18) — takes the line alone and the chip
     drops beneath it, right-aligned, carrying its own subline. Stacked, the
     ticker has the whole rail and cannot truncate at any length on this book. */
  local!tickerFitsBesideChip: len(a!defaultValue(index(local!r, "ticker", ""), "")) <= 10,

  /* ============ THE EXCERPT: WHAT TO SHOW, AND WHAT TO SKIP ============
     THE RAIL PREVIEWS; THE CASE IS THE RECORD. Two separate decisions here.

     WHERE TO START. The stored assessment opens by restating trade id,
     instrument and notional — and it is RIGHT to: the assessment is a
     standalone audit record and has to identify its own subject. But the rail
     header has just said all three, so quoting that opening spends the
     preview's two sentences on nothing the reader does not already have. The
     excerpt therefore starts at the first sentence carrying REASONING.

     Detected BY CONTENT, not by position. "Skip sentence 1" would be a rule
     about today's assessment shape, and assessment shape is authored — it will
     drift. Matching on the vocabulary of the reasoning itself (the timing
     arithmetic, the counterparty history) survives that drift, and when no
     sentence matches the fallback is simply sentence 1, so a differently
     shaped assessment degrades to "show the beginning" rather than to blank.

     NOTE the agent instructions are NOT touched. This is display-side
     selection over a record that stays complete.

     WHERE TO STOP. Two sentences, cut on a boundary. Split on ". " —
     period-then-space — which no figure in these assessments contains, since
     "10.2 hours", "18.9%" and "9.2%" all put a digit or a percent sign
     immediately after the period. The split can only land between sentences.

     ONE DOOR. The excerpt ends with a plain " …" continuation cue and NO link
     of its own; "Open case →" at the foot of the rail is the single way into
     the record. Two links to the same place is two doors and a decision the
     reader should not have to make. */
  local!whySentences: split(a!defaultValue(ri!assessmentText, ""), ". "),
  local!whyCount: count(local!whySentences),
  /* The vocabulary of reasoning — timing arithmetic or counterparty history.
     Deliberately NOT bare "cutoff": a settlement date restatement could carry
     that word and it would defeat the skip. */
  local!whyStart: a!defaultValue(
    index(
      a!flatten(a!forEach(
        items: local!whySentences,
        expression: if(
          rule!SO_textContainsAny(
            haystack: fv!item,
            needles: {
              "broker confirmation lag", "remaining to cutoff",
              "cutoff has now passed", "risk tier", "twelve months",
              "fail rate", "book average"
            }
          ),
          { fv!index },
          {}
        )
      )),
      1,
      null
    ),
    1
  ),
  /* Sentences other than the last lost their period to the split; the last
     kept its own. Normalising here means the join never doubles or drops one. */
  local!whyFirst: index(local!whySentences, local!whyStart, ""),
  local!whySecond: if(
    local!whyStart + 1 <= local!whyCount,
    index(local!whySentences, local!whyStart + 1, ""),
    ""
  ),
  local!whyText: if(
    a!isNullOrEmpty(ri!assessmentText),
    "",
    local!whyFirst
      & if(right(local!whyFirst, 1) = ".", "", ".")
      & if(
        local!whySecond = "",
        "",
        " " & local!whySecond & if(right(local!whySecond, 1) = ".", "", ".")
      )
      & " …"
  ),

  local!lane: a!defaultValue(index(local!r, "lane", "UNSCORED"), "UNSCORED"),
  local!hasAssessment: not(a!isNullOrEmpty(ri!assessmentText)),
  local!scored: and(local!hasAssessment, local!lane <> "UNSCORED"),
  /* Bar fill follows the LANE, never the score comparison: an escalated case
     that scored above the gate must not draw a green bar. */
  local!laneColor: a!defaultValue(index(local!r, "arPillColor", "#6E7885"), "#6E7885"),

  local!arScore: tointeger(a!defaultValue(index(local!r, "arScore", 0), 0)),
  local!arGate: tointeger(a!defaultValue(index(local!r, "arGate", 80), 80)),
  local!arCells: 16,
  local!arFill: tointeger(max({ 0, min({ local!arCells, tointeger(round(local!arCells * local!arScore / 100, 0)) }) })),
  local!arGateCell: tointeger(max({ 1, min({ local!arCells, tointeger(round(local!arCells * local!arGate / 100, 0)) }) })),

  /* The rail is the RIGHT HALF OF ONE TWO-COLUMN REGION, not a floating panel,
     so it carries the same card treatment as the queue card beside it. */
  a!cardLayout(
    padding: "NONE",
    style: "NONE",
    showBorder: true,
    shape: "SEMI_ROUNDED",
    height: "AUTO",
    contents: {
      /* ============ EMPTY STATE ============ */
      a!cardLayout(
        showWhen: not(local!has),
        padding: "MORE",
        style: "NONE",
        showBorder: false,
        height: "MEDIUM",
        contents: a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          align: "CENTER",
          value: {
            a!richTextIcon(icon: "hand-pointer-o", color: "#9AA6B3", size: "MEDIUM"),
            char(10),
            char(10),
            a!richTextItem(text: "Select a row to review the case", color: "#454F5C", style: "STRONG", size: "STANDARD"),
            char(10),
            a!richTextItem(
              text: "The rail shows the timing arithmetic, the risk profile and the agent's recommended action for whichever trade you pick.",
              color: "#6E7885",
              size: "SMALL"
            )
          }
        )
      ),

      /* ============ IDENTITY — "what is it" and "how long have I got" ======= */
      a!cardLayout(
        showWhen: local!has,
        padding: "LESS",
        style: "#EEF4FA",
        showBorder: false,
        contents: {
          /* IDENTITY ROW — and its shape is a bug fix, not a preference.
             The ticker once carried MEDIUM_PLUS inside a side-by-side whose
             OTHER item was width MINIMIZE. MINIMIZE takes whatever it needs
             first; the oversized countdown beside it took most of a 320px
             rail, and the ticker was left so little room that it rendered ONE
             CHARACTER PER LINE. Three things stop that recurring:
               - MEDIUM is the CEILING of this rail, not a step on the way up
                 (mockup .tick is 15px, the single largest thing in the panel),
                 and the countdown beside it is no longer competing for width;
               - preventWrapping on the ticker line, so it can never break
                 apart into characters whatever the width;
               - the instrument name moved OUT of this row onto its own
                 full-width line beneath, so a long name has the whole rail
                 to wrap across instead of widening this one.
             A graceful "drop the countdown below when it will not fit" was the
             intended fourth guard and IS NOT AVAILABLE: `shouldWrap` appears in
             a!sideBySideLayout's RENDERED TREE and validateExpression accepts
             it with no errors, but the object validator rejects it outright —
             "Unrecognized Keyword ... shouldWrap" (MEASURED; same trap class as
             contentsWidth on a!headerContentLayout and truncateText on a grid
             column). So the row cannot reflow, and instead the sizes are chosen
             to fit: at MEDIUM the longest ticker on the book, "CHFJPY 1M FWD",
             sits comfortably beside the countdown's MINIMIZE column, and
             preventWrapping guarantees that if a future value ever does not
             fit it CLIPS rather than breaking into characters. */
          /* LINE 1 — TICKER, and the chip beside it only when it fits.
             See local!tickerFitsBesideChip for why this is a length test rather
             than a reflow: the layout cannot reflow, so the decision is made in
             the expression. Two arrangements, one rule — the ticker never
             shares the line with anything that could push it out. */
          a!sideBySideLayout(
            showWhen: local!tickerFitsBesideChip,
            alignVertical: "MIDDLE",
            items: {
              a!sideBySideItem(
                item: rule!SO_railTicker(row: local!r, showWhen: true)
              ),
              a!sideBySideItem(
                width: "MINIMIZE",
                item: rule!SO_railCutoffChip(row: local!r, isPast: local!isPast, align: "RIGHT", showWhen: true)
              )
            }
          ),
          /* Long ticker: it takes the line alone, chip beneath it. */
          rule!SO_railTicker(row: local!r, showWhen: not(local!tickerFitsBesideChip)),
          rule!SO_railCutoffChip(
            row: local!r,
            isPast: local!isPast,
            align: "LEFT",
            showWhen: not(local!tickerFitsBesideChip)
          ),

          /* LINE 2 — full instrument name left, status pill right.
             THE TRADE ID / CASE ID LINE IS DELIBERATELY GONE. The trade id is
             already on the selected row immediately to the left of this rail,
             and the case id is internal plumbing that means nothing to an
             analyst. Both still appear on Case Detail, where the record is the
             subject rather than the preview. The status pill was the only real
             information on that line, so it moves here. */
          a!sideBySideLayout(
            alignVertical: "MIDDLE",
            marginBelow: "STANDARD",
            items: {
              a!sideBySideItem(
                item: a!richTextDisplayField(
                  labelPosition: "COLLAPSED",
                  value: a!richTextItem(
                    text: index(local!r, "instrumentName", ""),
                    size: "SMALL",
                    color: "#454F5C"
                  )
                )
              ),
              a!sideBySideItem(
                width: "MINIMIZE",
                item: a!tagField(
                  labelPosition: "COLLAPSED",
                  tags: a!tagItem(
                    text: index(local!r, "statusLabel", ""),
                    backgroundColor: index(local!r, "statusColor", "#454F5C")
                  )
                )
              )
            }
          ),
          a!columnsLayout(
            columns: {
              a!columnLayout(contents: {
                rule!SO_railFact(
                  key: if(index(local!r, "hasQuantity", false), "Position", "Side"),
                  val: if(
                    index(local!r, "hasQuantity", false),
                    index(local!r, "direction", "") & " " & index(local!r, "quantityDisplay", ""),
                    index(local!r, "direction", "")
                  ),
                  warn: false, sub: "", showWhen: true
                ),
                rule!SO_railFact(key: "Counterparty", val: index(local!r, "counterparty", ""), warn: false, sub: "", showWhen: true)
              }),
              a!columnLayout(contents: {
                rule!SO_railFact(
                  key: if(index(local!r, "hasQuantity", false), "Value", "Notional"),
                  val: index(local!r, "valueDisplay", ""),
                  warn: false, sub: "", showWhen: true
                ),
                rule!SO_railFact(
                  key: "Settles",
                  val: index(local!r, "settlesDisplay", "—"),
                  warn: false, sub: "", showWhen: true
                )
              })
            }
          )
        }
      ),

      /* ============ TIMING — "how long have I got, and does it fit" ======== */
      a!cardLayout(
        showWhen: local!has,
        padding: "LESS",
        style: "NONE",
        showBorder: false,
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            marginBelow: "STANDARD",
            value: a!richTextItem(text: "TIMING", color: "#454F5C", size: "SMALL", style: "STRONG")
          ),

          /* ---------- PAST CUTOFF ----------
             The chip above already said "Past cutoff · missed 09:00", so this
             states only the CONSEQUENCE and the lag pair. Saying the clock time
             twice in a 320px rail is noise, not emphasis. */
          a!richTextDisplayField(
            showWhen: local!isPast,
            labelPosition: "COLLAPSED",
            marginBelow: "STANDARD",
            value: {
              a!richTextItem(text: "Past cutoff", color: "#B3261E", style: "STRONG", size: "STANDARD"),
              a!richTextItem(
                text: " — fail management, not remediation.",
                color: "#1B2330",
                size: "STANDARD"
              )
            }
          ),
          rule!SO_railFact(
            showWhen: local!isPast,
            key: "Broker confirmation lag",
            val: local!lagText,
            warn: false, sub: ""
          ),

          /* ---------- LIVE: two native bars, one shared scale ---------- */
          a!progressBarField(
            showWhen: not(local!isPast),
            label: "Remaining to cutoff   " & index(local!r, "countdown", ""),
            labelPosition: "ABOVE",
            percentage: local!remainPct,
            color: index(local!r, "cutoffColor", "#2E5A88"),
            style: "THIN",
            showPercentage: false,
            marginBelow: "STANDARD"
          ),
          a!progressBarField(
            showWhen: not(local!isPast),
            label: "Broker confirmation lag   " & local!lagText,
            labelPosition: "ABOVE",
            percentage: local!lagPct,
            color: "#96590A",
            style: "THIN",
            showPercentage: false,
            marginBelow: "STANDARD"
          ),

          /* ---------- THE ONE SENTENCE ----------
             The rail's entire prose budget outside the agent's own reasoning.
             CLAUDE.md makes the arithmetic mandatory: lag against hours
             remaining, BOTH stated — a verdict without its two numbers is not
             reviewable. Only reachable when the cutoff is in the future, so
             every value below is positive and safe to format. */
          a!richTextDisplayField(
            showWhen: not(local!isPast),
            labelPosition: "COLLAPSED",
            value: if(
              a!isNullOrEmpty(index(local!r, "lagFits", null)),
              a!richTextItem(
                text: "Timing cannot be assessed — the trade has no confirmation lag or no cutoff recorded.",
                color: "#6E7885",
                size: "STANDARD"
              ),
              if(
                index(local!r, "lagFits", false),
                {
                  a!richTextItem(text: "Fits the window", color: "#17715B", style: "STRONG", size: "STANDARD"),
                  a!richTextItem(
                    text: " — confirmation takes " & text(round(local!lag, 1), "0.0")
                      & "h against " & text(round(local!hrsLeft, 1), "0.0")
                      & "h remaining, completing about "
                      & text(round(a!defaultValue(index(local!r, "lagSlackHrs", 0), 0), 1), "0.0")
                      & "h before cutoff.",
                    color: "#1B2330",
                    size: "STANDARD"
                  )
                },
                {
                  a!richTextItem(text: "Does not fit the window", color: "#B3261E", style: "STRONG", size: "STANDARD"),
                  a!richTextItem(
                    text: " — confirmation takes " & text(round(local!lag, 1), "0.0")
                      & "h against only " & text(round(local!hrsLeft, 1), "0.0")
                      & "h remaining, so the remediation cannot complete before cutoff.",
                    color: "#1B2330",
                    size: "STANDARD"
                  )
                }
              )
            )
          )
        }
      ),

      /* ============ RISK PROFILE — "how bad is it" · Snowflake-served ====== */
      a!cardLayout(
        showWhen: local!has,
        padding: "LESS",
        style: "NONE",
        showBorder: false,
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            marginBelow: "STANDARD",
            tooltip: "Every figure in this panel is read live from Snowflake — the model's prediction and the counterparty's settlement history.",
            value: {
              a!richTextItem(text: "RISK PROFILE   ", color: "#454F5C", size: "SMALL", style: "STRONG"),
              rule!SO_snowflakeMark(showWhen: true),
              a!richTextItem(text: " live read", color: "#3E7396", size: "SMALL", style: "STRONG")
            }
          ),
          /* EXCEPTION 2, probability half — rendered inline rather than
             through SO_railFact, because it is a named one-off and giving that
             object a size parameter is exactly what produced the deleted tier.
             The VALUE is MEDIUM in the prediction's own TIER colour (the
             mockup's .t-critical / .t-high / .t-medium); the tier WORD stays
             STANDARD in the same colour, because it is context, not the
             number. "83%" is three characters — it cannot wrap. */
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            marginBelow: "STANDARD",
            value: {
              a!richTextItem(text: "Fail probability", color: "#6E7885", size: "SMALL"),
              char(10),
              a!richTextItem(
                text: index(local!r, "probDisplay", "—"),
                color: index(local!r, "tierColor", "#4A5462"),
                style: "STRONG",
                size: "MEDIUM"
              ),
              a!richTextItem(
                text: "  ·  " & index(local!r, "riskTier", "") & " tier",
                color: index(local!r, "tierColor", "#4A5462"),
                style: "STRONG",
                size: "STANDARD"
              )
            }
          ),
          rule!SO_railFact(
            key: "Predicted reason",
            val: index(local!r, "failReasonLabel", "—"),
            warn: false, sub: "", showWhen: true
          ),
          rule!SO_railFact(
            key: "Counterparty fail history",
            val: if(
              a!isNullOrEmpty(index(local!r, "cptyFailRate", null)),
              "—",
              text(round(100 * todecimal(index(local!r, "cptyFailRate", 0)), 1), "0.0") & "%"
            ),
            sub: if(
              a!isNullOrEmpty(index(local!r, "cptyFailRate", null)),
              "",
              "·  12 mo  ·  " & index(local!r, "cptyRiskTier", "") & " tier"
            ),
            warn: false,
            showWhen: true
          )
        }
      ),

      /* ============ RECOMMENDED ACTION — "what do I do" ==================== */
      a!cardLayout(
        showWhen: local!has,
        padding: "LESS",
        style: "NONE",
        showBorder: false,
        contents: a!cardLayout(
          padding: "LESS",
          style: "#F7FAFC",
          showBorder: true,
          shape: "SEMI_ROUNDED",
          contents: {
            /* UNSCORED: ONE LINE, and nothing else. No action title, no lane,
               no score bar, no empty WHY. A case that has not been triaged has
               no recommendation, and a card that renders the frame around an
               absent recommendation reads as a broken screen. */
            a!richTextDisplayField(
              showWhen: not(local!scored),
              labelPosition: "COLLAPSED",
              value: a!richTextItem(
                text: "Not yet scored",
                color: "#6E7885",
                style: "STRONG",
                size: "STANDARD"
              )
            ),

            a!richTextDisplayField(
              showWhen: local!scored,
              labelPosition: "COLLAPSED",
              marginBelow: "STANDARD",
              value: {
                a!richTextItem(text: "RECOMMENDED ACTION", color: "#454F5C", size: "SMALL", style: "STRONG"),
                char(10),
                a!richTextItem(
                  text: a!defaultValue(index(local!r, "remediation", ""), "Not yet proposed"),
                  color: "#1B2330",
                  style: "STRONG",
                  size: "STANDARD"
                )
              }
            ),
            /* THE LANE, FROM THE STORED STATUS. The pill says what happened to
               the case; the line says what the gate arithmetic was. Where the
               two diverge — a high score that was escalated by reason override
               — laneNote says so out loud rather than leaving the screen
               looking self-contradictory. The word "confidence" appears
               nowhere; the gate figure comes from the live constant through
               SO_autoReleaseDisplay, never a literal 80. */
            a!richTextDisplayField(
              showWhen: local!scored,
              labelPosition: "COLLAPSED",
              marginBelow: "STANDARD",
              value: {
                a!richTextItem(
                  text: index(local!r, "arPill", ""),
                  color: local!laneColor,
                  size: "STANDARD",
                  style: "STRONG"
                ),
                a!richTextItem(
                  text: char(10),
                  showWhen: index(local!r, "arHasScore", false)
                ),
                /* The canon phrase at ONE size, with only the number carrying
                   weight. "Auto-release score 85, releases at 80" — word order
                   and wording unchanged; the emphasis is bold, not scale. */
                a!richTextItem(
                  text: "Auto-release score ",
                  color: "#454F5C",
                  size: "STANDARD",
                  showWhen: index(local!r, "arHasScore", false)
                ),
                a!richTextItem(
                  text: index(local!r, "arScore", 0),
                  color: "#1B2330",
                  size: "STANDARD",
                  style: "STRONG",
                  showWhen: index(local!r, "arHasScore", false)
                ),
                a!richTextItem(
                  text: ", releases at " & index(local!r, "arGate", 80),
                  color: "#454F5C",
                  size: "STANDARD",
                  showWhen: index(local!r, "arHasScore", false)
                ),
                a!richTextItem(
                  text: char(10),
                  showWhen: not(a!isNullOrEmpty(index(local!r, "arLaneNote", "")))
                ),
                a!richTextItem(
                  text: index(local!r, "arLaneNote", ""),
                  color: "#454F5C",
                  size: "SMALL",
                  showWhen: not(a!isNullOrEmpty(index(local!r, "arLaneNote", "")))
                )
              }
            ),
            a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              showWhen: and(local!scored, index(local!r, "arHasScore", false)),
              preventWrapping: true,
              marginBelow: "STANDARD",
              value: a!forEach(
                items: enumerate(local!arCells) + 1,
                expression: a!richTextItem(
                  /* The gate marker sits ON the bar, in the same cell
                     arithmetic as the fill, so the two cannot drift apart. */
                  text: if(fv!item = local!arGateCell, "┃", "▇"),
                  color: if(
                    fv!item = local!arGateCell,
                    "#1B2330",
                    if(fv!item <= local!arFill, local!laneColor, "#E9EDF2")
                  )
                )
              )
            ),
            /* AI ATTRIBUTION IS GOVERNANCE, NOT DECORATION. This card renders
               text a model wrote, and a screen that shows machine-authored
               reasoning without saying so is making an implicit claim about
               its provenance. The attribution line REPLACES the old "WHY"
               label rather than sitting beside it: one line, naming the agent
               and when it ran, is both the label and the disclosure.
               The chip is a tagField because rich text has no background —
               #E7F0F6 on Snowflake blue, the mockup's .chead .aichip. */
            a!sideBySideLayout(
              showWhen: local!scored,
              alignVertical: "MIDDLE",
              marginBelow: "STANDARD",
              items: {
                a!sideBySideItem(
                  width: "MINIMIZE",
                  item: a!tagField(
                    labelPosition: "COLLAPSED",
                    tags: a!tagItem(text: "AI", backgroundColor: "#E7F0F6", textColor: "#3E7396")
                  )
                ),
                a!sideBySideItem(
                  item: a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(
                      text: "SO Triage Agent"
                        & if(
                          a!isNullOrEmpty(ri!assessmentAt),
                          "",
                          "  ·  " & text(ri!assessmentAt, "hh:mm")
                        ),
                      color: "#6E7885",
                      size: "SMALL"
                    )
                  )
                )
              }
            ),
            a!richTextDisplayField(
              showWhen: local!scored,
              labelPosition: "COLLAPSED",
              value: a!richTextItem(
                text: local!whyText,
                color: "#1B2330",
                size: "STANDARD"
              )
            )
          }
        )
      ),

      /* ============ ACTIONS ============
         STATUS-AWARE. An escalated case is out of the analyst's hands — it is
         a supervisor's credit decision now — so offering Assign on it invites
         an action the workflow does not want. Same for a resolved case: there
         is nothing left to assign. Both keep Open case, because reading the
         full record is always legitimate. */
      a!cardLayout(
        showWhen: local!has,
        padding: "LESS",
        style: "NONE",
        showBorder: false,
        contents: a!sideBySideLayout(
          alignVertical: "MIDDLE",
          items: {
            a!sideBySideItem(
              showWhen: index(local!r, "canAssign", false),
              item: a!recordActionField(
                actions: a!recordActionItem(
                  action: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case.actions.{53d0adce-7e74-40dc-97e8-7b1b2e63d8dc}assignCase',
                  identifier: index(local!r, "caseId", null)
                ),
                style: "TOOLBAR_PRIMARY"
              )
            ),
            a!sideBySideItem(
              item: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                align: "RIGHT",
                /* A RecordLink is NOT a valid rich-text value on its own; it
                   goes in a richTextItem's link parameter (MEASURED — passing
                   it as value fails with "Received RecordLink"). */
                value: a!richTextItem(
                  text: "Open case →",
                  style: "STRONG",
                  size: "STANDARD",
                  link: a!recordLink(
                    recordType: 'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case',
                    identifier: index(local!r, "caseId", null)
                  )
                )
              )
            )
          }
        )
      )
    }
  )
)
