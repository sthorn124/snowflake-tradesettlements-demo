/*
 * SO_autoReleaseDisplay — the analyst-facing rendering of the confidence gate.
 *
 * CLAUDE.md display vocabulary, and the reason this rule exists: the word
 * "confidence" is GOVERNANCE-screen vocabulary, not analyst-screen vocabulary.
 * Analyst- and supervisor-facing screens say
 *     "Auto-release score 68, releases at 80"
 * and nothing on those screens says "confidence" at all.
 *
 * THE LANE IS READ FROM THE STORED STATUS. IT IS NEVER RE-DERIVED FROM THE
 * SCORE, AND THAT IS THE WHOLE CORRECTION IN THIS VERSION.
 * The pill used to be `if(score >= gate, "Released without touch", "Held for
 * review")`. That is a re-decision, not a rendering, and it disagreed with the
 * record the moment the two could differ — which they can, because the gate is
 * not the only thing that routes a case. A REASON OVERRIDE BINDS REGARDLESS OF
 * SCORE: counterparty_default always goes to a human credit decision, so a
 * case can legitimately carry a high score AND be Escalated. Rendered from the
 * score, such a case announced "Released without touch · score 95" on a screen
 * whose own status chip said Escalated and whose reasoning panel said no
 * assessment existed (observed on a click-through, case SO-43).
 *
 * So: status decides the LANE and the colour; the score decides only the
 * ARITHMETIC LINE and the bar fill fraction, which are facts about the gate and
 * remain true whichever way the case was routed. A screen may show that a case
 * scored 86 and was escalated anyway — that is the governance story. It may
 * never claim the case was released when the record says it was not.
 *
 * The gate is read LIVE from cons!SO_CONFIDENCE_THRESHOLD, never written as the
 * literal 80, because the threshold is demo-tunable: changing the constant must
 * visibly change both the number on the screen and which side of it a case
 * falls, in the same breath.
 *
 * round() before text() (§4: text() truncates), so a stored 0.679 renders as
 * score 68 rather than 67.
 */
a!localVariables(
  local!raw: todecimal(ri!confidenceScore),
  local!hasScore: not(a!isNullOrEmpty(local!raw)),
  local!score: tointeger(round(100 * a!defaultValue(local!raw, 0), 0)),
  local!gate: tointeger(round(100 * todecimal(a!defaultValue(cons!SO_CONFIDENCE_THRESHOLD, 0.8)), 0)),
  local!status: a!defaultValue(ri!status, ""),

  /* The four lanes an analyst can see, keyed to the STORED status. "unscored"
     is a lane too: it is what a case looks like before triage has run, and the
     rail collapses its whole recommendation card to a single line for it
     rather than showing an empty action, an empty lane and an empty bar. */
  local!lane: a!match(
    value: local!status,
    equals: "Escalated", then: "ESCALATED",
    equals: "Resolved - Straight Through", then: "RELEASED",
    default: if(local!hasScore, "HELD", "UNSCORED")
  ),

  a!map(
    hasScore: local!hasScore,
    score: local!score,
    gate: local!gate,
    lane: local!lane,
    /* cleared is now strictly "the score cleared the gate" — an arithmetic
       fact, no longer a claim about what happened to the case. Only the
       arithmetic line uses it; the lane never does. */
    cleared: and(local!hasScore, local!score >= local!gate),

    /* The pill states the lane in the analyst's words. */
    pill: a!match(
      value: local!lane,
      equals: "ESCALATED", then: "Escalated to supervisor",
      equals: "RELEASED", then: "Released without touch",
      equals: "HELD", then: "Held for review",
      default: "Not yet scored"
    ),
    pillColor: a!match(
      value: local!lane,
      equals: "ESCALATED", then: "#B3261E",
      equals: "RELEASED", then: "#17715B",
      equals: "HELD", then: "#96590A",
      default: "#6E7885"
    ),

    /* The arithmetic line. EMPTY when there is no score: `pill` already says
       "Not yet scored", and returning the same words here made the rail print
       the phrase twice on a New case. With no score there is no arithmetic. */
    line: if(
      local!hasScore,
      "Auto-release score " & local!score & ", releases at " & local!gate,
      ""
    ),
    /* Said out loud only where the two genuinely diverge, so the screen
       explains itself instead of looking broken. */
    laneNote: if(
      and(local!lane = "ESCALATED", local!score >= local!gate),
      "Score cleared the gate; the fail reason routes this to a human anyway.",
      ""
    ),

    scoreFraction: local!score / 100,
    gateFraction: local!gate / 100
  )
)
