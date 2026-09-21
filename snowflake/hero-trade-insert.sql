/* ============================================================================
   hero-trade-insert.sql
   Settlement Operations demo — authored hero trade (Phase 5 packet, slot 01)
   Run in Snowsight as FINSERVADMIN AFTER snowflake-mockup-columns.sql.
   Idempotent: re-running replaces this session's hero rows.
   Written 2026-09-02. Values are the contract in hero-trade-spec.md §1.

   INSERT-ONLY. This script writes two rows into the reserved id range
   TRD9<session><seq> and touches nothing else. No baseline row is read for
   update, modified or deleted. Paired with hero-trade-delete.sql.

   The story: a large SAP buy settling today, predicted to fail on a
   deliver-side shortfall, against a high-risk APAC counterparty, with a broker
   confirmation that fits inside the window. Expected agent outcome is
   HELD FOR REVIEW — confidence below the 0.80 gate, not straight-through and
   not escalated.
   ============================================================================ */

USE ROLE FINSERVADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FINSERV;
USE SCHEMA TRADE_SETTLEMENT;

/* ---------------------------------------------------------------------------
   Session code: 3 uppercase alphanumerics, unique per concurrent SC session.
   Change this and nothing else to run a second session against the same account.
   --------------------------------------------------------------------------- */
SET session_code = 'NY1';
SET hero_id      = 'TRD9' || $session_code || '01';

SELECT $hero_id AS hero_trade_id;   /* expect: TRD9NY101 */

/* Idempotency: clear this session's hero rows before re-inserting.
   Child (prediction) first — 1:1 on TRADE_ID. */
DELETE FROM TRADE_PREDICTIONS WHERE TRADE_ID = $hero_id;
DELETE FROM TRADES            WHERE TRADE_ID = $hero_id;

/* ---------------------------------------------------------------------------
   The trade.
     INS0147 = SAP GY / SAP SE / DE0007164600 / Clearstream (CBF), a genuine
               equity in EUR, so "shares", the German ISIN and the German CSD
               all cohere with a deliver-side shortfall story.
     CP0023  = Diamond Trust: broker, APAC, high tier, 19.89% historical fail
               rate — the mockup's counterparty, with its real profile.
     210,000 shares x 89.05 EUR = 18,700,500 -> renders as "18.7M EUR".
     Lag 1.15h (1h 09m) must stay well under the ~3h to cutoff, or the agent
     escalates on timing instead of holding for review.
   --------------------------------------------------------------------------- */
INSERT INTO TRADES
  (TRADE_ID, TRADE_DATE, EXPECTED_SETTLEMENT_DATE, INSTRUMENT_ID, COUNTERPARTY_ID,
   DIRECTION, NOTIONAL, CURRENCY, BROKER_CONFIRMATION_LAG_HRS, TRADER_ID, DESK,
   QUANTITY, IS_MATCHED, MATCHED_AT)
SELECT
  $hero_id,
  DATEADD(day, -1, CURRENT_DATE),                      /* traded yesterday      */
  CURRENT_DATE,                                        /* settles today, T+1    */
  'INS0147',
  'CP0023',
  'BUY',
  18700500,
  'EUR',
  1.15,
  'TR010',                                             /* existing EQ_FLOW trader */
  'EQ_FLOW',
  210000,
  TRUE,
  DATEADD(minute, 12, DATEADD(hour, 18, TO_TIMESTAMP_NTZ(DATEADD(day, -1, CURRENT_DATE))));
                                                       /* matched 18:12 on trade date */

/* ---------------------------------------------------------------------------
   The prediction. RISK_TIER here is capitalised ('Critical') — TRADE_PREDICTIONS
   and COUNTERPARTIES use different tier vocabularies in the same schema.
   SCORED_AT is the overnight batch time the watchlist header cites.
   --------------------------------------------------------------------------- */
INSERT INTO TRADE_PREDICTIONS (TRADE_ID, FAIL_PROBABILITY, RISK_TIER, SCORED_AT)
SELECT
  $hero_id,
  0.83,
  'Critical',
  DATEADD(hour, 5, TO_TIMESTAMP_NTZ(CURRENT_DATE));    /* today 05:00 */


/* ============================================================================
   VERIFICATION — expected results stated per query
   ============================================================================ */

/* V1. The hero trade as the case detail will read it.
   EXPECTED one row:
     trade_id TRD9NY101 | ticker 'SAP GY' | name 'SAP SE' | isin DE0007164600
     | csd 'Clearstream (CBF)' | counterparty 'Diamond Trust' | cp_tier 'high'
     | cp_fail_rate 0.1989 | direction BUY | quantity 210000.00
     | notional 18700500 | currency EUR | implied_price 89.05
     | lag_hrs 1.15 | desk EQ_FLOW | is_matched TRUE
     | trade_date = yesterday | expected_settlement_date = today */
SELECT t.TRADE_ID, i.TICKER, i.NAME, i.ISIN, i.CSD, i.ASSET_CLASS,
       c.NAME AS counterparty, c.REGION, c.RISK_TIER AS cp_tier,
       c.HISTORICAL_FAIL_RATE AS cp_fail_rate, c.OPS_CONTACT_NAME, c.OPS_CONTACT_PHONE,
       t.DIRECTION, t.QUANTITY, t.NOTIONAL, t.CURRENCY,
       ROUND(t.NOTIONAL / t.QUANTITY, 2) AS implied_price,
       t.BROKER_CONFIRMATION_LAG_HRS AS lag_hrs, t.DESK,
       t.IS_MATCHED, t.MATCHED_AT, t.TRADE_DATE, t.EXPECTED_SETTLEMENT_DATE
  FROM TRADES t
  JOIN INSTRUMENTS i    ON i.INSTRUMENT_ID  = t.INSTRUMENT_ID
  JOIN COUNTERPARTIES c ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID
 WHERE t.TRADE_ID = $hero_id;

/* V2. The prediction.
   EXPECTED: TRD9NY101 | 0.83 | Critical | today 05:00:00 */
SELECT TRADE_ID, FAIL_PROBABILITY, RISK_TIER, SCORED_AT
  FROM TRADE_PREDICTIONS
 WHERE TRADE_ID = $hero_id;

/* V3. Reserved-range occupancy — what a reset would remove.
   EXPECTED: 1 trade, 1 prediction (this session only). */
SELECT (SELECT COUNT(*) FROM TRADES            WHERE TRADE_ID LIKE 'TRD9%') AS reserved_trades,
       (SELECT COUNT(*) FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9%') AS reserved_predictions;

/* V4. BASELINE UNDISTURBED — the counts that matter.
   EXPECTED: baseline_trades 50000 | baseline_predictions 50000
             | settlement_history 50000 | total_trades 50001
   The 50,001 vs 50,000 asymmetry is CORRECT: the hero is an open, unsettled
   trade and deliberately has no SETTLEMENT_HISTORY row. */
SELECT (SELECT COUNT(*) FROM TRADES            WHERE TRADE_ID NOT LIKE 'TRD9%') AS baseline_trades,
       (SELECT COUNT(*) FROM TRADE_PREDICTIONS WHERE TRADE_ID NOT LIKE 'TRD9%') AS baseline_predictions,
       (SELECT COUNT(*) FROM SETTLEMENT_HISTORY)                                AS settlement_history,
       (SELECT COUNT(*) FROM TRADES)                                            AS total_trades;

/* V5. Fail rate must not have moved — the hero adds no settlement outcome.
   EXPECTED: 50000 | 6416 | 12.83 */
SELECT COUNT(*) AS total_settlements,
       COUNT_IF(STATUS = 'FAILED') AS failed,
       ROUND(100.0 * COUNT_IF(STATUS = 'FAILED') / COUNT(*), 2) AS fail_rate_pct
  FROM SETTLEMENT_HISTORY;

/* ======================== end of script ================================== */
