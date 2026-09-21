# Packet Spec — Settlement Operations demo

The Phase 5 simulation packet: **fifteen authored trades per demo run** — three
seeded stories that open cases, twelve background trades that do not.
Regenerated 2026-09-10 against Scott's four rulings and the measured schema.
Expands `hero-trade-spec.md`, which stays the contract for the hero and both
mockups and has been updated to agree with this file.

**We author the packet; we do not adopt one.** Every row is inserted at demo
time into the reserved `TRD9` id range. No baseline trade, prediction,
instrument, counterparty or settlement record is modified.

> **FINAL 2026-09-10.** Probe P9 supplied the last measured inputs: `SCORED_AT` is
> `TIMESTAMP_NTZ`; FINSERVADMIN owns the schema and both tables, so no grants are
> needed; and the Snowsight session clock is America/Los_Angeles, which is why the
> run date is the UTC date (§2). `snowflake/simulate-reset-procedures.sql` carries no
> markers and was run in Snowsight on 2026-09-11; its evidence is `snowflake/verification-summary.sql`.

---

## 0. Where every fact in this file came from

| Fact | Source |
|---|---|
| TRADES and TRADE_PREDICTIONS insert column lists | `snowflake/hero-trade-insert.sql` — the proven insert, mirrored name for name |
| `TOP_RISK_FACTORS` shape: three elements; `[0]` Counterparty Risk = 2.5 × fail rate; fixed pairs at `[1]` / `[2]` | Probes P5 (per-position counts summing to 50,000) and P4 (five specimens), 2026-09-10 |
| `MATCHED_AT` is `TIMESTAMP_NTZ` | `snowflake/snowflake-mockup-columns.sql` line 332, the DDL that created it (ran clean) |
| Appian reads Snowflake `TIMESTAMP_NTZ` as UTC | Measured 2026-09-10 through the record layer (§2) |
| `SCORED_AT` is `TIMESTAMP_NTZ`, nullable, `DEFAULT CURRENT_TIMESTAMP()`; FINSERVADMIN owns the schema and both tables and holds CREATE PROCEDURE; Snowsight session clock is America/Los_Angeles | Probe P9, 2026-09-10 |
| Tier bands | Measured 2026-09-10 through the record layer on all 50,000 baseline predictions (§3) |
| Every instrument, counterparty and trader id; 9.20% book average | Read live 2026-09-10 |
| `SO_createTriageCase` accepts `failReason` and `cutoffTs` | `getProcessModel`, 2026-09-10 |
| Case-creation criterion, `MATCHED_AT` rule, `SCORED_AT` rule, id scheme, baseline-shaped factors | **Scott's rulings, 2026-09-10** |

---

## 1. Run name and trade ids — ruled 2026-09-10

**Run name:** 1–13 characters, **letters, digits and dash only**. Console
placeholder: `1012-ACME`. Validated twice — by the console (Part B) and again by
both procedures, which refuse anything else with a plain reason.

    <code>   = UPPER(run name with dashes removed)        e.g. 1012-ACME -> 1012ACME
    TRADE_ID = 'TRD9' || <code> || <seq>                   e.g. TRD91012ACME01
    <seq>    = the fixed set 01..15

- **Length:** `4 + ≤13 + 2 = ≤19`, inside `VARCHAR(20)`.
- `TRD9` stays the reserved prefix. Every baseline id is `TRD0…`, so `Verify Ready`'s
  `NOT LIKE 'TRD9%'` baseline exclusion is unaffected.
- **Reset deletes the EXACT id list** — `'TRD9' || <code> || seq` for the fifteen
  sequences — **never `LIKE`.** A `LIKE 'TRD9' || code || '%'` predicate is
  prefix-unsafe once codes vary in length: resetting `DEMO1` would also delete
  `DEMO12`'s rows. With a fixed two-digit sequence, two ids can only be equal if
  their codes are equal, so the exact list is collision-free at any code length.
  `verification-summary.sql` proves it with runs `VFY1` and `VFY12` (check 20).
- **Two names collide only if they differ by dashes alone** (`1012-ACME` and
  `1012ACME`). That is predictable and explainable, and harmless because
  `SIMULATE_FEED` is idempotent — re-running a name replaces that run.
- **Supersedes `hero-trade-spec.md` §2's three-character code.** The manual
  `hero-trade-delete.sql` deletes by `LIKE` and is therefore unsafe under this
  scheme; it is bannered superseded and replaced by `RESET_SESSION`.

---

## 2. Timestamps — every one relative to now

| Field | Derivation | Rule |
|---|---|---|
| `TRADE_DATE` | `DATEADD(day, -1, run_date)`, `run_date = SYSDATE()::DATE` | The UTC run date — judgment call below |
| `EXPECTED_SETTLEMENT_DATE` | `run_date` | Settles on the run date, T+1 |
| `MATCHED_AT` | `DATEADD(minute, m, DATEADD(hour, 18, TO_TIMESTAMP_NTZ(<trade date>)))`, `m` varied per trade | **Ruled 2026-09-10: trade-date evening**, the hero-insert precedent. Cast matches the column's DDL type. The `cutoff − 4h` formula is retired. |
| `SCORED_AT` | `SYSDATE()::TIMESTAMP_NTZ` | **Ruled 2026-09-10: call time, scoring on arrival**, retiring the hero's 05:00 overnight stamp. The column is `TIMESTAMP_NTZ` (P9) |
| case `cutoffTs` *(Appian)* | `now() + <story offset>` | Passed into `SO_createTriageCase`'s `cutoffTs` parameter, which is written as given (measured) |

**Why `SCORED_AT` must be UTC wall clock — MEASURED 2026-09-10.** Appian reads a
Snowflake `TIMESTAMP_NTZ` as UTC. `TRD000009`'s `MATCHED_AT` was generated as NTZ
19:11. Through the record layer it reads back as `gmt 19:11`, and `text()` renders
it `14:11` for a UTC−4 user. A "scored just now" stamp must therefore be written
as the **UTC** wall clock:

- **Written as `SYSDATE()::TIMESTAMP_NTZ`** — UTC, and independent of the caller's
  session timezone. P9 confirms the column is `TIMESTAMP_NTZ`.
- **The column's own `DEFAULT CURRENT_TIMESTAMP()` must never be relied on.** P9's
  clock row shows the Snowsight session at America/Los_Angeles
  (`CURRENT_TIMESTAMP` 12:52 −0700 against `SYSDATE` 19:52). A defaulted stamp is
  the Pacific wall clock, which Appian reads as UTC — so it looks seven hours old.
  `verification-summary.sql` check 15 fails on exactly that.

**Run date is the UTC date — a judgment call on a measured basis.** Because the
session is Pacific, `CURRENT_DATE` (the hero insert's form) is the *Pacific* date: a
day behind an APAC business morning, and behind London before 08:00. The UTC date
is right for New York until 20:00, London all day and Singapore from 08:00. It is
independent of whichever session calls the procedure, and it is the clock Appian
reads NTZ stamps on. Reverting to `CURRENT_DATE` is one line in `SIMULATE_FEED`.

**Display consequence of the `MATCHED_AT` ruling, for the talk track only.** A
trade-date 18:mm NTZ stamp renders as **14:mm the day before for a New York viewer**
and 19:mm for London. The baseline behaves identically, since it was generated the
same way. It is still an honest stamp on this clock, which is the display condition.

---

## 3. Case-creation criterion — ruled 2026-09-10

**A case is created when `RISK_TIER` is `High` or `Critical`.**

- **Source:** Scott's ruling, aligned with the semantic model's verified query
  *notional at risk (High/Critical)* (CLAUDE.md, Snowflake environment) — one risk
  language across case creation, the screens and Cortex.
- **Implemented once**, as a tier check in the Part B intake model. It reads SO Trade
  Predictions' mapped `riskTier` field, so no record-type re-sync is needed.
- **History:** before this ruling no object implemented a criterion. Measured:
  `SO_createTriageCase` has no caller and gates only on a duplicate open case, and
  the Phase 3 specimens were hand-picked.
- **Not built:** a probability-floor constant. It appears as a **roadmap line in the
  talk track** and nowhere else.

**Tier bands, measured 2026-09-10 on all 50,000 baseline predictions:**

| Tier | min p | max p | rows |
|---|---|---|---|
| Critical | 0.7507 | 0.95 | 1,824 |
| High | 0.5003 | 0.7495 | 10,637 |
| Medium | 0.251 | 0.4998 | 16,995 |
| Low | 0.0537 | 0.2498 | 20,544 |

**Packet consequence:** the three stories are High or Critical and open cases. All
twelve background trades sit **below 0.5003**, the High floor (maximum authored
0.45). Every authored probability→tier pair falls inside its band, and
`snowflake/verification-summary.sql` asserts that for all fifteen (check 08).

---

## 4. Fail reasons and risk factors (ruled 2026-09-10)

### Fail reasons — Appian-authored per story

`TRADE_PREDICTIONS` has no fail-reason column, and `TOP_RISK_FACTORS` holds risk
**drivers**, not fail reasons (below). A fail reason is therefore a per-story
attribute authored in this file. The Part B intake passes it into
`SO_createTriageCase`'s required `failReason` parameter, which writes it verbatim
to `SO Settlement Case.failReason` and composes it into the Case Created event.
This is the proven hero path: the stored event reads
`Case created from feed for trade TRD9NY101 (insufficient_securities, desk EQ_FLOW)`.
`SO_caseContext` then gives it to the agent as the predicted reason.

| seq | story | `failReason` | `cutoffTs` offset |
|---|---|---|---|
| `01` | hero · held for review | `insufficient_securities` | `+3h05m` |
| `02` | escalation · lag exceeds window | `funding_gap` | `+2h30m` |
| `03` | straight-through · clean facts | `operational_error` | `+9h00m` |

Keyed by the two-digit sequence at the end of the trade id. Background trades never
reach case creation, so they carry neither attribute. **Intake does not read
`TOP_RISK_FACTORS` this phase.** Reading it is a later item: it needs a Designer
re-sync, and VARIANT mapping on a record type is untested.

### TOP_RISK_FACTORS — baseline-shaped on every packet row

**Ruled 2026-09-10: packet predictions are baseline-shaped.** The hero insert's NULL
precedent is retired.

**Measured shape** (probes P4 and P5):
- An ARRAY of **exactly three** `{contribution, factor}` objects.
- **`[0]` is Counterparty Risk** on 48,157 of 50,000 rows, with **contribution =
  2.5 × the counterparty's `HISTORICAL_FAIL_RATE`**, stored as DOUBLE. It is exact on
  all five P4 specimens: Unity Bank 0.1105 → 0.27625 · Zephyr 0.0955 → 0.23875 ·
  Jade Capital 0.2123 → 0.53075 (twice) · Liberty Trust 0.2158 → 0.5395. P5's
  frequent values fit too (e.g. 0.11625 = 2.5 × Summit Finance's 0.0465). The
  procedure computes it from `COUNTERPARTIES` at insert, so it cannot drift from
  the trade's counterparty.
- **`[1]` and `[2]`** each carry one pair from a fixed set of (factor, DECIMAL
  contribution) pairs. P5's counts at each position sum to exactly 50,000, so the
  sets below are complete:

| position | pairs observed (rows) |
|---|---|
| `[1]` | Low Base Risk 0.02 (19,823) · Extended Settlement 0.02 (9,551) · High Volatility 0.06 (9,092) · Slow Confirmation 0.05 (5,241) · Month-End Pressure 0.07 (3,048) · Counterparty Risk (1,843) · Large Notional 0.02 (1,402) |
| `[2]` | Normal Operations 0.01 (28,590) · Extended Settlement 0.01 (14,742) · Month-End Pressure 0.07 (4,995) · Large Notional 0.05 (1,673) |

**THE COHERENCE RULE — ruled 2026-09-10: a packet row's factors must never
contradict its story's fail reason or its lane.** Applied:
- **Never Extended Settlement** — every packet trade settles T+1.
- **Never Month-End Pressure** — the run date is arbitrary, so it would be false on
  most days.
- **Never High Volatility** — no volatility threshold has been measured, so it
  cannot be shown to cohere with any packet instrument.
- **Slow Confirmation only where confirmation IS the story** — seq 02, whose lag
  exceeds the window.

| seq | `[0]` Counterparty Risk | `[1]` | `[2]` | why it coheres |
|---|---|---|---|---|
| `01` hero | 0.49725 (Diamond Trust 19.89%) | Large Notional 0.02 | Large Notional 0.05 | counterparty and size are what hold it for review |
| `02` escalation | 0.475 (Horizon Securities 19.00%) | Slow Confirmation 0.05 | Large Notional 0.05 | the measured TRD044567 array; the lag is the story |
| `03` straight-through | 0.05375 (Rosewood Trust 2.15%) | Low Base Risk 0.02 | Normal Operations 0.01 | nothing concerning |
| `04`–`15` background | 2.5 × the counterparty's rate | Low Base Risk 0.02 — **Large Notional 0.02 on `10` and `12`** | Normal Operations 0.01 — **Large Notional 0.05 on `10` and `12`** | generic low weight; `10` and `12` carry the largest nominal notionals and the Large Notional pair measured on 1,402 baseline rows |

**PAIRS ARE AUTHORED ONLY WHERE THE BASELINE PRODUCES THEM JOINTLY — corrected 2026-09-11.**
Positions `[1]` and `[2]` were first authored from P5's per-position lists, which count each
position separately. That produced **Low Base Risk 0.02 + Large Notional 0.05** on seq `10`
and `12` — a pair on **0** baseline rows (check 12, run of 2026-09-11). Under the coherence
rule, the allowed pairs and their measured status are:

| `[1]` + `[2]` | baseline rows (Counterparty Risk first) | source |
|---|---|---|
| Large Notional 0.02 + Large Notional 0.05 | **1,402** | check 12, 2026-09-11 run |
| Slow Confirmation 0.05 + Large Notional 0.05 | ≥ 1 — escalation only | TRD044567 specimen (P4) |
| Low Base Risk 0.02 + Normal Operations 0.01 | *not yet visible* — truncated in the check 12 detail | next run |
| Low Base Risk 0.02 + Large Notional 0.05 | **0** — removed | check 12, 2026-09-11 run |
| Large Notional 0.02 + Normal Operations 0.01 | **0** — not usable | all 1,402 Large Notional 0.02 rows at `[1]` (P5) pair with Large Notional 0.05 (check 12) |

The corrected packet therefore uses **three** distinct pairs, and no allowed fourth exists.

**Two departures from the ruling's wording, both forced by the coherence rule and the
measured shape:**
1. **No confirmation factor on the hero.** The ruling called for
   counterparty/confirmation/notional flavour, but the vocabulary's only confirmation
   factor is Slow Confirmation, and the hero's 1.15h lag fits its ~3h window. Carrying
   it would contradict the held-for-review lane that the hero's assessment argues.
   Counterparty and notional carry the hero.
2. **The escalation cannot be lag-*heavy* by weight.** `[0]` is always Counterparty
   Risk at 2.5 × rate (0.475 here), and Slow Confirmation weighs 0.05 wherever the
   baseline carries it. The lag is expressed by the factor's presence, exactly as on
   the TRD044567 specimen.

**Known tension, not a contradiction:** story 03 scores 0.72 (High) behind low-risk
factors. Its probability is authored against the heuristic — no baseline trade pairs
a high probability with a clean counterparty — while its factors follow its facts
and its lane.

**Both shape details resolved (2026-09-10):**
- **`[0]` is Counterparty Risk on every packet row — settled by counts.** P9 counts
  Counterparty Risk on exactly 50,000 elements. Subtracting P5's per-position counts
  shows which factors ever lead on the 1,843 rows where Counterparty Risk sits
  second: Extended Settlement (892), High Volatility (342) and Month-End Pressure
  (609), which sum to exactly 1,843. **Large Notional, Low Base Risk, Normal
  Operations and Slow Confirmation never appear first.** The packet uses only those
  four, so no packet row can be one the baseline would order differently. (The P9
  run predated its per-counterparty branch, and the count argument made that branch
  unnecessary.)
- **Pair co-occurrence is asserted, not assumed.** `verification-summary.sql` check 12 checks each of
  the distinct authored `[1]` + `[2]` pairs against the baseline and prints FAIL for any
  pair the baseline never produces. A FAIL stops the run, and that pair is changed.

---

## 5. The three seeded stories

### Story 1 — HERO · held for review (seq `01`)

Per `hero-trade-spec.md` §1.

| Column | Value |
|---|---|
| `INSTRUMENT_ID` | `INS0147` — SAP GY / SAP SE / `equity` / EUR / DE0007164600 / Clearstream (CBF) |
| `COUNTERPARTY_ID` | `CP0023` — Diamond Trust / broker / APAC / `high` / 19.89% |
| `DIRECTION` / `QUANTITY` | `BUY` / `210000` shares |
| `NOTIONAL` / `CURRENCY` | `18700500` / `EUR` |
| `BROKER_CONFIRMATION_LAG_HRS` | `1.15` |
| `TRADER_ID` / `DESK` | `TR010` / `EQ_FLOW` |
| `IS_MATCHED` / `MATCHED_AT` | `TRUE` / trade date **18:12** |
| `FAIL_PROBABILITY` / `RISK_TIER` | `0.83` / `Critical` → **case** |
| `SCORED_AT` | call time |
| `TOP_RISK_FACTORS` | Counterparty Risk 0.49725 · Large Notional 0.02 · Large Notional 0.05 |

**Why it holds rather than releases:** the timing fits (1.15h lag against ~3h
remaining), but the counterparty is high-tier at 19.89% against the 9.20% book
average and the notional is large for the desk. Two concerning facts compound.
Measured on 2026-09-02 at **0.62** → Pending Analyst.

### Story 2 — ESCALATION · lag exceeds window (seq `02`)

The TRD044567 shape, authored rather than adopted.

| Column | Value |
|---|---|
| `INSTRUMENT_ID` | `INS0153` — BATS LN / British American Tobacco PLC / `equity` / GBP / CREST |
| `COUNTERPARTY_ID` | `CP0027` — Horizon Securities / bank / APAC / `high` / 19.00% |
| `DIRECTION` / `QUANTITY` | `BUY` / `640000` shares |
| `NOTIONAL` / `CURRENCY` | `19584000` / `GBP` (640,000 × 30.60) |
| `BROKER_CONFIRMATION_LAG_HRS` | **`26.07`** |
| `TRADER_ID` / `DESK` | `TR010` / `EQ_FLOW` |
| `IS_MATCHED` / `MATCHED_AT` | `TRUE` / trade date **18:37** |
| `FAIL_PROBABILITY` / `RISK_TIER` | `0.81` / `Critical` → **case** |
| `SCORED_AT` | call time |
| `TOP_RISK_FACTORS` | Counterparty Risk 0.475 · Slow Confirmation 0.05 · Large Notional 0.05 |

**Why it escalates:** 26.07h of confirmation lag against ~2.5h remaining. Canon
says lag at or near the remaining hours goes to a human at confidence 0.5 or
lower. A funding gap on an equity BUY is coherent: our cash is not in place to pay.

### Story 3 — STRAIGHT-THROUGH · clean facts (seq `03`)

| Column | Value |
|---|---|
| `INSTRUMENT_ID` | `INS0143` — IFX GY / Infineon Technologies AG / `equity` / EUR / Clearstream (CBF) |
| `COUNTERPARTY_ID` | `CP0037` — Rosewood Trust / bank / EMEA / `low` / **2.15%**, the book minimum |
| `DIRECTION` / `QUANTITY` | `SELL` / `18400` shares |
| `NOTIONAL` / `CURRENCY` | `634800` / `EUR` (18,400 × 34.50) |
| `BROKER_CONFIRMATION_LAG_HRS` | `0.75` |
| `TRADER_ID` / `DESK` | `TR010` / `EQ_FLOW` |
| `IS_MATCHED` / `MATCHED_AT` | `TRUE` / trade date **18:05** |
| `FAIL_PROBABILITY` / `RISK_TIER` | **`0.72` / `High`** → **case** (ruled: stays High) |
| `SCORED_AT` | call time |
| `TOP_RISK_FACTORS` | Counterparty Risk 0.05375 · Low Base Risk 0.02 · Normal Operations 0.01 |

**Why it releases:** every fact is favourable, and favourable facts are reassurance
— 0.75h lag against ~9h, a 2.15% counterparty, a small notional, and "Correct &
resubmit". Canon expects 0.85 or higher → released straight through.

---

## 6. The twelve background trades (seq `04`–`15`)

Volume without agent runs. **All below the High floor (p < 0.5003), so none opens a
case.** Every id was read live.

| seq | instrument | asset / ccy | desk | dir | quantity | notional | lag h | cpty | p | tier | matched |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 04 | INS0003 HSBA LN | equity GBP | EQ_FLOW | SELL | 42,000 sh | 287,700 | 1.40 | CP0012 Summit Finance | 0.18 | Low | 18:48 |
| 05 | INS0158 KFW 3.062 08/31 | bond EUR | FI_TRADING | BUY | 5,000,000 face | 5,118,000 | 0.50 | CP0010 Falcon Capital | 0.12 | Low | 18:21 |
| 06 | INS0160 AUDJPY 1M FWD | fx_forward AUD | FX_DESK | SELL | — | 22,400,000 | 3.20 | CP0002 Atlas Securities | 0.24 | Low | 18:56 |
| 07 | INS0004 SPY US | etf USD | ETF_MM | BUY | 12,500 sh | 6,912,500 | 0.90 | CP0015 Sapphire Bank | 0.15 | Low | 18:09 |
| 08 | INS0150 PFE US | equity USD | EQ_FLOW | BUY | 55,000 sh | 1,617,000 | 2.10 | CP0033 Neptune Finance | 0.31 | Medium | 18:33 |
| 09 | INS0162 OAT 4.41 06/38 | bond EUR | FI_TRADING | SELL | 8,000,000 face | 8,264,000 | 0.75 | CP0016 Titan Custody | 0.21 | Low | 18:17 |
| 10 | INS0164 GBPJPY 1M FWD | fx_forward GBP | FX_DESK | BUY | — | 31,900,000 | 4.00 | CP0022 Citadel Prime | 0.28 | Medium | 18:44 |
| 11 | INS0167 MSFT US | equity USD | EQ_FLOW | BUY | 9,800 sh | 4,067,000 | 1.05 | CP0028 Ivory Tower | 0.19 | Low | 18:02 |
| 12 | INS0170 TOYOTA 4.505 01/27 | bond JPY | CREDIT | BUY | 900,000,000 face | 918,000,000 | 2.60 | CP0019 Silver Creek | 0.33 | Medium | 18:29 |
| 13 | INS0155 VOW3 GY | equity EUR | EQ_FLOW | SELL | 21,300 sh | 2,151,300 | 1.90 | CP0041 Vertex Holdings | 0.45 | Medium | 18:51 |
| 14 | INS0152 PWLB 3.855 01/27 | bond GBP | FI_TRADING | BUY | 4,200,000 face | 4,271,400 | 0.60 | CP0026 Gold Standard | 0.10 | Low | 18:14 |
| 15 | INS0159 6758 JT | equity JPY | EQ_FLOW | BUY | 31,000 sh | 434,000,000 | 1.30 | CP0046 Alpine Partners | 0.26 | Medium | 18:40 |

- **Factors** (§4): `[0]` Counterparty Risk at 2.5 × the counterparty's rate · `[1]` Low
  Base Risk 0.02 · `[2]` Normal Operations 0.01 — except seq `10` and `12` (the largest
  nominal notionals), which carry **Large Notional 0.02 + Large Notional 0.05**, the pair
  measured on 1,402 baseline rows.
- **FX forwards carry `QUANTITY = NOTIONAL`**, the baseline convention read from
  `TRD000009` (an `INS0160` forward). `SO_quantityDisplay` never renders it.
- **Traders** — `TR010` on the stories and five EQ_FLOW background rows; `TR002`,
  `TR003`, `TR005`, `TR012`, `TR015` and `TR019` elsewhere. All present in live
  trades.
- **Prices are authored, not read** — there is no price column. They sit at
  plausible levels for each line.

---

## 7. What the packet deliberately does NOT create

- **No `SETTLEMENT_HISTORY` rows.** Packet trades are open. With a packet loaded,
  `TRADES` = 50,015 and `SETTLEMENT_HISTORY` = 50,000, and that asymmetry is correct.
- **No cases, comments or audit rows.** Those are created by the Part B intake for
  the three High/Critical stories, tagged with the run name in `sessionID`, and
  removed by the console's Appian-side delete.
- **No Snowflake writes from Appian** other than the two procedure calls.

---

## 8. Authoring rules

1. Instrument type and fail reason cohere — checked per story.
2. Quantity language follows asset class — shares / face / notional only.
3. Every narrated beat points at a trade satisfying (1) and (2).
4. **Every timestamp is relative to now, on the UTC clock:** `TRADE_DATE`, `EXPECTED_SETTLEMENT_DATE`,
   `MATCHED_AT` (trade-date evening), `SCORED_AT` (call time, UTC), and the case's
   `cutoffTs`.
5. Every instrument, counterparty and trader id is read back live before it is
   written down.
6. **Background trades stay below the measured High floor (p < 0.5003)**, and every
   probability→tier pair falls inside the measured band.
7. **A Snowflake-written "now" is UTC wall clock** — Appian reads NTZ as UTC (§2).
8. **Factors never contradict the story's fail reason or lane**, and every factor pair
   is one the baseline produces (§4 coherence rule).
