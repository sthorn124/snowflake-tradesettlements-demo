/* ============================================================================
   snowflake-mockup-columns.sql
   Settlement Operations demo — mockup-driven column widening
   Run in Snowsight as FINSERVADMIN, warehouse COMPUTE_WH. Idempotent: safe to
   re-run in full. Written 2026-09-02.

   WHY: the analyst-watchlist and case-detail mockups display instrument
   identity, settlement venue, matched status, ops contacts and quantity. None
   of those existed in the schema. This script adds them and backfills.

   ---------------------------------------------------------------------------
   CHANGE INVENTORY  (per the 2026-09-02 data-safety policy)
   ---------------------------------------------------------------------------
   INSTRUMENTS (200 rows)
     COLUMNS ADDED     : ISIN, CSD, TICKER_ORIG, NAME_ORIG
     COLUMNS MODIFIED  : TICKER, NAME  <-- the ONLY pre-existing values rewritten
                         anywhere in this script. Sanctioned exception: current
                         values are synthetic placeholders ('MUN000','MUN000
                         Bond 0'). Snapshotted to TICKER_ORIG / NAME_ORIG BEFORE
                         the rewrite; see RESTORE below.
     UNTOUCHED         : INSTRUMENT_ID, ASSET_CLASS, CURRENCY, AVG_VOLATILITY,
                         MARKET_CAP_TIER

   TRADES (50,000 rows)
     COLUMNS ADDED     : QUANTITY, IS_MATCHED, MATCHED_AT
     COLUMNS MODIFIED  : none
     UNTOUCHED         : every pre-existing column, incl. NOTIONAL, CURRENCY,
                         DIRECTION, all dates, INSTRUMENT_ID, COUNTERPARTY_ID

   COUNTERPARTIES (50 rows)
     COLUMNS ADDED     : OPS_CONTACT_NAME, OPS_CONTACT_PHONE
     COLUMNS MODIFIED  : none

   SETTLEMENT_HISTORY (50,000 rows)
     COLUMNS ADDED     : COUNTERPARTY_ID  (derived: joined from TRADES)
     COLUMNS MODIFIED  : none
     NOT ADDED         : instrument / value / date columns. The recent-fails view
                         reaches those by relationship traversal to SO Trade in
                         Appian, per the data-safety policy.

   NO OTHER VALUES CHANGE. No fail reason, probability, risk tier, notional,
   asset class, currency, date or relationship value is written by this script.
   No rows are inserted or deleted. TRADE_PREDICTIONS is not touched at all.

   RESTORE (undo the only value rewrite):
     UPDATE FINSERV.TRADE_SETTLEMENT.INSTRUMENTS
        SET TICKER = TICKER_ORIG, NAME = NAME_ORIG
      WHERE TICKER_ORIG IS NOT NULL;
   ============================================================================ */

USE ROLE FINSERVADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE FINSERV;
USE SCHEMA TRADE_SETTLEMENT;


/* ============================================================================
   1. INSTRUMENTS — identity and settlement venue
   ============================================================================
   TICKER/NAME are rewritten to real-style identities; ISIN and CSD are new.
   Every identity is consistent with the row's OWN pre-existing ASSET_CLASS and
   CURRENCY, which are NOT modified:
     - equities  -> real listed identity, market suffix matching the currency
     - ETFs      -> real fund identity on the matching listing venue
     - bonds     -> issuer + coupon + maturity; govt/muni settle domestically,
                    corporate/IG/HY/EM settle at Euroclear Bank (international)
     - FX fwds   -> currency pair + tenor. ISIN is NULL by design: an FX forward
                    is not a securities issue and carries no ISIN. CSD is CLS.
   ISINs are valid-format: correct country prefix for the listing market and a
   correct ISO 6166 check digit (verified at generation time).

   Demo pins:
     INS0147 -> SAP GY / SAP SE / DE0007164600 / Clearstream (CBF)
                (equity, EUR, mid — the hero instrument; see hero-trade-spec.md)
     INS0078 -> BAS GY / BASF SE / DE000BASF111 / Clearstream (CBF)
                (equity, EUR — instrument on specimen trade TRD016924)
     INS0142 -> EURUSD 3M FWD (fx_forward, EUR — instrument on specimen trade
                TRD044567, whose fail reason is funding_gap; a currency-forward
                identity is what makes that story cohere)
   ------------------------------------------------------------------------- */

ALTER TABLE INSTRUMENTS ADD COLUMN IF NOT EXISTS ISIN        VARCHAR(12);
ALTER TABLE INSTRUMENTS ADD COLUMN IF NOT EXISTS CSD         VARCHAR(40);
ALTER TABLE INSTRUMENTS ADD COLUMN IF NOT EXISTS TICKER_ORIG VARCHAR(20);
ALTER TABLE INSTRUMENTS ADD COLUMN IF NOT EXISTS NAME_ORIG   VARCHAR(100);

/* Snapshot BEFORE any rewrite. Guarded two ways so a re-run cannot clobber the
   snapshot with already-rewritten values: TICKER_ORIG must still be empty AND
   TICKER must still look synthetic. Every original ticker is of the form
   ABC123 (no space); every replacement contains a space. */
UPDATE INSTRUMENTS
   SET TICKER_ORIG = TICKER,
       NAME_ORIG   = NAME
 WHERE TICKER_ORIG IS NULL
   AND TICKER NOT LIKE '% %';

UPDATE INSTRUMENTS t
   SET TICKER = m.ticker,
       NAME   = m.name,
       ISIN   = m.isin,
       CSD    = m.csd
  FROM (VALUES
    ('INS0001', 'TOKYO 4.32 11/31', 'Tokyo Metropolitan Government 4.32% 2031', 'JP00026784E7', 'JASDEC'),
    ('INS0002', 'INDOAU 1.567 09/37', 'Republic of Indonesia 1.567% 2037', 'AU000E053AF6', 'Euroclear Bank'),
    ('INS0003', 'HSBA LN', 'HSBC Holdings PLC', 'GB0002E840A9', 'CREST'),
    ('INS0004', 'SPY US', 'SPDR S&P 500 ETF Trust', 'US00030B1957', 'DTC'),
    ('INS0005', 'NRW 3.272 12/35', 'Land Nordrhein-Westfalen 3.272% 2035', 'DE0009CDFAA9', 'Clearstream (CBF)'),
    ('INS0006', 'HEI GY', 'Heidelberg Materials AG', 'DE0004052AC0', 'Clearstream (CBF)'),
    ('INS0007', 'BAYERN 1.768 09/29', 'Freistaat Bayern 1.768% 2029', 'DE00074A6B20', 'Clearstream (CBF)'),
    ('INS0008', 'UKT 3.905 12/30', 'United Kingdom Gilt 3.905% 2030', 'GB0003A6EA36', 'CREST'),
    ('INS0009', 'XRO AU', 'Xero Ltd', 'AU000B0108B7', 'CHESS'),
    ('INS0010', 'CAT US', 'Caterpillar Inc', 'US000BEE87E9', 'DTC'),
    ('INS0011', 'CBAAU 0.76 05/32', 'Commonwealth Bank of Australia 0.76% 2032', 'AU0007ADAF25', 'Euroclear Bank'),
    ('INS0012', 'AI FP', 'Air Liquide SA', 'FR000DFC9C62', 'Euroclear France'),
    ('INS0013', 'SIE GY', 'Siemens AG', 'DE000D9FAA10', 'Clearstream (CBF)'),
    ('INS0014', 'BRAZIL 1.542 07/36', 'Federative Republic of Brazil 1.542% 2036', 'US00019D2834', 'Euroclear Bank'),
    ('INS0015', 'NG LN', 'National Grid PLC', 'GB00059AC4A8', 'CREST'),
    ('INS0016', 'DOW US', 'Dow Inc', 'US0000658858', 'DTC'),
    ('INS0017', '5401 JT', 'Nippon Steel Corp', 'JP000EBE4E66', 'JASDEC'),
    ('INS0018', 'CHSPI SW', 'iShares Core SPI ETF', 'CH000FBD16C6', 'SIX SIS'),
    ('INS0019', 'BARC LN', 'Barclays PLC', 'GB0005164347', 'CREST'),
    ('INS0020', 'HON US', 'Honeywell International Inc', 'US0004B36894', 'DTC'),
    ('INS0021', 'IVV US', 'iShares Core S&P 500 ETF', 'US0009CE5564', 'DTC'),
    ('INS0022', 'VUSA LN', 'Vanguard S&P 500 UCITS ETF', 'GB00067C90D7', 'CREST'),
    ('INS0023', 'SHEL LN', 'Shell PLC', 'GB000FD65516', 'CREST'),
    ('INS0024', 'JPM US', 'JPMorgan Chase & Co', 'US000C481170', 'DTC'),
    ('INS0025', 'SPG US', 'Simon Property Group Inc', 'US000474D495', 'DTC'),
    ('INS0026', 'EXS1 GY', 'iShares Core DAX UCITS ETF', 'DE00081863D0', 'Clearstream (CBF)'),
    ('INS0027', 'BAC US', 'Bank of America Corp', 'US000FC94E16', 'DTC'),
    ('INS0028', 'EURUSD 1M FWD', 'EUR/USD 1-Month Forward', NULL, 'CLS'),
    ('INS0029', 'JPM 2.107 01/39', 'JPMorgan Chase & Co 2.107% 2039', 'US000D2EEF04', 'Euroclear Bank'),
    ('INS0030', 'QQQ US', 'Invesco QQQ Trust Series 1', 'US0009C35745', 'DTC'),
    ('INS0031', 'XOM US', 'Exxon Mobil Corp', 'US00022B8861', 'DTC'),
    ('INS0032', 'EUNL GY', 'iShares Core MSCI World UCITS ETF', 'DE000C9BF5E5', 'Clearstream (CBF)'),
    ('INS0033', 'GE US', 'GE Aerospace', 'US0005257F42', 'DTC'),
    ('INS0034', 'SIEGR 4.982 12/35', 'Siemens AG 4.982% 2035', 'DE0000616E95', 'Euroclear Bank'),
    ('INS0035', 'VW 2.468 05/36', 'Volkswagen International Finance NV 2.468% 2036', 'DE0008FA4D39', 'Euroclear Bank'),
    ('INS0036', 'AAPL 1.538 01/32', 'Apple Inc 1.538% 2032', 'US0003BB3C74', 'Euroclear Bank'),
    ('INS0037', '1306 JT', 'NEXT FUNDS TOPIX Exchange Traded Fund', 'JP000A2B0251', 'JASDEC'),
    ('INS0038', 'LSEG LN', 'London Stock Exchange Group PLC', 'GB0007512C05', 'CREST'),
    ('INS0039', 'BAC 4.53 03/34', 'Bank of America Corp 4.53% 2034', 'US000592E021', 'Euroclear Bank'),
    ('INS0040', 'CVX US', 'Chevron Corp', 'US000AFE2082', 'DTC'),
    ('INS0041', 'VZ US', 'Verizon Communications Inc', 'US000ACC8BA7', 'DTC'),
    ('INS0042', 'VAS AU', 'Vanguard Australian Shares Index ETF', 'AU000E538D41', 'CHESS'),
    ('INS0043', 'HOLN SW', 'Holcim AG', 'CH0008829F20', 'SIX SIS'),
    ('INS0044', '7203 JT', 'Toyota Motor Corp', 'JP000C52BFB8', 'JASDEC'),
    ('INS0045', 'JPYKRW 1M FWD', 'JPY/KRW 1-Month Forward', NULL, 'CLS'),
    ('INS0046', 'USDJPY 1M FWD', 'USD/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0047', 'RIO LN', 'Rio Tinto PLC', 'GB000A5E50A5', 'CREST'),
    ('INS0048', 'HSBC 2.962 01/29', 'HSBC Holdings PLC 2.962% 2029', 'GB000603ADB3', 'Euroclear Bank'),
    ('INS0049', '9983 JT', 'Fast Retailing Co Ltd', 'JP000FCDB029', 'JASDEC'),
    ('INS0050', 'PEMEX 1.657 04/35', 'Petroleos Mexicanos 1.657% 2035', 'ES0004AA3EA8', 'Euroclear Bank'),
    ('INS0051', 'LGEN LN', 'Legal & General Group PLC', 'GB000D4B7158', 'CREST'),
    ('INS0052', 'EURGBP 1M FWD', 'EUR/GBP 1-Month Forward', NULL, 'CLS'),
    ('INS0053', 'VNA GY', 'Vonovia SE', 'DE000C49D574', 'Clearstream (CBF)'),
    ('INS0054', 'MUFG 3.335 01/30', 'Mitsubishi UFJ Financial Group Inc 3.335% 2030', 'JP00079E8C29', 'Euroclear Bank'),
    ('INS0055', 'EURJPY 1M FWD', 'EUR/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0056', 'SXRV GY', 'iShares Nasdaq 100 UCITS ETF', 'DE0006BA6351', 'Clearstream (CBF)'),
    ('INS0057', 'BAYN GY', 'Bayer AG', 'DE00072A85E9', 'Clearstream (CBF)'),
    ('INS0058', '1321 JT', 'NEXT FUNDS Nikkei 225 Exchange Traded Fund', 'JP0001951037', 'JASDEC'),
    ('INS0059', 'TKAGR 4.365 08/36', 'ThyssenKrupp AG 4.365% 2036', 'DE000199FAB8', 'Euroclear Bank'),
    ('INS0060', 'AUDUSD 1M FWD', 'AUD/USD 1-Month Forward', NULL, 'CLS'),
    ('INS0061', 'CHFJPY 1M FWD', 'CHF/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0062', 'EURCHF 1M FWD', 'EUR/CHF 1-Month Forward', NULL, 'CLS'),
    ('INS0063', 'T 2.435 12/28', 'United States Treasury 2.435% 2028', 'US00024D2AD3', 'DTC'),
    ('INS0064', 'NYSDA 4.248 04/34', 'New York State Dormitory Authority 4.248% 2034', 'US000243CFE8', 'DTC'),
    ('INS0065', 'EURSEK 1M FWD', 'EUR/SEK 1-Month Forward', NULL, 'CLS'),
    ('INS0066', 'TTE FP', 'TotalEnergies SE', 'FR0004882A95', 'Euroclear France'),
    ('INS0067', 'DTE GY', 'Deutsche Telekom AG', 'DE000D0C45A8', 'Clearstream (CBF)'),
    ('INS0068', 'ULVR LN', 'Unilever PLC', 'GB000218E3C0', 'CREST'),
    ('INS0069', 'CADJPY 1M FWD', 'CAD/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0070', 'NESNCH 4.5 06/30', 'Nestle Holdings Inc 4.5% 2030', 'CH00012E8143', 'Euroclear Bank'),
    ('INS0071', '9501 JT', 'Tokyo Electric Power Co Holdings Inc', 'JP000004ED70', 'JASDEC'),
    ('INS0072', 'MBG GY', 'Mercedes-Benz Group AG', 'DE000F610466', 'Clearstream (CBF)'),
    ('INS0073', 'DBR 1.94 07/40', 'Bundesrepublik Deutschland 1.94% 2040', 'DE000399E2D1', 'Clearstream (CBF)'),
    ('INS0074', 'SU FP', 'Schneider Electric SE', 'FR0009AACF57', 'Euroclear France'),
    ('INS0075', 'GBPUSD 1M FWD', 'GBP/USD 1-Month Forward', NULL, 'CLS'),
    ('INS0076', 'PG US', 'Procter & Gamble Co', 'US0008AF2C69', 'DTC'),
    ('INS0077', 'PHILIP 4.412 06/29', 'Republic of the Philippines 4.412% 2029', 'JP0006682678', 'Euroclear Bank'),
    ('INS0078', 'BAS GY', 'BASF SE', 'DE000BASF111', 'Clearstream (CBF)'),
    ('INS0079', 'QANAU 4.955 03/30', 'Qantas Airways Ltd 4.955% 2030', 'AU000EC44A10', 'Euroclear Bank'),
    ('INS0080', 'XDWD GY', 'Xtrackers MSCI World UCITS ETF', 'DE0001904605', 'Clearstream (CBF)'),
    ('INS0081', '1330 JT', 'Listed Index Fund 225', 'JP0002457935', 'JASDEC'),
    ('INS0082', 'ORAFP 4.475 02/30', 'Orange SA 4.475% 2030', 'FR00029F1DE3', 'Euroclear Bank'),
    ('INS0083', 'ENELIM 4.467 06/28', 'Enel SpA 4.467% 2028', 'IT00039E96A3', 'Euroclear Bank'),
    ('INS0084', 'AAL LN', 'Anglo American PLC', 'GB000BCC2677', 'CREST'),
    ('INS0085', 'T 1.345 04/36', 'United States Treasury 1.345% 2036', 'US000CAEF5F6', 'DTC'),
    ('INS0086', 'USDCHF 1M FWD', 'USD/CHF 1-Month Forward', NULL, 'CLS'),
    ('INS0087', 'SAN FP', 'Sanofi SA', 'FR000E7F5040', 'Euroclear France'),
    ('INS0088', 'F 2.428 09/35', 'Ford Motor Co 2.428% 2035', 'US000FA88699', 'Euroclear Bank'),
    ('INS0089', 'BARCLN 3.547 11/31', 'Barclays PLC 3.547% 2031', 'GB0001AA7348', 'Euroclear Bank'),
    ('INS0090', 'VTI US', 'Vanguard Total Stock Market ETF', 'US00060701D1', 'DTC'),
    ('INS0091', 'PFE 2.188 08/30', 'Pfizer Inc 2.188% 2030', 'US0006E65280', 'Euroclear Bank'),
    ('INS0092', 'DUK 3.982 04/27', 'Duke Energy Corp 3.982% 2027', 'US000C18DDC0', 'Euroclear Bank'),
    ('INS0093', 'TURKEY 4.965 10/39', 'Republic of Turkiye 4.965% 2039', 'IT0002EFB656', 'Euroclear Bank'),
    ('INS0094', 'EURNOK 1M FWD', 'EUR/NOK 1-Month Forward', NULL, 'CLS'),
    ('INS0095', 'PHILIP 4.248 02/31', 'Republic of the Philippines 4.248% 2031', 'JP000BFDBBD5', 'Euroclear Bank'),
    ('INS0096', 'AGG US', 'iShares Core US Aggregate Bond ETF', 'US000134A152', 'DTC'),
    ('INS0097', 'MEX 2.6 06/39', 'United Mexican States 2.6% 2039', 'US000E7C4780', 'Euroclear Bank'),
    ('INS0098', 'JNJ US', 'Johnson & Johnson', 'US000CD6E692', 'DTC'),
    ('INS0099', 'T US', 'AT&T Inc', 'US000F074A90', 'DTC'),
    ('INS0100', 'ALV GY', 'Allianz SE', 'DE000331FEB9', 'Clearstream (CBF)'),
    ('INS0101', 'ACFP 2.22 04/30', 'Accor SA 2.22% 2030', 'FR000D8A8EE0', 'Euroclear Bank'),
    ('INS0102', 'CALST 1.232 10/30', 'State of California 1.232% 2030', 'US0005F8EC49', 'DTC'),
    ('INS0103', 'NSWTC 3.225 05/35', 'New South Wales Treasury Corp 3.225% 2035', 'AU0002FFEB56', 'CHESS'),
    ('INS0104', 'DG FP', 'Vinci SA', 'FR000C0AE759', 'Euroclear France'),
    ('INS0105', 'JPYTHB 1M FWD', 'JPY/THB 1-Month Forward', NULL, 'CLS'),
    ('INS0106', 'IWM US', 'iShares Russell 2000 ETF', 'US000D4BFD06', 'DTC'),
    ('INS0107', 'EURPLN 1M FWD', 'EUR/PLN 1-Month Forward', NULL, 'CLS'),
    ('INS0108', 'AAPL US', 'Apple Inc', 'US0007465D71', 'DTC'),
    ('INS0109', 'EURCAD 1M FWD', 'EUR/CAD 1-Month Forward', NULL, 'CLS'),
    ('INS0110', 'EFA US', 'iShares MSCI EAFE ETF', 'US000ADFC403', 'DTC'),
    ('INS0111', 'UKT 1.71 01/37', 'United Kingdom Gilt 1.71% 2037', 'GB00061E8329', 'CREST'),
    ('INS0112', 'EOAN GY', 'E.ON SE', 'DE000DC61F46', 'Clearstream (CBF)'),
    ('INS0113', 'WSTP 1.2 04/39', 'Westpac Banking Corp 1.2% 2039', 'AU000CB1B053', 'Euroclear Bank'),
    ('INS0114', 'ISF LN', 'iShares Core FTSE 100 UCITS ETF', 'GB0008229261', 'CREST'),
    ('INS0115', 'INDON 3.625 02/30', 'Republic of Indonesia 3.625% 2030', 'US000161A320', 'Euroclear Bank'),
    ('INS0116', 'LQD US', 'iShares iBoxx USD Investment Grade Corporate Bond ETF', 'US0008C1B2B5', 'DTC'),
    ('INS0117', 'USDCAD 1M FWD', 'USD/CAD 1-Month Forward', NULL, 'CLS'),
    ('INS0118', 'SMFG 4.12 10/36', 'Sumitomo Mitsui Financial Group Inc 4.12% 2036', 'JP0001633437', 'Euroclear Bank'),
    ('INS0119', 'KO US', 'Coca-Cola Co', 'US000A667549', 'DTC'),
    ('INS0120', 'EURAUD 1M FWD', 'EUR/AUD 1-Month Forward', NULL, 'CLS'),
    ('INS0121', 'EGYPT 3.558 04/37', 'Arab Republic of Egypt 3.558% 2037', 'GB000A36CBA3', 'Euroclear Bank'),
    ('INS0122', 'SWISS 3.23 12/29', 'Swiss Confederation 3.23% 2029', 'CH0005577561', 'SIX SIS'),
    ('INS0123', 'RENTEN 1.36 12/35', 'Landwirtschaftliche Rentenbank 1.36% 2035', 'DE000944F9E3', 'Clearstream (CBF)'),
    ('INS0124', 'HYG US', 'iShares iBoxx USD High Yield Corporate Bond ETF', 'US000EDDA511', 'DTC'),
    ('INS0125', 'PHILIP 4.855 05/32', 'Republic of the Philippines 4.855% 2032', 'JP0001909175', 'Euroclear Bank'),
    ('INS0126', 'PEP US', 'PepsiCo Inc', 'US00034091F5', 'DTC'),
    ('INS0127', '1348 JT', 'MAXIS TOPIX ETF', 'JP000E00D525', 'JASDEC'),
    ('INS0128', 'JAGLR 0.968 06/30', 'Jaguar Land Rover Automotive PLC 0.968% 2030', 'GB000D790731', 'Euroclear Bank'),
    ('INS0129', 'TSCOLN 0.775 10/30', 'Tesco PLC 0.775% 2030', 'GB0001DBB9F6', 'Euroclear Bank'),
    ('INS0130', 'GLA 2.105 04/39', 'Greater London Authority 2.105% 2039', 'GB00095A4F31', 'CREST'),
    ('INS0131', 'TLT US', 'iShares 20+ Year Treasury Bond ETF', 'US000871EC57', 'DTC'),
    ('INS0132', 'MSFT 2.715 05/37', 'Microsoft Corp 2.715% 2037', 'US0007A61D04', 'Euroclear Bank'),
    ('INS0133', 'UKT 2.572 04/34', 'United Kingdom Gilt 2.572% 2034', 'GB0006F212D0', 'CREST'),
    ('INS0134', 'COP US', 'ConocoPhillips', 'US000BFDD359', 'DTC'),
    ('INS0135', 'VOO US', 'Vanguard S&P 500 ETF', 'US000ED08D79', 'DTC'),
    ('INS0136', 'ORA FP', 'Orange SA', 'FR000863A704', 'Euroclear France'),
    ('INS0137', 'USDMXN 1M FWD', 'USD/MXN 1-Month Forward', NULL, 'CLS'),
    ('INS0138', 'EURHUF 1M FWD', 'EUR/HUF 1-Month Forward', NULL, 'CLS'),
    ('INS0139', '9432 JT', 'Nippon Telegraph and Telephone Corp', 'JP000C379B88', 'JASDEC'),
    ('INS0140', 'ENB CT', 'Enbridge Inc', 'CA0003D14FA9', 'CDS'),
    ('INS0141', 'MUV2 GY', 'Muenchener Rueckversicherung AG', 'DE0007FECD42', 'Clearstream (CBF)'),
    ('INS0142', 'EURUSD 3M FWD', 'EUR/USD 3-Month Forward', NULL, 'CLS'),
    ('INS0143', 'IFX GY', 'Infineon Technologies AG', 'DE000443E593', 'Clearstream (CBF)'),
    ('INS0144', 'WES AU', 'Wesfarmers Ltd', 'AU0009211C57', 'CHESS'),
    ('INS0145', 'INDOAU 2.498 09/37', 'Republic of Indonesia 2.498% 2037', 'AU000B4EAFA2', 'Euroclear Bank'),
    ('INS0146', 'BMW 4.23 11/27', 'BMW Finance NV 4.23% 2027', 'DE0001BCAA64', 'Euroclear Bank'),
    ('INS0147', 'SAP GY', 'SAP SE', 'DE0007164600', 'Clearstream (CBF)'),
    ('INS0148', 'PHIA NA', 'Koninklijke Philips NV', 'NL00057B7DB2', 'Euroclear Nederland'),
    ('INS0149', 'COLOM 4.342 07/32', 'Republic of Colombia 4.342% 2032', 'US0009D0BB14', 'Euroclear Bank'),
    ('INS0150', 'PFE US', 'Pfizer Inc', 'US000DC7F531', 'DTC'),
    ('INS0151', 'ARBNCH 4.963 12/29', 'Aryzta AG 4.963% 2029', 'CH0004098CA1', 'Euroclear Bank'),
    ('INS0152', 'PWLB 3.855 01/27', 'UK Municipal Bonds Agency 3.855% 2027', 'GB0008D78BF0', 'CREST'),
    ('INS0153', 'BATS LN', 'British American Tobacco PLC', 'GB00074FF679', 'CREST'),
    ('INS0154', 'BKW SW', 'BKW AG', 'CH000A76DD14', 'SIX SIS'),
    ('INS0155', 'VOW3 GY', 'Volkswagen AG', 'DE000FAFE906', 'Clearstream (CBF)'),
    ('INS0156', 'PLD US', 'Prologis Inc', 'US000AD78E85', 'DTC'),
    ('INS0157', 'BP LN', 'BP PLC', 'GB000E8BCB77', 'CREST'),
    ('INS0158', 'KFW 3.062 08/31', 'Kreditanstalt fuer Wiederaufbau 3.062% 2031', 'DE0000BC0804', 'Clearstream (CBF)'),
    ('INS0159', '6758 JT', 'Sony Group Corp', 'JP000D5C0095', 'JASDEC'),
    ('INS0160', 'AUDJPY 1M FWD', 'AUD/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0161', 'RWE GY', 'RWE AG', 'DE000E359552', 'Clearstream (CBF)'),
    ('INS0162', 'OAT 4.41 06/38', 'Republique Francaise 4.41% 2038', 'FR000C3B3AD7', 'Euroclear France'),
    ('INS0163', 'MC FP', 'LVMH Moet Hennessy Louis Vuitton SE', 'FR0003FEFD46', 'Euroclear France'),
    ('INS0164', 'GBPJPY 1M FWD', 'GBP/JPY 1-Month Forward', NULL, 'CLS'),
    ('INS0165', 'XOM 4.623 05/28', 'Exxon Mobil Corp 4.623% 2028', 'US0009808F89', 'Euroclear Bank'),
    ('INS0166', 'VZ 4.348 09/39', 'Verizon Communications Inc 4.348% 2039', 'US00013AAD46', 'Euroclear Bank'),
    ('INS0167', 'MSFT US', 'Microsoft Corp', 'US00029623E5', 'DTC'),
    ('INS0168', 'TELEFO 3.837 04/35', 'Telefonica Emisiones SA 3.837% 2035', 'ES000FEFE414', 'Euroclear Bank'),
    ('INS0169', 'BPLN 1.115 07/38', 'BP Capital Markets PLC 1.115% 2038', 'GB000A0ADE96', 'Euroclear Bank'),
    ('INS0170', 'TOYOTA 4.505 01/27', 'Toyota Motor Corp 4.505% 2027', 'JP000794CAB6', 'Euroclear Bank'),
    ('INS0171', 'GBPCHF 1M FWD', 'GBP/CHF 1-Month Forward', NULL, 'CLS'),
    ('INS0172', 'SSE LN', 'SSE PLC', 'GB0001ABC9A9', 'CREST'),
    ('INS0173', '1605 JT', 'Inpex Corp', 'JP000F57D670', 'JASDEC'),
    ('INS0174', 'GBPCAD 1M FWD', 'GBP/CAD 1-Month Forward', NULL, 'CLS'),
    ('INS0175', 'ENGI FP', 'Engie SA', 'FR0005787FC2', 'Euroclear France'),
    ('INS0176', 'OSAKA 4.763 03/38', 'Osaka Prefecture 4.763% 2038', 'JP0002FA4F90', 'JASDEC'),
    ('INS0177', 'GS US', 'Goldman Sachs Group Inc', 'US000250D176', 'DTC'),
    ('INS0178', 'GBPAUD 1M FWD', 'GBP/AUD 1-Month Forward', NULL, 'CLS'),
    ('INS0179', 'AZN LN', 'AstraZeneca PLC', 'GB000B49C9A9', 'CREST'),
    ('INS0180', 'STW AU', 'SPDR S&P/ASX 200 Fund', 'AU000E5615B0', 'CHESS'),
    ('INS0181', 'ONT 1.393 03/28', 'Province of Ontario 1.393% 2028', 'CA0001397110', 'CDS'),
    ('INS0182', 'GLD US', 'SPDR Gold Shares', 'US0000FD05E9', 'DTC'),
    ('INS0183', 'GBPNZD 1M FWD', 'GBP/NZD 1-Month Forward', NULL, 'CLS'),
    ('INS0184', 'CADCHF 1M FWD', 'CAD/CHF 1-Month Forward', NULL, 'CLS'),
    ('INS0185', 'USDSGD 1M FWD', 'USD/SGD 1-Month Forward', NULL, 'CLS'),
    ('INS0186', 'NEE US', 'NextEra Energy Inc', 'US0004378B35', 'DTC'),
    ('INS0187', 'AAPL 4.35 12/39', 'Apple Inc 4.35% 2039', 'US0007155F25', 'Euroclear Bank'),
    ('INS0188', 'HSBC 0.96 07/33', 'HSBC Holdings PLC 0.96% 2033', 'GB00022F14A1', 'Euroclear Bank'),
    ('INS0189', 'CCL 3.74 10/39', 'Carnival Corp 3.74% 2039', 'US00030D71A2', 'Euroclear Bank'),
    ('INS0190', 'AKZA NA', 'Akzo Nobel NV', 'NL000CCF1944', 'Euroclear Nederland'),
    ('INS0191', 'DUK US', 'Duke Energy Corp', 'US00067028E0', 'DTC'),
    ('INS0192', 'SOFTBK 4.793 12/40', 'SoftBank Group Corp 4.793% 2040', 'JP00072AEC73', 'Euroclear Bank'),
    ('INS0193', 'JPM 2.96 01/31', 'JPMorgan Chase & Co 2.96% 2031', 'US000F30DA08', 'Euroclear Bank'),
    ('INS0194', 'MS US', 'Morgan Stanley', 'US000FB544E6', 'DTC'),
    ('INS0195', 'WKL NA', 'Wolters Kluwer NV', 'NL0004D25DA2', 'Euroclear Nederland'),
    ('INS0196', 'USDZAR 1M FWD', 'USD/ZAR 1-Month Forward', NULL, 'CLS'),
    ('INS0197', 'GBPSEK 1M FWD', 'GBP/SEK 1-Month Forward', NULL, 'CLS'),
    ('INS0198', 'USDBRL 1M FWD', 'USD/BRL 1-Month Forward', NULL, 'CLS'),
    ('INS0199', '1557 JT', 'SPDR S&P 500 ETF Trust Tokyo Listing', 'JP00061CE982', 'JASDEC'),
    ('INS0200', 'CMCSA US', 'Comcast Corp', 'US000663C6B0', 'DTC')
  ) AS m(instrument_id, ticker, name, isin, csd)
 WHERE t.INSTRUMENT_ID = m.instrument_id;


/* ============================================================================
   2. TRADES — quantity, matched status, matched timestamp
   ============================================================================
   All three are derived deterministically from HASH(TRADE_ID) / HASH(
   INSTRUMENT_ID), never from RAND() or CURRENT_TIMESTAMP, so the backfill is
   reproducible and a re-run writes byte-identical values (project rule:
   deterministic sample data).

   QUANTITY is derived from the row's EXISTING notional and a per-instrument
   reference price, so quantity and notional never fight on screen. The implied
   price is sane for the asset class and is stable per instrument (the same
   instrument prices the same way across all 50,000 trades):
     equity : 20-399 per share, quantity rounded to a 100-share lot
     etf    : 30-499 per unit
     bond   : quoted 95-105 per 100 face; quantity IS face value, rounded to 1,000
     fx fwd : quantity = notional (an FX forward has no unit count)
   Display language per asset class is fixed in CLAUDE.md: "shares" for
   equities and ETFs, "face" for bonds, notional-only for FX forwards.

   BITAND(HASH(x), 2147483647) keeps the hash non-negative without ABS(), which
   would overflow on the minimum 64-bit value.
   ------------------------------------------------------------------------- */

ALTER TABLE TRADES ADD COLUMN IF NOT EXISTS QUANTITY   NUMBER(38,2);
ALTER TABLE TRADES ADD COLUMN IF NOT EXISTS IS_MATCHED BOOLEAN;
ALTER TABLE TRADES ADD COLUMN IF NOT EXISTS MATCHED_AT TIMESTAMP_NTZ;

UPDATE TRADES t
   SET QUANTITY = CASE i.ASSET_CLASS
       WHEN 'equity' THEN GREATEST(
              ROUND(t.NOTIONAL / (20 + MOD(BITAND(HASH(i.INSTRUMENT_ID), 2147483647), 380)), -2),
              100)
       WHEN 'etf' THEN GREATEST(
              ROUND(t.NOTIONAL / (30 + MOD(BITAND(HASH(i.INSTRUMENT_ID), 2147483647), 470)), 0),
              1)
       WHEN 'bond' THEN GREATEST(
              ROUND(t.NOTIONAL / ((95 + MOD(BITAND(HASH(i.INSTRUMENT_ID), 2147483647), 11)) / 100.0), -3),
              1000)
       ELSE ROUND(t.NOTIONAL, 2)          /* fx_forward: quantity = notional */
     END
  FROM INSTRUMENTS i
 WHERE t.INSTRUMENT_ID = i.INSTRUMENT_ID;

/* ~97% matched. Unmatched rows carry a NULL MATCHED_AT, which is the point:
   an unmatched trade at T+1 is a fail precursor an analyst should see. */
UPDATE TRADES
   SET IS_MATCHED = (MOD(BITAND(HASH(TRADE_ID), 2147483647), 100) < 97);

/* Matched on the evening of trade date, 18:00-20:59 local. A separate hash seed
   keeps the minute uncorrelated with the matched/unmatched draw. */
UPDATE TRADES
   SET MATCHED_AT = CASE
       WHEN IS_MATCHED THEN DATEADD(
              minute,
              MOD(BITAND(HASH(TRADE_ID || 'm'), 2147483647), 180),
              DATEADD(hour, 18, TO_TIMESTAMP_NTZ(TRADE_DATE)))
       ELSE NULL
     END;


/* ============================================================================
   3. COUNTERPARTIES — settlement ops contact
   ============================================================================
   Phone format follows the counterparty's own REGION, which is not modified.
   Deterministic from HASH(COUNTERPARTY_ID).
   ------------------------------------------------------------------------- */

ALTER TABLE COUNTERPARTIES ADD COLUMN IF NOT EXISTS OPS_CONTACT_NAME  VARCHAR(120);
ALTER TABLE COUNTERPARTIES ADD COLUMN IF NOT EXISTS OPS_CONTACT_PHONE VARCHAR(30);

UPDATE COUNTERPARTIES
   SET OPS_CONTACT_NAME = NAME || ' Settlements',
       OPS_CONTACT_PHONE = CASE REGION
         WHEN 'EMEA'  THEN '+44 20 '  || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID),       2147483647), 10000), 4, '0')
                                      || ' ' || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID || 'p'), 2147483647), 10000), 4, '0')
         WHEN 'APAC'  THEN '+65 '     || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID),       2147483647), 10000), 4, '0')
                                      || ' ' || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID || 'p'), 2147483647), 10000), 4, '0')
         WHEN 'NA'    THEN '+1 212 '  || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID),       2147483647), 1000),  3, '0')
                                      || ' ' || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID || 'p'), 2147483647), 10000), 4, '0')
         WHEN 'LATAM' THEN '+55 11 '  || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID),       2147483647), 10000), 4, '0')
                                      || ' ' || LPAD(MOD(BITAND(HASH(COUNTERPARTY_ID || 'p'), 2147483647), 10000), 4, '0')
         ELSE '+44 20 0000 0000'
       END;


/* ============================================================================
   4. SETTLEMENT_HISTORY — counterparty reference
   ============================================================================
   Additive and purely derived: the counterparty of a settlement is the
   counterparty of its trade. SETTLEMENT_HISTORY is 1:1 with TRADES on TRADE_ID,
   so this is a lookup, not a judgement. It exists so SO Settlement History can
   carry an N:1 relationship to SO Counterparty and the recent-fails view can
   filter by counterparty in one hop.
   ------------------------------------------------------------------------- */

ALTER TABLE SETTLEMENT_HISTORY ADD COLUMN IF NOT EXISTS COUNTERPARTY_ID VARCHAR(10);

UPDATE SETTLEMENT_HISTORY sh
   SET COUNTERPARTY_ID = t.COUNTERPARTY_ID
  FROM TRADES t
 WHERE sh.TRADE_ID = t.TRADE_ID;


/* ============================================================================
   5. VERIFICATION — expected results stated per query
   ============================================================================ */

/* 5.1 INSTRUMENTS null counts and distinctness.
   EXPECTED: total_rows 200 | ticker_nulls 0 | name_nulls 0 | csd_nulls 0
             | isin_nulls 32  <-- exactly the 32 fx_forward rows, by design
             | ticker_orig_nulls 0 | distinct_tickers 200 */
SELECT COUNT(*)                                        AS total_rows,
       COUNT_IF(TICKER      IS NULL)                   AS ticker_nulls,
       COUNT_IF(NAME        IS NULL)                   AS name_nulls,
       COUNT_IF(CSD         IS NULL)                   AS csd_nulls,
       COUNT_IF(ISIN        IS NULL)                   AS isin_nulls,
       COUNT_IF(TICKER_ORIG IS NULL)                   AS ticker_orig_nulls,
       COUNT(DISTINCT TICKER)                          AS distinct_tickers
  FROM INSTRUMENTS;

/* 5.2 Every NULL ISIN must be an FX forward, and every FX forward must be NULL.
   EXPECTED: one row -> fx_forward | 32 | 32 */
SELECT ASSET_CLASS, COUNT(*) AS row_cnt, COUNT_IF(ISIN IS NULL) AS isin_nulls
  FROM INSTRUMENTS
 WHERE ISIN IS NULL OR ASSET_CLASS = 'fx_forward'
 GROUP BY ASSET_CLASS;

/* 5.3 CSD must be consistent with asset class / currency.
   EXPECTED: no CLS outside fx_forward, no fx_forward outside CLS -> 0 rows */
SELECT INSTRUMENT_ID, ASSET_CLASS, CURRENCY, TICKER, CSD
  FROM INSTRUMENTS
 WHERE (CSD = 'CLS') <> (ASSET_CLASS = 'fx_forward');

/* 5.4 The three demo pins.
   EXPECTED exactly:
     INS0078 | BAS GY        | BASF SE                 | DE000BASF111 | Clearstream (CBF)
     INS0142 | EURUSD 3M FWD | EUR/USD 3-Month Forward | NULL         | CLS
     INS0147 | SAP GY        | SAP SE                  | DE0007164600 | Clearstream (CBF) */
SELECT INSTRUMENT_ID, TICKER, NAME, ISIN, CSD, ASSET_CLASS, CURRENCY, TICKER_ORIG
  FROM INSTRUMENTS
 WHERE INSTRUMENT_ID IN ('INS0078','INS0142','INS0147')
 ORDER BY INSTRUMENT_ID;

/* 5.5 Sample identities across asset classes — eyeball for realism.
   EXPECTED: equities read as real listings, bonds as issuer+coupon+maturity,
             FX as pair+tenor, and each CSD matches the currency's market. */
SELECT INSTRUMENT_ID, ASSET_CLASS, CURRENCY, TICKER, NAME, ISIN, CSD
  FROM INSTRUMENTS
 WHERE INSTRUMENT_ID IN ('INS0001','INS0003','INS0004','INS0013','INS0044',
                         'INS0063','INS0073','INS0089','INS0127','INS0173')
 ORDER BY INSTRUMENT_ID;

/* 5.6 TRADES null counts and matched rate.
   EXPECTED: total_rows 50000 | quantity_nulls 0 | is_matched_nulls 0
             | matched_true ~48,500 (97% +/- ~150 from hash spread)
             | matched_at_nulls = 50000 - matched_true  (exactly the unmatched)
             | matched_pct ~97.0 */
SELECT COUNT(*)                                  AS total_rows,
       COUNT_IF(QUANTITY   IS NULL)              AS quantity_nulls,
       COUNT_IF(IS_MATCHED IS NULL)              AS is_matched_nulls,
       COUNT_IF(IS_MATCHED)                      AS matched_true,
       COUNT_IF(MATCHED_AT IS NULL)              AS matched_at_nulls,
       ROUND(100.0 * COUNT_IF(IS_MATCHED) / COUNT(*), 2) AS matched_pct
  FROM TRADES;

/* 5.7 MATCHED_AT must be NULL exactly when unmatched, and otherwise fall on the
   evening of trade date.
   EXPECTED: 0 rows */
SELECT TRADE_ID, TRADE_DATE, IS_MATCHED, MATCHED_AT
  FROM TRADES
 WHERE (MATCHED_AT IS NULL) <> (NOT IS_MATCHED)
    OR (MATCHED_AT IS NOT NULL
        AND (DATE(MATCHED_AT) <> TRADE_DATE
             OR HOUR(MATCHED_AT) NOT BETWEEN 18 AND 20))
 LIMIT 20;

/* 5.8 Implied unit price must be sane for the asset class.
   EXPECTED: equity 20-400 | etf 30-500 | bond ~0.95-1.05 (price per unit face)
             | fx_forward exactly 1.0 */
SELECT i.ASSET_CLASS,
       COUNT(*)                                              AS row_cnt,
       ROUND(MIN(t.NOTIONAL / NULLIF(t.QUANTITY, 0)), 4)     AS min_implied_price,
       ROUND(MAX(t.NOTIONAL / NULLIF(t.QUANTITY, 0)), 4)     AS max_implied_price
  FROM TRADES t
  JOIN INSTRUMENTS i ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
 GROUP BY i.ASSET_CLASS
 ORDER BY i.ASSET_CLASS;

/* 5.9 Sample trades showing quantity and notional side by side.
   EXPECTED: the two numbers imply a believable price and do not fight. */
SELECT t.TRADE_ID, i.TICKER, i.ASSET_CLASS, t.DIRECTION,
       t.QUANTITY, t.NOTIONAL, t.CURRENCY,
       ROUND(t.NOTIONAL / NULLIF(t.QUANTITY, 0), 4) AS implied_price,
       t.IS_MATCHED, t.MATCHED_AT
  FROM TRADES t
  JOIN INSTRUMENTS i ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
 WHERE t.TRADE_ID IN ('TRD016924','TRD044567','TRD031208')
 ORDER BY t.TRADE_ID;

/* 5.10 COUNTERPARTIES ops contacts.
   EXPECTED: total_rows 50 | name_nulls 0 | phone_nulls 0 | fallback_phones 0 */
SELECT COUNT(*)                                          AS total_rows,
       COUNT_IF(OPS_CONTACT_NAME  IS NULL)               AS name_nulls,
       COUNT_IF(OPS_CONTACT_PHONE IS NULL)               AS phone_nulls,
       COUNT_IF(OPS_CONTACT_PHONE = '+44 20 0000 0000')  AS fallback_phones
  FROM COUNTERPARTIES;

/* 5.11 Ops contact sample, incl. the counterparty named in the mockups.
   EXPECTED: 'Diamond Trust Settlements' with an APAC (+65) number. */
SELECT COUNTERPARTY_ID, NAME, REGION, RISK_TIER,
       OPS_CONTACT_NAME, OPS_CONTACT_PHONE
  FROM COUNTERPARTIES
 WHERE COUNTERPARTY_ID IN ('CP0023','CP0031','CP0045','CP0011')
 ORDER BY COUNTERPARTY_ID;

/* 5.12 SETTLEMENT_HISTORY counterparty backfill.
   EXPECTED: total_rows 50000 | cpty_nulls 0 | mismatched_vs_trades 0 */
SELECT COUNT(*)                                   AS total_rows,
       COUNT_IF(sh.COUNTERPARTY_ID IS NULL)       AS cpty_nulls,
       COUNT_IF(sh.COUNTERPARTY_ID <> t.COUNTERPARTY_ID) AS mismatched_vs_trades
  FROM SETTLEMENT_HISTORY sh
  JOIN TRADES t ON t.TRADE_ID = sh.TRADE_ID;

/* 5.13 The recent-fails view this enables, for the mockup's counterparty.
   EXPECTED: 5 rows, most recent first, each with a real instrument and value.
             NOTE the dates: this data ends 2025-07-20, which is why the card is
             labelled "Recent settlement fails" with no time-window claim. */
SELECT sh.ACTUAL_SETTLEMENT_DATE AS fail_date, sh.TRADE_ID, i.TICKER,
       sh.FAIL_REASON, t.NOTIONAL, t.CURRENCY
  FROM SETTLEMENT_HISTORY sh
  JOIN TRADES t      ON t.TRADE_ID = sh.TRADE_ID
  JOIN INSTRUMENTS i ON i.INSTRUMENT_ID = t.INSTRUMENT_ID
 WHERE sh.COUNTERPARTY_ID = 'CP0023'
   AND sh.STATUS = 'FAILED'
 ORDER BY sh.ACTUAL_SETTLEMENT_DATE DESC
 LIMIT 5;

/* 5.14 BASELINE INVARIANTS — proof the script disturbed nothing.
   These are the CLAUDE.md assertion targets. If any number moved, STOP.
   EXPECTED: total_trades 50000 | failed 6416 | fail_rate_pct 12.83 */
SELECT COUNT(*)                                        AS total_settlements,
       COUNT_IF(STATUS = 'FAILED')                     AS failed,
       ROUND(100.0 * COUNT_IF(STATUS = 'FAILED') / COUNT(*), 2) AS fail_rate_pct
  FROM SETTLEMENT_HISTORY;

/* EXPECTED exactly: Critical 1824 | High 10637 | Medium 16995 | Low 20544 */
SELECT RISK_TIER, COUNT(*) AS trades
  FROM TRADE_PREDICTIONS
 GROUP BY RISK_TIER
 ORDER BY trades;

/* EXPECTED: instruments 200 | counterparties 50 | trades 50000 | predictions 50000
   (run BEFORE the hero INSERT script; the hero adds 1 trade + 1 prediction) */
SELECT (SELECT COUNT(*) FROM INSTRUMENTS)       AS instruments,
       (SELECT COUNT(*) FROM COUNTERPARTIES)    AS counterparties,
       (SELECT COUNT(*) FROM TRADES)            AS trades,
       (SELECT COUNT(*) FROM TRADE_PREDICTIONS) AS predictions;

/* ======================== end of script ================================== */
