/*
 * SO_askAnswerText — the last guard between a Snowflake reply and the screen.
 *
 * IT DOES NOT PARSE, AND IT DOES NOT FILTER NARRATION. Two deliberate limits:
 *
 *   1. NO PARSING. SNOWFLAKE.CORTEX.DATA_AGENT_RUN returns the whole agent
 *      transcript as one JSON string, and it arrived TRUNCATED AT EXACTLY 4000
 *      CHARACTERS (measured 2026-09-24) — never valid JSON, so a!fromJson threw
 *      and took the whole page down. Extraction moved into SO_askSnowflake's own
 *      SELECT, so the answer text arrives plain and the agent's reasoning never
 *      leaves Snowflake. A rule whose contract is "degrades to empty, never to an
 *      error" must contain no function that errors on bad input, and this one now
 *      contains none.
 *   2. NO NARRATION FILTERING. The agent narrating its own process ("There's a
 *      verified query for exactly this", "Let me run it") is a REAL defect, and it
 *      is fixed in the agent's instructions, not here. Any display-side filter
 *      would have to guess which sentences are narration, and the cost of a wrong
 *      guess is deleting answer prose — silently. Formatting is safe to normalise;
 *      meaning is not.
 *
 * WHAT IT DOES FIX is presentation only, both reported from the browser:
 *   - MARKDOWN EMPHASIS. The agent emits **bold**, which SAIL rich text renders
 *     literally as asterisks. Only UNAMBIGUOUS markers are stripped: **, __ and
 *     backticks. A single * is left alone on purpose — it can be a footnote or a
 *     multiplication sign, and stripping it would corrupt an answer to fix a
 *     cosmetic.
 *   - BLANK-LINE RUNS. Answers arrived with four to six consecutive newlines. The
 *     lines are split, trimmed, emptied ones dropped, and the survivors rejoined
 *     with exactly one blank line between them — so spacing is normalised by
 *     construction rather than by chasing run lengths with repeated substitutions.
 */
a!localVariables(
  local!raw: if(a!isNullOrEmpty(ri!raw), "", ri!raw),

  local!demarked: substitute(
    substitute(
      substitute(local!raw, "**", ""),
      "__", ""
    ),
    "`", ""
  ),

  local!lines: reject(
    a!isNullOrEmpty,
    a!forEach(
      items: split(local!demarked, char(10)),
      expression: trim(fv!item)
    )
  ),

  if(
    a!isNullOrEmpty(local!lines),
    "",
    trim(joinarray(local!lines, char(10) & char(10)))
  )
)
