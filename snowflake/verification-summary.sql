/* ============================================================================
   verification-summary.sql
   Settlement Operations demo - Phase 5 Part A evidence
   Written 2026-09-11.

   ONE STATEMENT, ONE GRID (CLAUDE.md, Snowsight deliverables).
   Returns one row per check: check_name | result | detail, result PASS/FAIL.

   HOW TO RUN
     Worksheet context (the picker at the top right): role FINSERVADMIN,
     warehouse COMPUTE_WH.  Every object below is fully qualified, so
     database and schema do not matter.  Run the statement; paste the grid.
     Snowsight colours the body between the dollar-quote delimiters like a
     string - that is normal; the block is compiled when it runs.

   WHAT IT DOES
     Uses the two procedures created by simulate-reset-procedures.sql.
     Pre-cleans its own test runs (SMOKE, VFY1, VFY12), then loads, checks,
     reloads, tries three bad run names, proves prefix safety, resets
     everything and checks the baseline.  It writes only the reserved TRD9
     test ids and one session-temporary results table, and it leaves no
     test rows behind.

   IF IT STOPS
     An error appends a row 99 STOPPED carrying the error text and returns
     the checks that ran.  The next run pre-cleans whatever was left.

   HOW INTERMEDIATE VALUES ARE HELD
     No SELECT ... INTO a variable anywhere (Snowflake rejected that
     construct in this block, 2026-09-11).  A value needed by a later check
     is written as a helper row with a NEGATIVE seq in the scratch table and
     read back with a subquery; the returned grid shows only seq >= 0.
     Semi-structured fields use bracket notation (x[1]['factor']) so no
     colon inside a SQL statement can be read as a bind variable.
   ============================================================================ */
EXECUTE IMMEDIATE $$
DECLARE
    err  VARCHAR;
    rs   RESULTSET;
BEGIN
    CREATE OR REPLACE TEMPORARY TABLE FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
        (seq NUMBER, chk_name VARCHAR, chk_result VARCHAR, chk_detail VARCHAR);

    -- 00 context -------------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 0, '00 context - role is FINSERVADMIN and both procedures exist',
           CASE WHEN CURRENT_ROLE() = 'FINSERVADMIN' AND n = 2 THEN 'PASS' ELSE 'FAIL' END,
           'role=' || CURRENT_ROLE() || ' | procedures found=' || n
      FROM (SELECT COUNT(*) AS n
              FROM FINSERV.INFORMATION_SCHEMA.PROCEDURES
             WHERE PROCEDURE_SCHEMA = 'TRADE_SETTLEMENT'
               AND PROCEDURE_NAME IN ('SIMULATE_FEED', 'RESET_SESSION'));

    -- 01 pre-clean -----------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -1, 'helper - test rows before pre-clean', NULL,
           TO_VARCHAR((SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                        WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                           OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11)))
                    + (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                        WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                           OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11))));
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('SMOKE');
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('VFY1');
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('VFY12');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 1, '01 pre-clean - no SMOKE, VFY1 or VFY12 rows left from an earlier run',
           CASE WHEN n = 0 THEN 'PASS' ELSE 'FAIL' END,
           'test rows before pre-clean='
             || COALESCE((SELECT MAX(chk_detail) FROM FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY WHERE seq = -1), 'null')
             || ' | after=' || n
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                        OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11)))
                 + (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                        OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11))) AS n);

    -- 02 baseline before load ------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 2, '02 baseline before load - trades, predictions and settlement history are 50000 each',
           CASE WHEN bt = 50000 AND bp = 50000 AND sh = 50000 THEN 'PASS' ELSE 'FAIL' END,
           'baseline trades=' || bt || ' | baseline predictions=' || bp || ' | settlement history=' || sh
             || ' | reserved rows from other runs=' || rr
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES            WHERE TRADE_ID NOT LIKE 'TRD9%') AS bt,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS WHERE TRADE_ID NOT LIKE 'TRD9%') AS bp,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.SETTLEMENT_HISTORY)                              AS sh,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES            WHERE TRADE_ID LIKE 'TRD9%')     AS rr);

    -- LOAD -------------------------------------------------------------------
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('SMOKE');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -101, 'helper - load message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 03 load landed ---------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 3, '03 SMOKE load - 15 trades and 15 predictions on exactly the fifteen reserved ids',
           CASE WHEN pt = 15 AND pp = 15 AND ids = 15 THEN 'PASS' ELSE 'FAIL' END,
           'trades=' || pt || ' | predictions=' || pp || ' | expected ids with trade and prediction=' || ids
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11) AS pt,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11) AS pp,
                   (SELECT COUNT(*)
                      FROM FINSERV.TRADE_SETTLEMENT.TRADES t
                      JOIN FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p ON p.TRADE_ID = t.TRADE_ID
                     WHERE t.TRADE_ID IN (SELECT 'TRD9SMOKE' || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                                            FROM TABLE(GENERATOR(ROWCOUNT => 15)))) AS ids);

    -- 04 isolation -----------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 4, '04 isolation - baseline counts unchanged with the packet loaded',
           CASE WHEN bt = 50000 AND bp = 50000 AND sh = 50000 THEN 'PASS' ELSE 'FAIL' END,
           'baseline trades=' || bt || ' | baseline predictions=' || bp || ' | settlement history=' || sh
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES            WHERE TRADE_ID NOT LIKE 'TRD9%') AS bt,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS WHERE TRADE_ID NOT LIKE 'TRD9%') AS bp,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.SETTLEMENT_HISTORY)                              AS sh);

    -- 05 story 01 ------------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 5, '05 story 01 hero - SAP GY, Diamond Trust, BUY 210000, 18700500 EUR, lag 1.15, 0.83 Critical, factors Large Notional x2',
           CASE WHEN i.TICKER = 'SAP GY' AND c.NAME = 'Diamond Trust' AND t.DESK = 'EQ_FLOW'
                 AND t.DIRECTION = 'BUY' AND t.QUANTITY = 210000 AND t.NOTIONAL = 18700500 AND t.CURRENCY = 'EUR'
                 AND t.BROKER_CONFIRMATION_LAG_HRS = 1.15 AND p.FAIL_PROBABILITY = 0.83 AND p.RISK_TIER = 'Critical'
                 AND p.TOP_RISK_FACTORS[1]['factor']::VARCHAR = 'Large Notional'
                 AND p.TOP_RISK_FACTORS[2]['factor']::VARCHAR = 'Large Notional'
                THEN 'PASS' ELSE 'FAIL' END,
           COALESCE(i.TICKER || ' | ' || c.NAME || ' | ' || t.DIRECTION || ' ' || TO_VARCHAR(t.QUANTITY)
             || ' | ' || TO_VARCHAR(t.NOTIONAL) || ' ' || t.CURRENCY
             || ' | lag ' || TO_VARCHAR(t.BROKER_CONFIRMATION_LAG_HRS)
             || ' | p ' || TO_VARCHAR(p.FAIL_PROBABILITY) || ' ' || p.RISK_TIER
             || ' | factors ' || TO_VARCHAR(p.TOP_RISK_FACTORS), 'row missing')
      FROM (SELECT 'TRD9SMOKE01' AS id) d
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADES t            ON t.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p ON p.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.INSTRUMENTS i       ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.COUNTERPARTIES c    ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID;

    -- 06 story 02 ------------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 6, '06 story 02 escalation - BATS LN, Horizon Securities, BUY 640000, 19584000 GBP, lag 26.07, 0.81 Critical, factors Slow Confirmation + Large Notional',
           CASE WHEN i.TICKER = 'BATS LN' AND c.NAME = 'Horizon Securities' AND t.DESK = 'EQ_FLOW'
                 AND t.DIRECTION = 'BUY' AND t.QUANTITY = 640000 AND t.NOTIONAL = 19584000 AND t.CURRENCY = 'GBP'
                 AND t.BROKER_CONFIRMATION_LAG_HRS = 26.07 AND p.FAIL_PROBABILITY = 0.81 AND p.RISK_TIER = 'Critical'
                 AND p.TOP_RISK_FACTORS[1]['factor']::VARCHAR = 'Slow Confirmation'
                 AND p.TOP_RISK_FACTORS[2]['factor']::VARCHAR = 'Large Notional'
                THEN 'PASS' ELSE 'FAIL' END,
           COALESCE(i.TICKER || ' | ' || c.NAME || ' | ' || t.DIRECTION || ' ' || TO_VARCHAR(t.QUANTITY)
             || ' | ' || TO_VARCHAR(t.NOTIONAL) || ' ' || t.CURRENCY
             || ' | lag ' || TO_VARCHAR(t.BROKER_CONFIRMATION_LAG_HRS)
             || ' | p ' || TO_VARCHAR(p.FAIL_PROBABILITY) || ' ' || p.RISK_TIER
             || ' | factors ' || TO_VARCHAR(p.TOP_RISK_FACTORS), 'row missing')
      FROM (SELECT 'TRD9SMOKE02' AS id) d
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADES t            ON t.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p ON p.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.INSTRUMENTS i       ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.COUNTERPARTIES c    ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID;

    -- 07 story 03 ------------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 7, '07 story 03 straight-through - IFX GY, Rosewood Trust, SELL 18400, 634800 EUR, lag 0.75, 0.72 High, factors Low Base Risk + Normal Operations',
           CASE WHEN i.TICKER = 'IFX GY' AND c.NAME = 'Rosewood Trust' AND t.DESK = 'EQ_FLOW'
                 AND t.DIRECTION = 'SELL' AND t.QUANTITY = 18400 AND t.NOTIONAL = 634800 AND t.CURRENCY = 'EUR'
                 AND t.BROKER_CONFIRMATION_LAG_HRS = 0.75 AND p.FAIL_PROBABILITY = 0.72 AND p.RISK_TIER = 'High'
                 AND p.TOP_RISK_FACTORS[1]['factor']::VARCHAR = 'Low Base Risk'
                 AND p.TOP_RISK_FACTORS[2]['factor']::VARCHAR = 'Normal Operations'
                THEN 'PASS' ELSE 'FAIL' END,
           COALESCE(i.TICKER || ' | ' || c.NAME || ' | ' || t.DIRECTION || ' ' || TO_VARCHAR(t.QUANTITY)
             || ' | ' || TO_VARCHAR(t.NOTIONAL) || ' ' || t.CURRENCY
             || ' | lag ' || TO_VARCHAR(t.BROKER_CONFIRMATION_LAG_HRS)
             || ' | p ' || TO_VARCHAR(p.FAIL_PROBABILITY) || ' ' || p.RISK_TIER
             || ' | factors ' || TO_VARCHAR(p.TOP_RISK_FACTORS), 'row missing')
      FROM (SELECT 'TRD9SMOKE03' AS id) d
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADES t            ON t.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p ON p.TRADE_ID = d.id
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.INSTRUMENTS i       ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
      LEFT JOIN FINSERV.TRADE_SETTLEMENT.COUNTERPARTIES c    ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID;

    -- 08 tier bands ----------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 8, '08 tier bands - every probability sits in its measured band (Low <0.25, Medium <0.50, High <0.75, Critical)',
           CASE WHEN n = 15 AND m = 15 THEN 'PASS' ELSE 'FAIL' END,
           'in band=' || m || ' of ' || n
      FROM (SELECT COUNT(*) AS n,
                   COUNT_IF(RISK_TIER = CASE WHEN FAIL_PROBABILITY >= 0.75 THEN 'Critical'
                                             WHEN FAIL_PROBABILITY >= 0.50 THEN 'High'
                                             WHEN FAIL_PROBABILITY >= 0.25 THEN 'Medium'
                                             ELSE 'Low' END) AS m
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- 09 case split ----------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 9, '09 case split - High or Critical is exactly stories 01-03; background max p below 0.5003',
           CASE WHEN hc = 3 AND hcs = 3 AND bg < 0.5003 THEN 'PASS' ELSE 'FAIL' END,
           'high or critical=' || hc || ' | of which stories=' || hcs || ' | background max p=' || TO_VARCHAR(bg)
      FROM (SELECT COUNT_IF(RISK_TIER IN ('High', 'Critical')) AS hc,
                   COUNT_IF(RISK_TIER IN ('High', 'Critical') AND RIGHT(TRADE_ID, 2) IN ('01', '02', '03')) AS hcs,
                   MAX(CASE WHEN RIGHT(TRADE_ID, 2) NOT IN ('01', '02', '03') THEN FAIL_PROBABILITY END) AS bg
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- 10 factor shape --------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 10, '10 factor shape - 3 elements; [0] Counterparty Risk = 2.5 x fail rate as DOUBLE; [1] and [2] observed DECIMAL pairs',
           CASE WHEN n = 15 AND arr = 15 AND cp = 15 AND ty = 15 AND p1 = 15 AND p2 = 15 THEN 'PASS' ELSE 'FAIL' END,
           'rows=' || n || ' | three elements=' || arr || ' | counterparty first and derived=' || cp
             || ' | contribution types as baseline=' || ty || ' | [1] pair observed=' || p1 || ' | [2] pair observed=' || p2
      FROM (SELECT COUNT(*) AS n,
                   COUNT_IF(TYPEOF(p.TOP_RISK_FACTORS) = 'ARRAY' AND ARRAY_SIZE(p.TOP_RISK_FACTORS) = 3) AS arr,
                   COUNT_IF(p.TOP_RISK_FACTORS[0]['factor']::VARCHAR = 'Counterparty Risk'
                            AND ABS(p.TOP_RISK_FACTORS[0]['contribution']::FLOAT - 2.5 * c.HISTORICAL_FAIL_RATE) < 1e-9) AS cp,
                   COUNT_IF(TYPEOF(p.TOP_RISK_FACTORS[0]['contribution']) = 'DOUBLE'
                            AND TYPEOF(p.TOP_RISK_FACTORS[1]['contribution']) = 'DECIMAL'
                            AND TYPEOF(p.TOP_RISK_FACTORS[2]['contribution']) = 'DECIMAL') AS ty,
                   COUNT_IF(p.TOP_RISK_FACTORS[1]['factor']::VARCHAR || '|' || TO_VARCHAR(p.TOP_RISK_FACTORS[1]['contribution']::NUMBER(3,2)) IN
                            ('Low Base Risk|0.02', 'Extended Settlement|0.02', 'High Volatility|0.06',
                             'Slow Confirmation|0.05', 'Month-End Pressure|0.07', 'Large Notional|0.02')) AS p1,
                   COUNT_IF(p.TOP_RISK_FACTORS[2]['factor']::VARCHAR || '|' || TO_VARCHAR(p.TOP_RISK_FACTORS[2]['contribution']::NUMBER(3,2)) IN
                            ('Normal Operations|0.01', 'Extended Settlement|0.01', 'Month-End Pressure|0.07',
                             'Large Notional|0.05')) AS p2
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p
              JOIN FINSERV.TRADE_SETTLEMENT.TRADES t         ON t.TRADE_ID = p.TRADE_ID
              JOIN FINSERV.TRADE_SETTLEMENT.COUNTERPARTIES c ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID
             WHERE p.TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(p.TRADE_ID) = 11);

    -- 11 factor coherence ----------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 11, '11 factor coherence - Slow Confirmation only on 02; no Extended Settlement, Month-End Pressure or High Volatility; story 03 low-risk only',
           CASE WHEN sc = 1 AND sc02 = 1 AND bad = 0 AND clean = 1 THEN 'PASS' ELSE 'FAIL' END,
           'slow confirmation rows=' || sc || ' | on story 02=' || sc02 || ' | excluded factors present=' || bad
             || ' | story 03 low-risk only=' || clean
      FROM (SELECT COUNT_IF(TO_VARCHAR(TOP_RISK_FACTORS) LIKE '%Slow Confirmation%') AS sc,
                   COUNT_IF(TO_VARCHAR(TOP_RISK_FACTORS) LIKE '%Slow Confirmation%' AND RIGHT(TRADE_ID, 2) = '02') AS sc02,
                   COUNT_IF(TO_VARCHAR(TOP_RISK_FACTORS) LIKE ANY ('%Extended Settlement%', '%Month-End Pressure%', '%High Volatility%')) AS bad,
                   COUNT_IF(RIGHT(TRADE_ID, 2) = '03'
                            AND TOP_RISK_FACTORS[1]['factor']::VARCHAR = 'Low Base Risk'
                            AND TOP_RISK_FACTORS[2]['factor']::VARCHAR = 'Normal Operations') AS clean
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- 12 factor pairs exist in the baseline ----------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 12, '12 factor pairs - every authored [1] + [2] pair occurs in the baseline (3 pairs)',
           CASE WHEN COUNT(*) = 3 AND COUNT_IF(COALESCE(b.row_cnt, 0) = 0) = 0 THEN 'PASS' ELSE 'FAIL' END,
           COALESCE(LISTAGG(a.f1 || ' ' || TO_VARCHAR(a.c1) || ' + ' || a.f2 || ' ' || TO_VARCHAR(a.c2)
                            || ' = ' || TO_VARCHAR(COALESCE(b.row_cnt, 0)) || ' baseline rows', ' ; ')
                      WITHIN GROUP (ORDER BY a.f1, a.f2), 'no packet factor pairs found')
      FROM (SELECT DISTINCT
                   TOP_RISK_FACTORS[1]['factor']::VARCHAR           AS f1,
                   TOP_RISK_FACTORS[1]['contribution']::NUMBER(3,2) AS c1,
                   TOP_RISK_FACTORS[2]['factor']::VARCHAR           AS f2,
                   TOP_RISK_FACTORS[2]['contribution']::NUMBER(3,2) AS c2
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11) a
      LEFT JOIN (SELECT TOP_RISK_FACTORS[1]['factor']::VARCHAR           AS f1,
                        TOP_RISK_FACTORS[1]['contribution']::NUMBER(3,2) AS c1,
                        TOP_RISK_FACTORS[2]['factor']::VARCHAR           AS f2,
                        TOP_RISK_FACTORS[2]['contribution']::NUMBER(3,2) AS c2,
                        COUNT(*)                                      AS row_cnt
                   FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                  WHERE TRADE_ID NOT LIKE 'TRD9%'
                    AND TOP_RISK_FACTORS[0]['factor']::VARCHAR = 'Counterparty Risk'
                  GROUP BY 1, 2, 3, 4) b
        ON b.f1 = a.f1 AND b.c1 = a.c1 AND b.f2 = a.f2 AND b.c2 = a.c2;

    -- 13 dates ---------------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 13, '13 dates - traded the day before the UTC run date, settling on it (T+1)',
           CASE WHEN n = 15 AND ty = 15 AND st = 15 THEN 'PASS' ELSE 'FAIL' END,
           'utc run date=' || TO_VARCHAR(SYSDATE()::DATE) || ' | session date=' || TO_VARCHAR(CURRENT_DATE)
             || ' | traded day before=' || ty || ' | settling on run date=' || st
      FROM (SELECT COUNT(*) AS n,
                   COUNT_IF(TRADE_DATE = DATEADD(day, -1, SYSDATE()::DATE)) AS ty,
                   COUNT_IF(EXPECTED_SETTLEMENT_DATE = SYSDATE()::DATE)     AS st
              FROM FINSERV.TRADE_SETTLEMENT.TRADES
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- 14 matched stamps ------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 14, '14 matched stamps - on the trade-date evening (18:mm), minutes varied across all 15',
           CASE WHEN n = 15 AND ev = 15 AND dm = 15 THEN 'PASS' ELSE 'FAIL' END,
           'evening of trade date=' || ev || ' | distinct minutes=' || dm || ' | hero matched at=' || COALESCE(TO_VARCHAR(hm), 'null')
      FROM (SELECT COUNT(*) AS n,
                   COUNT_IF(DATE(MATCHED_AT) = TRADE_DATE AND HOUR(MATCHED_AT) = 18) AS ev,
                   COUNT(DISTINCT MINUTE(MATCHED_AT)) AS dm,
                   MAX(CASE WHEN TRADE_ID = 'TRD9SMOKE01' THEN MATCHED_AT END) AS hm
              FROM FINSERV.TRADE_SETTLEMENT.TRADES
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- 15 scored stamps -------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 15, '15 scored stamps - SCORED_AT is call time on the UTC clock, not the Pacific session clock',
           CASE WHEN n = 15 AND fresh = 15 THEN 'PASS' ELSE 'FAIL' END,
           'within 15 min of SYSDATE=' || fresh || ' | scored at=' || COALESCE(TO_VARCHAR(s), 'null')
             || ' | SYSDATE utc=' || TO_VARCHAR(SYSDATE()) || ' | session clock=' || TO_VARCHAR(CURRENT_TIMESTAMP())
      FROM (SELECT COUNT(*) AS n,
                   COUNT_IF(DATEDIFF(second, SCORED_AT, SYSDATE()) BETWEEN 0 AND 900) AS fresh,
                   MAX(SCORED_AT) AS s
              FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
             WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11);

    -- RELOAD -----------------------------------------------------------------
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('SMOKE');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -102, 'helper - reload message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 16 idempotent reload ---------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 16, '16 idempotent reload - loading SMOKE again leaves exactly 15 trades and 15 predictions',
           CASE WHEN pt = 15 AND pp = 15 THEN 'PASS' ELSE 'FAIL' END,
           'trades=' || pt || ' | predictions=' || pp
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11) AS pt,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11) AS pp);

    -- GUARDS -----------------------------------------------------------------
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('THIS-IS-TOO-LONG');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -103, 'helper - too-long refusal message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('ACME_1012');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -104, 'helper - underscore refusal message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('---');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -105, 'helper - dashes-only refusal message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('ACME_1012');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -106, 'helper - reset refusal message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 17-19 guards wrote nothing ---------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 17, '17 guard - a 16-character run name (THIS-IS-TOO-LONG) writes nothing',
           CASE WHEN n = 0 THEN 'PASS' ELSE 'FAIL' END, 'rows written=' || n
      FROM (SELECT COUNT(*) AS n FROM FINSERV.TRADE_SETTLEMENT.TRADES
             WHERE LEFT(TRADE_ID, 17) = 'TRD9THISISTOOLONG');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 18, '18 guard - a run name with an underscore (ACME_1012) writes nothing',
           CASE WHEN n = 0 THEN 'PASS' ELSE 'FAIL' END, 'rows written=' || n
      FROM (SELECT COUNT(*) AS n FROM FINSERV.TRADE_SETTLEMENT.TRADES
             WHERE LEFT(TRADE_ID, 13) = 'TRD9ACME_1012');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 19, '19 guard - a run name with no letter or digit (---) writes nothing',
           CASE WHEN n = 0 THEN 'PASS' ELSE 'FAIL' END, 'rows written=' || n
      FROM (SELECT COUNT(*) AS n FROM FINSERV.TRADE_SETTLEMENT.TRADES
             WHERE TRADE_ID LIKE 'TRD9%' AND LENGTH(TRADE_ID) = 6);

    -- PREFIX SAFETY ----------------------------------------------------------
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('VFY1');
    CALL FINSERV.TRADE_SETTLEMENT.SIMULATE_FEED('VFY12');
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('VFY1');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -107, 'helper - reset VFY1 message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 20 prefix safety -------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 20, '20 prefix safety - resetting VFY1 removes all of VFY1 and none of VFY12',
           CASE WHEN v1t = 0 AND v1p = 0 AND v12t = 15 AND v12p = 15 THEN 'PASS' ELSE 'FAIL' END,
           'VFY1 trades=' || v1t || ' predictions=' || v1p || ' | VFY12 trades=' || v12t || ' predictions=' || v12p
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) = 10) AS v1t,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) = 10) AS v1p,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE TRADE_ID LIKE 'TRD9VFY12%' AND LENGTH(TRADE_ID) = 11) AS v12t,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE TRADE_ID LIKE 'TRD9VFY12%' AND LENGTH(TRADE_ID) = 11) AS v12p);

    -- FULL RESET -------------------------------------------------------------
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('VFY12');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -108, 'helper - reset VFY12 message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    CALL FINSERV.TRADE_SETTLEMENT.RESET_SESSION('SMOKE');
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT -109, 'helper - reset SMOKE message', NULL, TO_VARCHAR($1) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    -- 21 full reset ----------------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 21, '21 full reset - no SMOKE, VFY1 or VFY12 trade or prediction remains',
           CASE WHEN n = 0 THEN 'PASS' ELSE 'FAIL' END, 'test rows remaining=' || n
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES
                     WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                        OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11)))
                 + (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS
                     WHERE (TRADE_ID LIKE 'TRD9SMOKE%' AND LENGTH(TRADE_ID) = 11)
                        OR (TRADE_ID LIKE 'TRD9VFY1%'  AND LENGTH(TRADE_ID) IN (10, 11))) AS n);

    -- 22 baseline restored ---------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 22, '22 baseline after reset - trades, predictions and settlement history are 50000 each',
           CASE WHEN bt = 50000 AND bp = 50000 AND sh = 50000 THEN 'PASS' ELSE 'FAIL' END,
           'baseline trades=' || bt || ' | baseline predictions=' || bp || ' | settlement history=' || sh
      FROM (SELECT (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADES            WHERE TRADE_ID NOT LIKE 'TRD9%') AS bt,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS WHERE TRADE_ID NOT LIKE 'TRD9%') AS bp,
                   (SELECT COUNT(*) FROM FINSERV.TRADE_SETTLEMENT.SETTLEMENT_HISTORY)                              AS sh);

    -- 23 fail-rate invariant -------------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 23, '23 fail-rate invariant - 50000 settlements, 6416 failed, 12.83 percent',
           CASE WHEN total = 50000 AND failed = 6416 AND pct = 12.83 THEN 'PASS' ELSE 'FAIL' END,
           'settlements=' || total || ' | failed=' || failed || ' | fail rate pct=' || TO_VARCHAR(pct)
      FROM (SELECT COUNT(*) AS total,
                   COUNT_IF(STATUS = 'FAILED') AS failed,
                   ROUND(100.0 * COUNT_IF(STATUS = 'FAILED') / COUNT(*), 2) AS pct
              FROM FINSERV.TRADE_SETTLEMENT.SETTLEMENT_HISTORY);

    -- 24 procedure return strings -------------------------------------------
    INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
    SELECT 24, '24 procedure messages - load and reload summaries, four refusals, three reset summaries',
           CASE WHEN r_load   = 'OK run=SMOKE trades=15 predictions=15 high_or_critical=3'
                 AND r_reload = 'OK run=SMOKE trades=15 predictions=15 high_or_critical=3'
                 AND g_long  LIKE 'REFUSED%' AND g_chars LIKE 'REFUSED%'
                 AND g_empty LIKE 'REFUSED%' AND g_reset LIKE 'REFUSED%'
                 AND r_vfy1  = 'OK run=VFY1 trades_deleted=15 predictions_deleted=15'
                 AND r_vfy12 = 'OK run=VFY12 trades_deleted=15 predictions_deleted=15'
                 AND r_smoke = 'OK run=SMOKE trades_deleted=15 predictions_deleted=15'
                THEN 'PASS' ELSE 'FAIL' END,
           'load: '          || COALESCE(r_load, 'null')
             || ' || reload: '        || COALESCE(r_reload, 'null')
             || ' || too long: '      || COALESCE(g_long, 'null')
             || ' || underscore: '    || COALESCE(g_chars, 'null')
             || ' || dashes only: '   || COALESCE(g_empty, 'null')
             || ' || reset refusal: ' || COALESCE(g_reset, 'null')
             || ' || reset VFY1: '    || COALESCE(r_vfy1, 'null')
             || ' || reset VFY12: '   || COALESCE(r_vfy12, 'null')
             || ' || reset SMOKE: '   || COALESCE(r_smoke, 'null')
      FROM (SELECT MAX(CASE WHEN seq = -101 THEN chk_detail END) AS r_load,
                   MAX(CASE WHEN seq = -102 THEN chk_detail END) AS r_reload,
                   MAX(CASE WHEN seq = -103 THEN chk_detail END) AS g_long,
                   MAX(CASE WHEN seq = -104 THEN chk_detail END) AS g_chars,
                   MAX(CASE WHEN seq = -105 THEN chk_detail END) AS g_empty,
                   MAX(CASE WHEN seq = -106 THEN chk_detail END) AS g_reset,
                   MAX(CASE WHEN seq = -107 THEN chk_detail END) AS r_vfy1,
                   MAX(CASE WHEN seq = -108 THEN chk_detail END) AS r_vfy12,
                   MAX(CASE WHEN seq = -109 THEN chk_detail END) AS r_smoke
              FROM FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
             WHERE seq < 0);

    rs := (SELECT chk_name AS "check_name", chk_result AS "result", chk_detail AS "detail"
             FROM FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
            WHERE seq >= 0
            ORDER BY seq);
    RETURN TABLE(rs);

EXCEPTION
    WHEN OTHER THEN
        err := SQLERRM;
        INSERT INTO FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
        SELECT 99, '99 STOPPED - the block raised an error; the checks above ran, the rest did not',
               'FAIL', :err;
        rs := (SELECT chk_name AS "check_name", chk_result AS "result", chk_detail AS "detail"
                 FROM FINSERV.TRADE_SETTLEMENT.SO_VERIFY_SUMMARY
                WHERE seq >= 0
                ORDER BY seq);
        RETURN TABLE(rs);
END;
$$;
