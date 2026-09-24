/*
 * SO_askAnswerText — the last guard between a Snowflake reply and the screen.
 *
 * IT USED TO PARSE JSON HERE, AND THAT WAS THE WRONG PLACE — measured 2026-09-24.
 * SNOWFLAKE.CORTEX.DATA_AGENT_RUN returns the WHOLE agent transcript as one JSON
 * string: the answer, plus every "thinking" and "tool_use" element. That
 * transcript arrived at Appian TRUNCATED AT EXACTLY 4000 CHARACTERS, so it was
 * never valid JSON, and a!fromJson threw — which took the entire supervisor page
 * down rather than showing a failure state. Two lessons, both now designed in:
 *
 *   1. THE ANSWER IS EXTRACTED IN SNOWFLAKE, not here. SO_askSnowflake's
 *      statement flattens the reply and keeps only the type:"text" elements, so
 *      what crosses the wire is the answer alone — comfortably under the cap,
 *      because the bulk of a transcript is reasoning, not answer. The agent's
 *      working-out now never leaves Snowflake at all, which is a better answer
 *      to "don't show working-out as findings" than filtering it on arrival.
 *   2. THIS RULE NO LONGER PARSES ANYTHING, so it can no longer throw. It trims
 *      and it guards. A rule whose stated contract is "degrades to empty, never
 *      to an error" must not contain a function that errors on bad input.
 *
 * Returns "" for anything empty, and the caller renders its failure state.
 */
a!localVariables(
  local!t: if(a!isNullOrEmpty(ri!raw), "", trim(ri!raw)),
  if(a!isNullOrEmpty(local!t), "", local!t)
)
