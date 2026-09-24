/*
 * SO_askPanel — the Ask panel, built ONCE and used by both screens.
 *
 * WHY ONE RULE FOR TWO PANELS: the analyst and the supervisor ask the same
 * system the same way; what differs is SCOPE, and scope is a parameter. The
 * supervisor asks across the book, the analyst asks about the case in front of
 * her, so the caller passes a contextLine that is prepended to the question.
 * Nothing else about the two panels differs, and nothing else should.
 *
 * ================= THE THREE STATES =================
 * IDLE      — no question submitted yet. A prompt, nothing more.
 * ANSWERED  — answer text came back. Rendered with the provenance line.
 * FAILED    — the call did not produce an answer. ONE PLAIN LINE, no stack
 *             trace, no JSON, no "contact your administrator". A panel that
 *             hangs or vomits a trace in front of an audience is worse than no
 *             panel, so the failure path gets the same care as the success one:
 *             it says what happened, that the rest of the screen is unaffected,
 *             and invites a retry.
 *
 * ASKING is NOT a fourth rendered state, and pretending otherwise would be a
 * lie about how this evaluates. The call is synchronous: Appian blocks the
 * evaluation until Snowflake answers, so no intermediate local can render
 * mid-flight. Visible progress is whatever the PLATFORM paints while an
 * evaluation is in flight, and that is all it can be.
 * MEASURED 2026-09-24: a!buttonWidget's `enableLoadingIndicator` is NOT a
 * settable keyword — the object validator rejects it outright ("Unrecognized
 * Keyword") even though it appears as an attribute in a rendered button's
 * component tree. So there is no per-button spinner to add here. Do not add a
 * fake "Thinking…" local either: a synchronous evaluation would never paint it.
 *
 * ================= PROVENANCE =================
 * Every answer carries the snowchip and a line naming where it was computed.
 * This is the same governance rule as the AI attribution on agent-authored
 * content: a screen that renders machine-written prose without saying so is
 * making an implicit claim about where it came from. The agent's own internal
 * reasoning and generated SQL are deliberately NOT shown (SO_askAnswerText
 * keeps only type:"text"): working-out is not a finding.
 */
a!localVariables(
  local!draft: "",
  local!submitted: null,

  /* ================= WHY THE CALL IS DRIVEN FROM A saveInto =================
     It was first built as a QUERY-usage integration inside an a!refreshVariable
     keyed to the submitted question. That is the tidier expression, and it is
     WRONG HERE, for two reasons measured on 2026-09-24:
       1. APPIAN CACHES A QUERY-USAGE INTEGRATION'S RESPONSE. Pressing the same
          question again returned in 1s carrying the PREVIOUS body - on a FRESH
          page load, and after the integration's own SQL had been changed. So
          "ask it again" silently did not ask, and a three-run stability check
          would have scored three identical answers as a pass without a second
          call ever leaving Appian.
       2. refreshOnVarChange never fires for an unchanged value, so pressing the
          same chip twice was a no-op even before the cache.
     MODIFY usage is not cached and runs on every press. Note what that flag is
     and is not: it governs CACHING and process behaviour, NOT permissions. The
     read-only guarantee rests entirely on the statement being a single SELECT
     with the question passed as a BINDING (see SO_askSnowflake), never on this
     keyword. */
  local!answered: false,
  local!ok: false,
  local!answer: "",
  local!failed: false,

  a!cardLayout(
    padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true, marginBelow: "STANDARD",
    decorativeBarPosition: "TOP", decorativeBarColor: "#3E7396",
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          rule!SO_snowflakeMark(showWhen: true),
          a!richTextItem(text: "  " & ri!title, color: "#454F5C", size: "SMALL", style: "STRONG")
        }
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED", marginBelow: "STANDARD",
        value: a!richTextItem(text: ri!blurb, color: "#6E7885", size: "SMALL")
      ),

      /* THE CHIPS ARE THE SEEDED QUESTIONS, and pressing one submits it.
         They are links rather than tags now: a tag cannot be pressed, and an
         unpressable suggestion on a live panel is the same unfinished tell the
         disabled text field used to be. */
      a!forEach(
        items: ri!questions,
        expression: a!richTextDisplayField(
          labelPosition: "COLLAPSED", marginBelow: "LESS",
          value: a!richTextItem(
            text: "•  " & fv!item,
            color: "#2E5A88", size: "SMALL",
            link: a!dynamicLink(
              value: fv!item,
              saveInto: {
                a!save(local!draft, fv!item),
                a!save(local!submitted, fv!item),
                rule!SO_askSnowflake(
                  question: if(a!isNullOrEmpty(ri!contextLine), fv!item, ri!contextLine & "  " & fv!item),
                  onSuccess: {
                    a!save(local!answered, true),
                    a!save(local!ok, true),
                    a!save(local!answer, rule!SO_askAnswerText(raw: a!defaultValue(index(index(index(index(fv!result, "body", null), "data", null), 1, null), 1, ""), ""))),
                    a!save(local!failed, a!isNullOrEmpty(rule!SO_askAnswerText(raw: a!defaultValue(index(index(index(index(fv!result, "body", null), "data", null), 1, null), 1, ""), ""))))
                  },
                  onError: {
                    a!save(local!answered, true),
                    a!save(local!ok, false),
                    a!save(local!answer, ""),
                    a!save(local!failed, true)
                  }
                )
              }
            ),
            linkStyle: "STANDALONE"
          )
        )
      ),

      /* ---------- THE ANSWER AREA ---------- */
      a!cardLayout(
        padding: "STANDARD", shape: "SEMI_ROUNDED", style: "#FAFBFC", showBorder: false,
        marginAbove: "STANDARD", marginBelow: "STANDARD",
        contents: {
          /* IDLE */
          a!richTextDisplayField(
            showWhen: not(local!answered),
            labelPosition: "COLLAPSED",
            value: a!richTextItem(text: ri!idleText, color: "#6E7885", size: "SMALL")
          ),
          /* ANSWERED */
          a!richTextDisplayField(
            showWhen: and(local!answered, not(local!failed)),
            labelPosition: "COLLAPSED", marginBelow: "STANDARD",
            value: a!richTextItem(text: local!submitted, color: "#1B2330", size: "SMALL", style: "STRONG")
          ),
          a!richTextDisplayField(
            showWhen: and(local!answered, not(local!failed)),
            labelPosition: "COLLAPSED", marginBelow: "STANDARD",
            value: a!richTextItem(text: local!answer, color: "#1B2330", size: "STANDARD")
          ),
          a!richTextDisplayField(
            showWhen: and(local!answered, not(local!failed)),
            labelPosition: "COLLAPSED",
            value: {
              rule!SO_snowflakeMark(showWhen: true),
              a!richTextItem(
                text: "  Computed in Snowflake by Cortex over the live book — nothing copied, nothing synced.",
                color: "#6E7885", size: "SMALL"
              )
            }
          ),
          /* FAILED — one plain line. */
          a!richTextDisplayField(
            showWhen: local!failed,
            labelPosition: "COLLAPSED",
            value: a!richTextItem(
              text: "Snowflake did not return an answer. Nothing else on this screen is affected — ask again, or carry on.",
              color: "#96590A", size: "SMALL"
            )
          )
        }
      ),

      a!textField(
        labelPosition: "COLLAPSED",
        placeholder: ri!placeholder,
        value: local!draft,
        saveInto: local!draft,
        refreshAfter: "UNFOCUS",
        marginBelow: "LESS"
      ),
      a!buttonArrayLayout(
        align: "START", marginBelow: "NONE",
        buttons: a!buttonWidget(
          label: "Ask",
          size: "SMALL",
          style: "OUTLINE",
          disabled: a!isNullOrEmpty(local!draft),
          saveInto: {
                a!save(local!submitted, local!draft),
                rule!SO_askSnowflake(
                  question: if(a!isNullOrEmpty(ri!contextLine), local!draft, ri!contextLine & "  " & local!draft),
                  onSuccess: {
                    a!save(local!answered, true),
                    a!save(local!ok, true),
                    a!save(local!answer, rule!SO_askAnswerText(raw: a!defaultValue(index(index(index(index(fv!result, "body", null), "data", null), 1, null), 1, ""), ""))),
                    a!save(local!failed, a!isNullOrEmpty(rule!SO_askAnswerText(raw: a!defaultValue(index(index(index(index(fv!result, "body", null), "data", null), 1, null), 1, ""), ""))))
                  },
                  onError: {
                    a!save(local!answered, true),
                    a!save(local!ok, false),
                    a!save(local!answer, ""),
                    a!save(local!failed, true)
                  }
                )
              }
        )
      )
    }
  )
)
