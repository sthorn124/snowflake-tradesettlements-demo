/* ============================================================================
   trade-predictions-shape-probe.sql
   Settlement Operations demo — READ-ONLY schema probe, Phase 5 Part A
   Run in Snowsight as FINSERVADMIN. Written 2026-09-10.

   WRITES NOTHING. Every statement is DESC / SHOW / SELECT.

   WHY: the Part A packet and procedures must mirror the real TRADE_PREDICTIONS
   shape. The only shape a session can read is the Appian record type, and a
   record type shows MAPPED columns only — an unmapped Snowflake column is
   invisible to it (CLAUDE.md: mapping an existing external column is a Designer
   re-sync). So "the record type has four fields" cannot prove the table has
   four columns. This probe settles it, and shows what any extra column holds.

   Paste the output of every block back. P4 and P5 reference TOP_RISK_FACTORS
   and will ERROR if P1 shows no such column — that error is itself the answer;
   skip them in that case.
   ============================================================================ */

USE ROLE FINSERVADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FINSERV;
USE SCHEMA TRADE_SETTLEMENT;

/* P1. Authoritative column list, types, nullability, defaults. */
DESC TABLE TRADE_PREDICTIONS;

/* P2. TRADES shape — needed for the timestamp TYPES (NTZ vs LTZ) the packet
       writes into MATCHED_AT; the hero insert casts with TO_TIMESTAMP_NTZ. */
DESC TABLE TRADES;

/* P3. Every column of every reserved-range prediction currently loaded
       (the hero, if still present). Shows what the PROVEN insert left in any
       column it did not name. */
SELECT * FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9%' ORDER BY TRADE_ID;

/* P6. Tier cut-points the scoring heuristic actually produced on baseline.
       The packet's probability -> tier pairs must fall inside these bands, or a
       packet row is labelled differently from how the model labels the same
       probability. */
SELECT RISK_TIER,
       MIN(FAIL_PROBABILITY) AS min_p,
       MAX(FAIL_PROBABILITY) AS max_p,
       COUNT(*)              AS row_cnt
  FROM TRADE_PREDICTIONS
 WHERE TRADE_ID NOT LIKE 'TRD9%'
 GROUP BY RISK_TIER
 ORDER BY min_p DESC;

/* P7. Session timezone — decides what CURRENT_TIMESTAMP() becomes when it is
       written into a TIMESTAMP_NTZ column. */
SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;

/* P8. What FINSERVADMIN already holds — decides whether the procedure script
       needs any GRANT at all, or only CREATE PROCEDURE on the schema. */
SHOW GRANTS TO ROLE FINSERVADMIN;

/* ---- ONLY IF P1 LISTS TOP_RISK_FACTORS ------------------------------------ */

/* P4. Its shape on the specimens the build has already reasoned about:
       TRD000055 / TRD000095 (Critical), TRD000005 (Medium), TRD016924 (High),
       TRD044567 (Critical). Phase 3 assigned their case reasons BY HAND. */
SELECT TRADE_ID, FAIL_PROBABILITY, RISK_TIER,
       TYPEOF(TOP_RISK_FACTORS) AS variant_type,
       TOP_RISK_FACTORS
  FROM TRADE_PREDICTIONS
 WHERE TRADE_ID IN ('TRD000055','TRD000095','TRD000005','TRD016924','TRD044567')
 ORDER BY TRADE_ID;

/* P5. The vocabulary inside it across the baseline — whether it carries one of
       the four canon fail reasons, or risk-factor names of a different kind. */
SELECT f.path, f.key, TYPEOF(f.value) AS value_type, f.value::string AS value_text,
       COUNT(*) AS row_cnt
  FROM TRADE_PREDICTIONS p,
       LATERAL FLATTEN(input => p.TOP_RISK_FACTORS, recursive => TRUE) f
 WHERE p.TRADE_ID NOT LIKE 'TRD9%'
 GROUP BY 1, 2, 3, 4
 ORDER BY row_cnt DESC
 LIMIT 60;

/* ============================================================================
   P9. ONE GRID — RUN THIS STATEMENT ON ITS OWN AND DOWNLOAD ITS RESULT.
   Added 2026-09-10. Snowsight's CSV download exports only the LAST result grid,
   which is why the first paste carried P5 alone. This folds everything still
   needed into one grid:
     kind '1 column'    — every column of TRADES and TRADE_PREDICTIONS: type,
                          nullability, default (replaces P1/P2)
     kind '2 privilege' — every grant on FINSERV, TRADE_SETTLEMENT and the two
                          tables, to any grantee (replaces P8)
     kind '3 clock'     — role, session timestamp, UTC timestamp, session date
                          (replaces P7)
     kind '4 factor'    — the COMPLETE distinct TOP_RISK_FACTORS factor set with
                          counts (P5 was LIMIT 60)
     kind '5 shape'     — for each of the packet's 15 counterparties: baseline
                          rows, rows with Counterparty Risk FIRST, and the range
                          of that first contribution (added 2026-09-10)
     kind '6 pair'      — which [1] + [2] (factor, contribution) pairs actually
                          co-occur on baseline rows led by Counterparty Risk
                          (added 2026-09-10)
   Read-only. If the privilege branch errors, delete it, run the rest, and export
   SHOW GRANTS TO ROLE FINSERVADMIN as a second grid.
   ============================================================================ */
SELECT kind, obj, name, detail1, detail2, detail3
FROM (
  SELECT '1 column' AS kind, TABLE_NAME AS obj, COLUMN_NAME AS name,
         DATA_TYPE AS detail1, IS_NULLABLE AS detail2,
         COALESCE(COLUMN_DEFAULT, '') AS detail3,
         LPAD(TO_VARCHAR(ORDINAL_POSITION), 3, '0') AS sort_key
    FROM FINSERV.INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = 'TRADE_SETTLEMENT'
     AND TABLE_NAME IN ('TRADE_PREDICTIONS', 'TRADES')
  UNION ALL
  SELECT '2 privilege',
         OBJECT_TYPE || ' ' || COALESCE(OBJECT_SCHEMA || '.', '') || OBJECT_NAME,
         PRIVILEGE_TYPE, GRANTEE, GRANTOR, IS_GRANTABLE, ''
    FROM FINSERV.INFORMATION_SCHEMA.OBJECT_PRIVILEGES
   WHERE (OBJECT_TYPE = 'DATABASE' AND OBJECT_NAME = 'FINSERV')
      OR (OBJECT_TYPE = 'SCHEMA'   AND OBJECT_NAME = 'TRADE_SETTLEMENT')
      OR (OBJECT_SCHEMA = 'TRADE_SETTLEMENT' AND OBJECT_NAME IN ('TRADES', 'TRADE_PREDICTIONS'))
  UNION ALL
  SELECT '3 clock', CURRENT_ROLE(), 'CURRENT_TIMESTAMP | SYSDATE (UTC) | CURRENT_DATE',
         TO_VARCHAR(CURRENT_TIMESTAMP()), TO_VARCHAR(SYSDATE()), TO_VARCHAR(CURRENT_DATE), ''
  UNION ALL
  SELECT '4 factor', 'TOP_RISK_FACTORS', f.value:factor::VARCHAR,
         TO_VARCHAR(COUNT(*)), '', '', ''
    FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p,
         LATERAL FLATTEN(input => p.TOP_RISK_FACTORS) f
   WHERE p.TRADE_ID NOT LIKE 'TRD9%'
   GROUP BY f.value:factor::VARCHAR
  UNION ALL
  SELECT '5 shape', t.COUNTERPARTY_ID, 'rows | counterparty-first rows | first contribution min-max',
         TO_VARCHAR(COUNT(*)),
         TO_VARCHAR(COUNT_IF(p.TOP_RISK_FACTORS[0]:factor::VARCHAR = 'Counterparty Risk')),
         TO_VARCHAR(MIN(p.TOP_RISK_FACTORS[0]:contribution::FLOAT)) || ' - ' || TO_VARCHAR(MAX(p.TOP_RISK_FACTORS[0]:contribution::FLOAT)),
         ''
    FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p
    JOIN FINSERV.TRADE_SETTLEMENT.TRADES t ON t.TRADE_ID = p.TRADE_ID
   WHERE p.TRADE_ID NOT LIKE 'TRD9%'
     AND t.COUNTERPARTY_ID IN ('CP0023','CP0027','CP0037','CP0012','CP0010','CP0002','CP0015',
                               'CP0033','CP0016','CP0022','CP0028','CP0019','CP0041','CP0026','CP0046')
   GROUP BY t.COUNTERPARTY_ID
  UNION ALL
  SELECT '6 pair', '[1] + [2]',
         p.TOP_RISK_FACTORS[1]:factor::VARCHAR || ' ' || TO_VARCHAR(p.TOP_RISK_FACTORS[1]:contribution)
           || '  +  ' || p.TOP_RISK_FACTORS[2]:factor::VARCHAR || ' ' || TO_VARCHAR(p.TOP_RISK_FACTORS[2]:contribution),
         TO_VARCHAR(COUNT(*)), '', '', ''
    FROM FINSERV.TRADE_SETTLEMENT.TRADE_PREDICTIONS p
   WHERE p.TRADE_ID NOT LIKE 'TRD9%'
     AND p.TOP_RISK_FACTORS[0]:factor::VARCHAR = 'Counterparty Risk'
   GROUP BY 3
)
ORDER BY kind, obj, sort_key, name;

/* ======================== end of probe =================================== */
