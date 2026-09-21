# Hero Trade Spec — Settlement Operations demo

The contract for the Phase 5 simulation packet's hero trade, and for the two
mockups that depict it. Written 2026-09-02; **revised 2026-09-10** to Scott's Phase 5
rulings (id scheme, `MATCHED_AT`, `SCORED_AT`, case-creation criterion). The
full fifteen-trade packet is `packet-spec.md`.

**We author the hero; we do not adopt one.** The hero is a packet trade inserted
at demo time into a reserved id range, never a baseline row. No baseline trade,
prediction, instrument attribute or settlement record is modified to make the
story work. This is what lets the mockups keep their banked figures and their
EQ_FLOW persona chrome: the data is authored to match the mockup, rather than the
mockup being rewritten to match whatever the data happened to contain.

This file is consumed by the Phase 5 packet builder and is the reference for any
mockup edit. If a number changes here, it changes in both mockups too.

---

## 1. The authored hero trade

The story: a large SAP buy, predicted to fail on a deliver-side shortfall,
against a high-risk APAC counterparty, with a broker confirmation that fits
inside the window — the agent should propose a borrow but hold it for a human
because of position size.

### TRADES row

| Column | Value | Why |
|---|---|---|
| `TRADE_ID` | *(reserved scheme — see §2)* | Session-safe, never collides with baseline |
| `TRADE_DATE` | `DATEADD(day, -1, SYSDATE()::DATE)` | The day before the UTC run date; makes settlement T+1 (`packet-spec.md` §2) |
| `EXPECTED_SETTLEMENT_DATE` | `SYSDATE()::DATE` | Settles on the UTC run date — the reason there is a cutoff at all |
| `INSTRUMENT_ID` | **`INS0147`** | Pinned to SAP GY / SAP SE / DE0007164600 / Clearstream (CBF). Genuine `equity`, `EUR` — so "shares", a German ISIN and a German CSD all cohere |
| `COUNTERPARTY_ID` | **`CP0023`** | Diamond Trust — broker, APAC, `high` tier, 19.89% historical fail rate. The mockup's named counterparty, used with its real profile |
| `DIRECTION` | `BUY` | Matches the mockup's "B" badge |
| `QUANTITY` | **`210000`** | The mockup's "210,000 shares" |
| `NOTIONAL` | **`18700500`** | 210,000 × 89.05 EUR/share — a sane SAP-scale price, rendering as "18.7M" |
| `CURRENCY` | **`EUR`** | See the currency note below |
| `BROKER_CONFIRMATION_LAG_HRS` | **`1.15`** | 1h 09m, per the mockup. Must stay comfortably below the hours-to-cutoff (§3) or the agent escalates on timing |
| `TRADER_ID` | `TR010` | An existing EQ_FLOW trader id (format `TR` + 3 digits) |
| `DESK` | **`EQ_FLOW`** | Keeps `alex.analyst`'s existing security clause and both mockups' persona chrome intact — no desk re-point needed |
| `IS_MATCHED` | `TRUE` | The mockup's "Matched Yes" |
| `MATCHED_AT` | trade date at `18:12` (`TIMESTAMP_NTZ`) | The mockup's "31 Aug 18:12". Trade-date evening relative to now — **ruled 2026-09-10**, the hero-insert precedent (§3a) |

### TRADE_PREDICTIONS row

| Column | Value |
|---|---|
| `TRADE_ID` | same reserved id |
| `FAIL_PROBABILITY` | **`0.83`** — the mockup's 83% |
| `RISK_TIER` | **`Critical`** — note the capitalisation; `TRADE_PREDICTIONS.RISK_TIER` is `Critical/High/Medium/Low` while `COUNTERPARTIES.RISK_TIER` is lowercase `high/medium/low`. They are different vocabularies in the same schema |
| `SCORED_AT` | **call time** — scoring on arrival, **ruled 2026-09-10**. Written as `SYSDATE()::TIMESTAMP_NTZ` — the column is `TIMESTAMP_NTZ` (P9), and its `DEFAULT CURRENT_TIMESTAMP()` would stamp the Pacific session clock (`packet-spec.md` §2). *The 05:00 overnight-batch stamp is retired.* |
| `TOP_RISK_FACTORS` | **Baseline-shaped, ruled 2026-09-10** — Counterparty Risk 0.49725 (2.5 × 19.89%) · Large Notional 0.02 · Large Notional 0.05. Counterparty and size are the two facts that hold the hero. There is **no confirmation factor**: the 1.15h lag fits the window, so Slow Confirmation would contradict the lane (`packet-spec.md` §4 coherence rule). *The NULL precedent of `hero-trade-insert.sql` is retired.* |

Predicted fail reason is **`insufficient_securities`**. `TRADE_PREDICTIONS` has no
fail-reason column. It does have `TOP_RISK_FACTORS` (measured 2026-09-10), but that
holds risk *drivers* — Counterparty Risk, Extended Settlement, High Volatility and so
on — not fail reasons. The reason is
**Appian-authored** (ruled 2026-09-10). The intake passes it into
`SO_createTriageCase`'s `failReason` parameter, which writes it to
`SO Settlement Case.failReason`. A deliver-side shortfall on an equity buy is
coherent — which is the point of pinning the hero to an equity instrument.

**No `SETTLEMENT_HISTORY` row.** The hero is an open, unsettled trade. Adding one
would assert an outcome that has not happened, and would break the 1:1 invariant
in the wrong direction. Expect `TRADES` = 50,001 and `SETTLEMENT_HISTORY` = 50,000
while a hero is loaded; that asymmetry is correct.

### Currency note

The mockups currently label this trade **18.7M USD** while showing the CSDR
penalty in **EUR** — internally inconsistent. The hero is authored in **EUR**,
which resolves it: SAP GY is a German EUR listing settling at Clearstream, so EUR
is the only currency that makes ticker, ISIN, CSD and penalty agree. The banked
figure 18.7M is preserved; only the currency label changes, in both mockups.

---

## 2. Reserved id scheme and reset predicate

> **REVISED 2026-09-10 (ruled) — `packet-spec.md` §1 is now authoritative.** The code
> is the **run name with dashes removed** (1–13 letters, digits or dashes; e.g.
> `1012-ACME` → `TRD91012ACME01`), and reset deletes the **exact fifteen-id list**,
> never `LIKE`. The three-character code and the `LIKE` predicates below are kept
> as history: a prefix predicate is unsafe once codes vary in length, because
> resetting `DEMO1` would also delete `DEMO12`'s rows. The `NOT LIKE 'TRD9%'`
> baseline exclusion for `Verify Ready` is unaffected.

    TRD9 <session> <sequence>
         3 chars    2 digits

- `TRD9` — reserved prefix. Every baseline trade id is `TRD0…` (the baseline runs
  to `TRD050000`), so nothing beginning `TRD9` can ever collide with baseline data.
- `<session>` — 3 uppercase alphanumerics identifying the SC session. Concurrent
  sessions on the shared partner account get different codes and therefore
  disjoint id space.
- `<sequence>` — `01`–`99`, the packet slot. The hero is `01`; the plan's other
  two seeded high-risk trades are `02` and `03`.

Example, session `NY1`: `TRD9NY101`. Nine characters, well inside `VARCHAR(20)`.

**Reset predicates.** Per-session (what `Reset Demo` runs):

```sql
DELETE FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%';
DELETE FROM TRADES            WHERE TRADE_ID LIKE 'TRD9' || $session_code || '%';
```

Whole reserved range (break-glass only — destroys every session's packet):

```sql
DELETE FROM TRADE_PREDICTIONS WHERE TRADE_ID LIKE 'TRD9%';
DELETE FROM TRADES            WHERE TRADE_ID LIKE 'TRD9%';
```

Predictions delete first: it is the child of the 1:1 relationship.

**Consequence for `Verify Ready`.** Baseline counts must exclude the reserved
range or a loaded packet reads as corruption:

```sql
SELECT COUNT(*) FROM TRADES WHERE TRADE_ID NOT LIKE 'TRD9%';  -- expect 50000
```

---

## 3. What is parameterized at insert time, and why

`EXPECTED_SETTLEMENT_DATE` is a `DATE`. It cannot carry intraday urgency, so it
cannot by itself produce the mockup's "3h 05m to cutoff". The urgency is composed
from two places:

**a. On the trade (Snowflake), set at insert:**
- `TRADE_DATE = run date - 1` and `EXPECTED_SETTLEMENT_DATE = run date`, where the run date is the **UTC** date (`SYSDATE()::DATE`; the Snowsight session is Pacific, measured by P9) —
  makes the trade settle *today*, so a cutoff today is meaningful.
- `BROKER_CONFIRMATION_LAG_HRS = 1.15` — fixed. This is the numerator of the
  agent's timing arithmetic.
- **`MATCHED_AT` MUST BE AUTHORED RELATIVE TO NOW, not to a fixed clock time**, and
  this is what unlocks the matched timestamp on screen. **Ruled 2026-09-10: the
  evening of the trade date** — `DATEADD(minute, m, DATEADD(hour, 18,
  TO_TIMESTAMP_NTZ(trade date)))`, minutes varied per trade. That is the hero-insert
  precedent, and the same 18:00–20:59 window the baseline was generated in. **The
  earlier `cutoff - 4 hours` formula is RETIRED.** Appian reads this `TIMESTAMP_NTZ`
  as UTC (measured 2026-09-10), so 18:12 renders as 14:12 for a New York viewer.
  **Case Detail withholds the matched STAMP on baseline trades
  and shows only the state**, because baseline `MATCHED_AT` is stale by
  construction and rendering "30 Dec 13:58" beside "Settles Wed 9 Sep" asserts a
  contradiction (ruled 2026-09-09). Packet trades are the first rows for which an
  honest stamp exists; the display gate opens when they do.

**b. On the case (Appian), set at case creation:**
- `SO Settlement Case.cutoffTs` is the *only* field carrying the intraday
  deadline. The packet builder must set it explicitly:

      cutoffTs = now() + 3 hours 5 minutes

  `SO_caseContext` derives the agent-visible window from it directly —
  `floor((cutoffTs - now()) * 24)` — so the agent reads "3 hours from now"
  without any Snowflake-side timestamp.

**The timing invariant that decides the lane:** `BROKER_CONFIRMATION_LAG_HRS`
(1.15h) must remain **comfortably below** the hours to cutoff (≈3h). Confirmation
completing ~1h 56m before cutoff is what keeps the hero in the held-for-review
lane. Narrow that gap and the agent escalates on timing, exactly as the
TRD044567 specimen does at 26.07h against a 23h window.

> **Phase 5 prerequisite — ANSWERED 2026-09-10 (measured):** `SO_createTriageCase`
> **accepts** `cutoffTs` as an optional Date and Time parameter (default `now() + 1`)
> and writes it verbatim. No override is needed; the intake passes it.

---

## 4. Intake topology

Intake is **one process model**, and the trigger is the only swappable part:

    [ trigger ] -> SO Ingest Packet Trade -> create case -> SO Triage Agent -> lanes

- **Today:** an Appian button (a site action on the admin/reset page) starts the
  model.
- **Later:** an event consumer starts the same model. Nothing downstream changes —
  same node chain, same case creation, same triage.

Keeping intake in one model is what makes the Kafka path a trigger swap rather
than a topology change. Do not build a second ingest path for the button.

**Case-creation criterion — ruled 2026-09-10: `RISK_TIER` is `High` or `Critical`.**
It is one tier check in this model, aligned with the semantic view's verified
*notional at risk (High/Critical)* query (`packet-spec.md` §3).

---

## 5. Phase 5 implementation note

Packet load and reset run as Snowflake stored procedures:

- `SIMULATE_FEED(RUN_NAME VARCHAR)` — inserts the fifteen-trade packet
  (`packet-spec.md`), with ids minted per the revised §2.
- `RESET_SESSION(RUN_NAME VARCHAR)` — deletes that run's exact fifteen ids.

Both are called from Appian over the **Snowflake SQL REST API** using the
existing PAT (`Appian_NY_MCP`, restricted to `FINSERVADMIN`). No new credential
and no new connected system: the endpoint is the same host already recorded in
`deploy-notes.md`.

`snowflake/hero-trade-insert.sql` remains the proven pattern the procedures
mirror for the TRADES row and the four scalar prediction columns. Its NULL
`TOP_RISK_FACTORS` is retired: packet predictions are baseline-shaped. **`snowflake/hero-trade-delete.sql` is SUPERSEDED (2026-09-10):** its
`LIKE` predicate is prefix-unsafe under the run-name scheme. Use
`RESET_SESSION`.

---

## 6. Future Kafka path

Stated now so nothing built today has to be unpicked:

- **The packet trades are the events.** The field list in §1 *is* the message
  schema — a produced trade event carries exactly those fields. No translation
  layer appears later.
- **Credential:** a single shared broker service credential in one Appian
  connected system. Not per-SC, not per-session; sessions stay separated by the
  §2 id scheme, not by identity.
- **Trigger:** the event consumer replaces the button per §4. The process model,
  case creation and triage are untouched.
- **Prediction enrichment moves.** Today the packet inserts a
  `TRADE_PREDICTIONS` row alongside the trade. When Phase 8 lands, scoring
  becomes on-demand — the consumer calls the model and the prediction is
  produced per event rather than pre-inserted.
- **The button path stays.** It remains canonical until the consumer is proven,
  and remains the permanent fallback afterwards. A demo that cannot fall back to
  a button is a demo that cannot be given when the broker is unreachable.

---

## 7. Authoring rules this file enforces

1. **Instrument type and fail reason must cohere.** No `insufficient_securities`
   story on an FX forward; no borrow remediation on something that cannot be
   borrowed. The hero is an equity because the story is a deliver-side shortfall.
2. **Quantity display language follows asset class** — "shares" for equities and
   ETFs, "face" for bonds, notional-only for FX forwards.
3. **Every narrated beat points at a trade that satisfies (1) and (2).** Checked
   at authoring time, here, not discovered on stage.
4. **Every timestamp on a packet trade is authored RELATIVE TO NOW**, never as a
   fixed clock time — `TRADE_DATE`, `EXPECTED_SETTLEMENT_DATE`, `MATCHED_AT`
   (trade-date evening), `SCORED_AT` (call time, UTC wall clock), and the case's
   `cutoffTs`. This is what lets the packet skip the P4-VERIFY re-date
   ritual entirely, and it is also the condition on which a screen may show a
   stamp at all: a screen shows a timestamp when an honest one exists, and
   authoring it relative to now is what makes it honest.
