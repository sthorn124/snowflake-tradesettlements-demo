/* ⛔ SUPERSEDED 2026-09-10 — use CALL RESET_SESSION('<run name>') instead.
   The LIKE 'TRD9' || $session_code || '%' predicate below is PREFIX-UNSAFE
   under the ruled run-name scheme (codes of 1-13 characters): code NY1 also
   matches a run named NY1ACME. Safe only while NY1 is the only reserved code
   loaded anywhere on the account. Kept for history; do not hand to an SC. */

/* ============================================================================
   hero-trade-delete.sql
   Settlement Operations demo — remove the authored hero trade
   Run in Snowsight as FINSERVADMIN. Paired with hero-trade-insert.sql.
   Written 2026-09-02.

   Deletes ONLY rows in the reserved id range TRD9<session>%. No baseline row is
   touched. Safe to run when nothing is loaded (deletes 0 rows).

   This is the manual equivalent of RESET_SESSION(session_id); see
   hero-trade-spec.md §2 and §5.
   ============================================================================ */

USE ROLE FINSERVADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FINSERV;
USE SCHEMA TRADE_SETTLEMENT;

SET session_code = 'NY1';           /* must match the insert script */

/* Show what is about to be deleted. EXPECTED: 1 trade, 1 prediction. */
SELECT TRADE_ID, DESK, NOTIONAL, CURRENCY
  FROM TRADES
 WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%';

/* Child first — TRADE_PREDICTIONS is 1:1 on TRADE_ID. */
DELETE FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%';
DELETE FROM TRADES            WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%';

/* ============================================================================
   VERIFICATION — baseline restored
   ============================================================================ */

/* EXPECTED: session_trades 0 | session_predictions 0 */
SELECT (SELECT COUNT(*) FROM TRADES            WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%') AS session_trades,
       (SELECT COUNT(*) FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%') AS session_predictions;

/* EXPECTED: trades 50000 | predictions 50000 | settlement_history 50000
             | reserved_remaining 0  (0 only if no OTHER session has a packet
             loaded — a non-zero value here is another SC's data, not an error) */
SELECT (SELECT COUNT(*) FROM TRADES)                                         AS trades,
       (SELECT COUNT(*) FROM TRADE_PREDICTIONS)                              AS predictions,
       (SELECT COUNT(*) FROM SETTLEMENT_HISTORY)                             AS settlement_history,
       (SELECT COUNT(*) FROM TRADES WHERE TRADE_ID LIKE 'TRD9%')             AS reserved_remaining;

/* EXPECTED: 50000 | 6416 | 12.83 */
SELECT COUNT(*) AS total_settlements,
       COUNT_IF(STATUS = 'FAILED') AS failed,
       ROUND(100.0 * COUNT_IF(STATUS = 'FAILED') / COUNT(*), 2) AS fail_rate_pct
  FROM SETTLEMENT_HISTORY;

/* ======================== end of script ================================== */
