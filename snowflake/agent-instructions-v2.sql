-- =====================================================================
-- SETTLEMENT_RISK_AGENT — response instructions, v2
-- Authored 2026-09-24 (Phase 6 Part 1d). RUN THIS ONCE IN SNOWSIGHT.
-- Worksheet role FINSERVADMIN, warehouse COMPUTE_WH.
--
-- WHAT THIS CHANGES
--   instructions.response, and nothing else. v1's rules are all kept; two new
--   rules are added, each fixing a defect measured on a live screen:
--
--   1. ASSET CLASSES AS DISPLAY LABELS, NEVER STORED CODES.
--      v1 answers rendered "fx_forward", "etf" and "bond" on an analyst screen.
--      The project's display-vocabulary canon requires every enum reaching a
--      screen to pass through a named display rule, and the panel cannot do that
--      to prose without parsing it. So the agent is told to write the labels.
--   2. NEVER SUM NOTIONALS ACROSS CURRENCIES.
--      v1 answered "total notional at risk" as "25.62 billion" with no unit,
--      adding EUR, GBP, JPY and CHF together. The project already ruled that a
--      house value-at-risk is NOT computable from the source data, because
--      nothing in it carries an FX rate - which is why every screen figure goes
--      through SO_fxToUsd and renders "USD eq." with its basis. An unlabelled
--      cross-currency sum is a number a settlements audience can falsify.
--      Supervisor chip 3 now asks "...by currency?" so the honest answer is also
--      the natural one.
--
--   NOTE ON NARRATION: v1 told the agent not to describe its own process, and it
--   still did on 5 of 21 runs. That is NOT fixed by instruction text and is not
--   re-attempted here - it is now handled downstream, in SO_askSnowflake, which
--   keeps only the text elements AFTER the last tool_result. Measured over six
--   runs: narration always precedes that boundary, the answer always follows it.
--   The prohibition stays in the instructions as a belt-and-braces measure, but
--   the guarantee lives in the extraction.
--
-- WHAT THIS PRESERVES — AND WHY THE WHOLE SPEC IS RESTATED
--   ALTER AGENT ... MODIFY LIVE VERSION SET SPECIFICATION REPLACES the
--   specification wholesale: per Snowflake's documentation, "the new
--   specification completely replaces the existing one. Fields that are not
--   included in the new specification are removed." There is no partial edit.
--   Every other field below is reproduced EXACTLY as DESCRIBE AGENT returned it
--   on 2026-09-24, character for character:
--     - tools:          one cortex_analyst_text_to_sql tool, "SettlementAnalyst",
--                       description unchanged
--     - tool_resources: semantic_view FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS,
--                       warehouse COMPUTE_WH, query_timeout 299
--     - instructions.orchestration:    unchanged
--     - instructions.sample_questions: all five, unchanged
--   The agent carries no "models" block and no top-level "orchestration" block;
--   none is added here, because adding one would be a change.
--
--   The agent's ONLY tool remains cortex_analyst_text_to_sql, which is text-to-SQL
--   over a semantic view and cannot emit DML. That is what the read-only argument
--   for the Ask panel rests on. Do not add a tool here without re-opening it.
--
-- EXPECTED RESULT: one row, "Statement executed successfully."
-- =====================================================================

ALTER AGENT FINSERV.TRADE_SETTLEMENT.SETTLEMENT_RISK_AGENT
  MODIFY LIVE VERSION SET SPECIFICATION = $$
{
  "instructions": {
    "response": "You are a trade settlement risk analyst answering a colleague on a settlements desk. Lead with the answer in your first sentence. Keep the whole reply to two to four sentences. Write plain text only: no markdown, no asterisks, no bold, no bullet points, no headings. Never describe your own process - do not mention verified queries, semantic models, logical or physical column names, SQL, tools, or what you are about to do, and never write phrases like 'let me', 'I will look at', 'first I need to', or 'here is'. Never refer to a chart, graph, table or any visual, because the answer is shown as text only and no visual exists. Whenever you give a rate or a percentage, state the numerator and denominator that produced it, for example '24.37 percent, 240 of 985 trades'. Write asset classes as Equity, Bond, ETF and FX forward, and never write a stored code containing an underscore such as fx_forward. Never add notional amounts together across different currencies, because the data carries no exchange rates and the total would be meaningless: report the amount for each currency separately, or give trade counts instead. If the data cannot answer the question, say so in one sentence and stop.",
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
