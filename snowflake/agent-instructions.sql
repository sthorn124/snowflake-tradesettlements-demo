-- =====================================================================
-- SETTLEMENT_RISK_AGENT — response instructions only
-- Authored 2026-09-24 (Phase 6 Part 1b). RUN THIS ONCE IN SNOWSIGHT.
-- Worksheet role FINSERVADMIN, warehouse COMPUTE_WH.
--
-- WHAT THIS CHANGES
--   instructions.response, and nothing else.
--   The live panels render the agent's answer verbatim, so its prose IS the
--   product. Three defects reported from the browser on 2026-09-24:
--     1. Markdown. The agent emits **bold**; SAIL rich text has no markdown
--        renderer, so asterisks appear literally on screen.
--     2. Self-narration. Answers opened with "There's a verified query for
--        exactly this. Let me run it. I need to use the logical column names
--        from the semantic model..." — working-out presented as findings.
--     3. References to charts and visuals the panel cannot render, which read
--        as a broken promise on stage.
--   The panel strips markdown defensively (SO_askAnswerText), but narration
--   cannot be filtered display-side without risking deletion of answer prose.
--   That is why it is fixed here, at the source.
--
-- WHAT THIS PRESERVES — AND WHY THE WHOLE SPEC IS RESTATED
--   ALTER AGENT ... MODIFY LIVE VERSION SET SPECIFICATION REPLACES the
--   specification wholesale: per Snowflake's documentation, "the new
--   specification completely replaces the existing one. Fields that are not
--   included in the new specification are removed." There is no partial edit.
--   So every other field below is reproduced EXACTLY as DESCRIBE AGENT returned
--   it on 2026-09-24, character for character:
--     - tools:          one cortex_analyst_text_to_sql tool, "SettlementAnalyst",
--                       with its description unchanged
--     - tool_resources: semantic_view FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS,
--                       warehouse COMPUTE_WH, query_timeout 299
--     - instructions.orchestration:  unchanged
--     - instructions.sample_questions: all five, unchanged
--   The agent carries no "models" block and no top-level "orchestration" block;
--   none is added here, because adding one would be a change.
--
--   NOTE FOR THE READ-ONLY ARGUMENT: the DESCRIBE confirmed the agent's ONLY
--   tool is cortex_analyst_text_to_sql. That is text-to-SQL over a semantic
--   view and cannot emit DML — which closes the one gap the Part 1 close-out
--   flagged as unverifiable from a session. Do not add a tool here without
--   re-opening that argument.
--
-- EXPECTED RESULT: one row, "Statement executed successfully."
-- =====================================================================

ALTER AGENT FINSERV.TRADE_SETTLEMENT.SETTLEMENT_RISK_AGENT
  MODIFY LIVE VERSION SET SPECIFICATION = $$
{
  "instructions": {
    "response": "You are a trade settlement risk analyst answering a colleague on a settlements desk. Lead with the answer in your first sentence. Keep the whole reply to two to four sentences. Write plain text only: no markdown, no asterisks, no bold, no bullet points, no headings. Never describe your own process - do not mention verified queries, semantic models, logical or physical column names, SQL, tools, or what you are about to do, and never write phrases like 'let me', 'I will look at', 'first I need to', or 'here is'. Never refer to a chart, graph, table or any visual, because the answer is shown as text only and no visual exists. Whenever you give a rate or a percentage, state the numerator and denominator that produced it, for example '24.37 percent, 240 of 985 trades'. If the data cannot answer the question, say so in one sentence and stop.",
    "orchestration": "Use the Analyst tool for all questions about trade settlement data, fail rates, risk tiers, counterparties, and instruments.",
    "sample_questions": [
      {"question": "What is the overall settlement fail rate?"},
      {"question": "Which counterparties have the highest fail rate?"},
      {"question": "How many trades are in each risk tier?"},
      {"question": "What is the total notional value at risk?"},
      {"question": "What is the fail rate by asset class?"}
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "SettlementAnalyst",
        "description": "Analyzes trade settlement data including fail predictions, counterparty risk, and historical outcomes"
      }
    }
  ],
  "tool_resources": {
    "SettlementAnalyst": {
      "semantic_view": "FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "COMPUTE_WH",
        "query_timeout": 299
      }
    }
  }
}
$$;
