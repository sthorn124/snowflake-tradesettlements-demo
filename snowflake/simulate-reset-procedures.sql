/* =====================================================================
   simulate-reset-procedures.sql
   Settlement Operations demo — SIMULATE_FEED / RESET_SESSION, Phase 5
   Run in Snowsight as FINSERVADMIN. Regenerated 2026-09-10.

   Contract: packet-spec.md.  Pattern: snowflake/hero-trade-insert.sql
   (the proven insert) — same TRADES column list, same date and NTZ forms.
   TRADE_PREDICTIONS adds TOP_RISK_FACTORS: packet predictions are
   baseline-shaped (ruled 2026-09-10; the hero's NULL precedent is retired).

   READY TO RUN — finalized 2026-09-10 from probe P9.
     SCORED_AT  TIMESTAMP_NTZ  -> written as SYSDATE()::TIMESTAMP_NTZ
     GRANTS     none required  -> see the GRANTS section for the P9 rows
     Run date   the UTC date   -> SYSDATE()::DATE (see SIMULATE_FEED)
   Run the whole file as FINSERVADMIN.  It creates the two procedures and
   nothing else.  Its evidence is snowflake/verification-summary.sql:
   one statement, one grid (CLAUDE.md, Snowsight deliverables).

   WHAT THESE PROCEDURES MAY TOUCH
     TRADES and TRADE_PREDICTIONS, and only the fifteen EXACT ids
     'TRD9' || <code> || '01'..'15' for the run name passed in.
     Never LIKE: a prefix predicate is unsafe once codes vary in length
     (resetting DEMO1 would take DEMO12).  The baseline is 50,000 rows on
     a shared partner account and is never read for update.

   IDEMPOTENT: SIMULATE_FEED deletes its own fifteen ids before inserting,
   so re-running a run name replaces that run.
   ===================================================================== */

USE ROLE FINSERVADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FINSERV;
USE SCHEMA TRADE_SETTLEMENT;


/* =====================================================================
   SIMULATE_FEED(RUN_NAME)
   ===================================================================== */
CREATE OR REPLACE PROCEDURE SIMULATE_FEED(RUN_NAME VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    code          VARCHAR;
    run_date      DATE;
    trades_in     NUMBER;
    preds_in      NUMBER;
    case_eligible NUMBER;
BEGIN
    /* ---- run name: 1-13 letters, digits or dashes (packet-spec §1) ---- */
    IF (RUN_NAME IS NULL OR NOT REGEXP_LIKE(RUN_NAME, '^[A-Za-z0-9-]{1,13}$')) THEN
        RETURN 'REFUSED: a run name is 1 to 13 letters, digits or dashes, e.g. 1012-ACME.';
    END IF;
    code := UPPER(REPLACE(RUN_NAME, '-', ''));
    IF (LENGTH(code) = 0) THEN
        RETURN 'REFUSED: a run name needs at least one letter or digit.';
    END IF;

    /* ---- run date = the UTC date --------------------------------------
       P9 measured the Snowsight session at America/Los_Angeles, so
       CURRENT_DATE is the PACIFIC date — a day behind an APAC business
       morning and London before 08:00.  The UTC date is right for New York
       until 20:00, London all day and Singapore from 08:00, is independent
       of whichever session calls the procedure (Snowsight or the REST API),
       and is the clock Appian reads NTZ stamps on.  (The hero insert used
       CURRENT_DATE; reverting is this one line.) */
    run_date := SYSDATE()::DATE;

    /* ---- idempotence: remove this run's fifteen exact ids (child first) ---- */
    DELETE FROM TRADE_PREDICTIONS
     WHERE TRADE_ID IN (SELECT 'TRD9' || :code || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                          FROM TABLE(GENERATOR(ROWCOUNT => 15)));
    DELETE FROM TRADES
     WHERE TRADE_ID IN (SELECT 'TRD9' || :code || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                          FROM TABLE(GENERATOR(ROWCOUNT => 15)));

    /* ---- TRADES — hero-insert forms ----------------------------------
       TRADE_DATE the day before run_date, settling on run_date (T+1).
       MATCHED_AT: trade-date evening, 18:mm with minutes varied per trade
       (ruled 2026-09-10).  The column is TIMESTAMP_NTZ per its creating
       DDL (snowflake-mockup-columns.sql), so the cast is explicit. */
    INSERT INTO TRADES
        (TRADE_ID, TRADE_DATE, EXPECTED_SETTLEMENT_DATE, INSTRUMENT_ID, COUNTERPARTY_ID,
         DIRECTION, NOTIONAL, CURRENCY, BROKER_CONFIRMATION_LAG_HRS, TRADER_ID, DESK,
         QUANTITY, IS_MATCHED, MATCHED_AT)
    SELECT
        'TRD9' || :code || seq,
        DATEADD(day, -1, :run_date),
        :run_date,
        instrument_id, counterparty_id, direction, notional, currency,
        lag_hrs, trader_id, desk, quantity,
        TRUE,
        DATEADD(minute, matched_min,
                DATEADD(hour, 18, TO_TIMESTAMP_NTZ(DATEADD(day, -1, :run_date))))
    FROM VALUES
        /* ---- the three seeded stories — High/Critical, open cases ---- */
        -- 01 HERO — held for review: timing fits; a 19.89% counterparty and a
        --    large notional compound into a human decision.
        ('01','INS0147','CP0023','BUY' , 18700500.00,'EUR', 1.15,'TR010','EQ_FLOW'   ,    210000.00,12),
        -- 02 ESCALATION — 26.07h of lag against a ~2.5h window.
        ('02','INS0153','CP0027','BUY' , 19584000.00,'GBP',26.07,'TR010','EQ_FLOW'   ,    640000.00,37),
        -- 03 STRAIGHT-THROUGH — clean across the board (0.72, High).
        ('03','INS0143','CP0037','SELL',   634800.00,'EUR', 0.75,'TR010','EQ_FLOW'   ,     18400.00, 5),
        /* ---- twelve background trades — all below the High floor ---- */
        ('04','INS0003','CP0012','SELL',   287700.00,'GBP', 1.40,'TR010','EQ_FLOW'   ,     42000.00,48),
        ('05','INS0158','CP0010','BUY' ,  5118000.00,'EUR', 0.50,'TR005','FI_TRADING',   5000000.00,21),
        ('06','INS0160','CP0002','SELL', 22400000.00,'AUD', 3.20,'TR003','FX_DESK'   ,  22400000.00,56),
        ('07','INS0004','CP0015','BUY' ,  6912500.00,'USD', 0.90,'TR002','ETF_MM'    ,     12500.00, 9),
        ('08','INS0150','CP0033','BUY' ,  1617000.00,'USD', 2.10,'TR010','EQ_FLOW'   ,     55000.00,33),
        ('09','INS0162','CP0016','SELL',  8264000.00,'EUR', 0.75,'TR019','FI_TRADING',   8000000.00,17),
        ('10','INS0164','CP0022','BUY' , 31900000.00,'GBP', 4.00,'TR015','FX_DESK'   ,  31900000.00,44),
        ('11','INS0167','CP0028','BUY' ,  4067000.00,'USD', 1.05,'TR010','EQ_FLOW'   ,      9800.00, 2),
        ('12','INS0170','CP0019','BUY' ,918000000.00,'JPY', 2.60,'TR012','CREDIT'    , 900000000.00,29),
        ('13','INS0155','CP0041','SELL',  2151300.00,'EUR', 1.90,'TR010','EQ_FLOW'   ,     21300.00,51),
        ('14','INS0152','CP0026','BUY' ,  4271400.00,'GBP', 0.60,'TR005','FI_TRADING',   4200000.00,14),
        ('15','INS0159','CP0046','BUY' ,434000000.00,'JPY', 1.30,'TR010','EQ_FLOW'   ,     31000.00,40)
    AS packet(seq, instrument_id, counterparty_id, direction, notional, currency,
              lag_hrs, trader_id, desk, quantity, matched_min);

    trades_in := SQLROWCOUNT;

    /* ---- TRADE_PREDICTIONS — baseline-shaped (ruled 2026-09-10) ------
       The hero insert's four scalar columns plus TOP_RISK_FACTORS.
       TOP_RISK_FACTORS shape, MEASURED (probes P4 and P5, 2026-09-10):
         an ARRAY of exactly three {contribution, factor} objects;
         [0]  Counterparty Risk, contribution = 2.5 x the counterparty's
              HISTORICAL_FAIL_RATE, stored as DOUBLE — exact on all five
              specimens.  Computed HERE from COUNTERPARTIES, so it cannot
              drift from the counterparty the trade row names.
         [1]  one of the fixed (factor, DECIMAL contribution) pairs observed
         [2]  at that position — authored per story (packet-spec §4).
       COHERENCE RULE (ruled): factors never contradict the story's fail
       reason or lane.  No Extended Settlement (every packet trade is T+1),
       no Month-End Pressure (the run date is arbitrary), Slow Confirmation
       only where confirmation IS the story (seq 02).
       RISK_TIER is capitalised; COUNTERPARTIES uses lower-case tiers.
       SCORED_AT is CALL TIME (ruled).  P9: the column is TIMESTAMP_NTZ with
       DEFAULT CURRENT_TIMESTAMP() — which would stamp the SESSION's wall
       clock (Pacific in Snowsight), and Appian reads NTZ as UTC (measured),
       so a defaulted stamp would look seven hours old.  It is therefore
       written explicitly as the UTC wall clock. */
    INSERT INTO TRADE_PREDICTIONS
        (TRADE_ID, FAIL_PROBABILITY, RISK_TIER, SCORED_AT, TOP_RISK_FACTORS)
    SELECT
        t.TRADE_ID,
        preds.fail_probability,
        preds.risk_tier,
        SYSDATE()::TIMESTAMP_NTZ,
        ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT('contribution', (2.5 * c.HISTORICAL_FAIL_RATE)::FLOAT, 'factor', 'Counterparty Risk'),
            OBJECT_CONSTRUCT('contribution', preds.f1_contribution, 'factor', preds.f1_factor),
            OBJECT_CONSTRUCT('contribution', preds.f2_contribution, 'factor', preds.f2_factor))
    FROM (VALUES
        /*  seq   p     tier        [1] factor           [1]    [2] factor           [2]  */
        -- 01 HERO — counterparty and size are what hold it.  NO confirmation
        --    factor: the 1.15h lag FITS the window, so Slow Confirmation
        --    would contradict the held-for-review lane.
        ('01', 0.83, 'Critical', 'Large Notional'   , 0.02, 'Large Notional'   , 0.05),
        -- 02 ESCALATION — the measured TRD044567 array: the lag is the story.
        ('02', 0.81, 'Critical', 'Slow Confirmation', 0.05, 'Large Notional'   , 0.05),
        -- 03 STRAIGHT-THROUGH — nothing concerning.
        ('03', 0.72, 'High'    , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        -- background — generic low weight.  10 and 12 (largest nominal notionals) carry
        -- Large Notional 0.02 + Large Notional 0.05: the pair measured on 1,402 baseline
        -- rows.  (Low Base Risk 0.02 + Large Notional 0.05 occurs on 0 baseline rows.)
        ('04', 0.18, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('05', 0.12, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('06', 0.24, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('07', 0.15, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('08', 0.31, 'Medium'  , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('09', 0.21, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('10', 0.28, 'Medium'  , 'Large Notional'   , 0.02, 'Large Notional'   , 0.05),
        ('11', 0.19, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('12', 0.33, 'Medium'  , 'Large Notional'   , 0.02, 'Large Notional'   , 0.05),
        ('13', 0.45, 'Medium'  , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('14', 0.10, 'Low'     , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01),
        ('15', 0.26, 'Medium'  , 'Low Base Risk'    , 0.02, 'Normal Operations', 0.01)
    ) AS preds(seq, fail_probability, risk_tier, f1_factor, f1_contribution, f2_factor, f2_contribution)
    JOIN TRADES t         ON t.TRADE_ID = 'TRD9' || :code || preds.seq
    JOIN COUNTERPARTIES c ON c.COUNTERPARTY_ID = t.COUNTERPARTY_ID;

    preds_in := SQLROWCOUNT;

    /* ---- how many will open a case: RISK_TIER in High/Critical (ruled) ---- */
    SELECT COUNT(*) INTO :case_eligible
      FROM TRADE_PREDICTIONS
     WHERE TRADE_ID IN (SELECT 'TRD9' || :code || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                          FROM TABLE(GENERATOR(ROWCOUNT => 15)))
       AND RISK_TIER IN ('High', 'Critical');

    RETURN 'OK run=' || code
        || ' trades=' || trades_in
        || ' predictions=' || preds_in
        || ' high_or_critical=' || case_eligible;
END;
$$;


/* =====================================================================
   RESET_SESSION(RUN_NAME)
   Deletes exactly that run's fifteen ids.  Predictions first.
   ===================================================================== */
CREATE OR REPLACE PROCEDURE RESET_SESSION(RUN_NAME VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    code       VARCHAR;
    preds_out  NUMBER;
    trades_out NUMBER;
BEGIN
    IF (RUN_NAME IS NULL OR NOT REGEXP_LIKE(RUN_NAME, '^[A-Za-z0-9-]{1,13}$')) THEN
        RETURN 'REFUSED: a run name is 1 to 13 letters, digits or dashes, e.g. 1012-ACME.';
    END IF;
    code := UPPER(REPLACE(RUN_NAME, '-', ''));
    IF (LENGTH(code) = 0) THEN
        RETURN 'REFUSED: a run name needs at least one letter or digit.';
    END IF;

    DELETE FROM TRADE_PREDICTIONS
     WHERE TRADE_ID IN (SELECT 'TRD9' || :code || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                          FROM TABLE(GENERATOR(ROWCOUNT => 15)));
    preds_out := SQLROWCOUNT;

    DELETE FROM TRADES
     WHERE TRADE_ID IN (SELECT 'TRD9' || :code || LPAD(TO_VARCHAR(ROW_NUMBER() OVER (ORDER BY SEQ4())), 2, '0')
                          FROM TABLE(GENERATOR(ROWCOUNT => 15)));
    trades_out := SQLROWCOUNT;

    RETURN 'OK run=' || code
        || ' trades_deleted=' || trades_out
        || ' predictions_deleted=' || preds_out;
END;
$$;


/* =====================================================================
   GRANTS — NONE REQUIRED.  Written from probe P9's privilege rows
   (2026-09-10), not from expectation:
     SCHEMA   TRADE_SETTLEMENT    OWNERSHIP         FINSERVADMIN
                                  CREATE PROCEDURE  FINSERVADMIN
     TABLE    TRADES              OWNERSHIP         FINSERVADMIN
     TABLE    TRADE_PREDICTIONS   OWNERSHIP         FINSERVADMIN
     DATABASE FINSERV             USAGE             FINSERVADMIN
                                  (the database itself is owned by ACCOUNTADMIN)
   FINSERVADMIN creates both procedures, so it owns them and may call
   them; EXECUTE AS OWNER runs their DML under its table ownership; the
   Appian PAT authenticates as FINSERVADMIN.  COUNTERPARTIES, which the
   factor join reads, is outside P9's scope — FINSERVADMIN's read of it is
   proven by hero-trade-insert.sql's V1 join, which ran clean.
   ===================================================================== */


/* =====================================================================
   VERIFICATION — NOT IN THIS FILE (ruled 2026-09-11).
   This is a setup script.  Its evidence is snowflake/verification-summary.sql:
   ONE statement that pre-cleans, loads, reloads, tries bad run names, proves
   prefix safety, resets, and returns ONE grid of check_name | result | detail
   rows.  The V0-V10 block that lived here produced eleven separate grids and
   could not be read as evidence in Snowsight, which shows one grid at a
   time, so it is retired.  Procedure definitions above are unchanged from
   the version run in Snowsight on 2026-09-11.
   ===================================================================== */
