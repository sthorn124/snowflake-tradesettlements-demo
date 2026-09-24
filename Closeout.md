# Closeout — 2026-09-24 — mockup authority ruled; Matched-time gate opened; fails-card geometry

**Scope.** Two documents ruled (mockup authority, presenter placement), one interface changed: `SO_caseDetail` **v8 → v9**, carrying both Task 3 and Task 5. No process model, no security or identity change, nothing Snowflake-side, `SO_supervisorCommand` untouched.

**Identity.** Dev MCP as `scott.thorn` (`SO Supervisors`, full scope). Persona reads via sail as `alex.analyst` (`~/.sail-alex.analyst`) and `sam.supervisor` (`~/.sail-sam.supervisor`). **`test.presenter` now has a live session** — new since the last close-out.

**Preflight.** Plan gate passed. Design surface present (camelCase, 11 record types). **Version drift re-reported, already logged:** Dev MCP and sail both **26.6.95** against `toolchain.md`'s 26.6.90 pin — App Market `UP_TO_DATE`, so the pin is what is stale (TODO:59, TODO:199). Skill copies **identical**. Per-session ritual run: all three P4-VERIFY CSVs regenerated and applied to SO Settlement Case, SO Case Comment and SO Settlement Case Event History.

---

## (f) STOPPED ON, AND READ THIS FIRST — the brief's premise did not hold

**The environment was NOT at clean baseline.** The console, read as the design account before any work:

```
Ready  ·  data 50,000/50,000  ·  9/9 connections  ·  agent OK
Loaded now:  15 demo trades  ·  3 cases
Status:  Demo loaded 24 Sep 13:33  ·  15 trades  ·  3 cases
Details: Demo trades 15 · Demo cases 3 · Built-in test cases 17
         Case comments 15 · Audit rows 23 · AI agent last run 24 Sep 13:34
```

A fully triaged packet from **13:33**, sixteen minutes before the session opened — almost certainly the GATE D run, left loaded rather than reset. Two decisions followed, both deliberate:

1. **No Load was run.** One was already there, and it is exactly the state Tasks 3 and 5 needed — `MATCHED_AT` authored on the current clock.
2. **No Reset was run at the end, contrary to the brief's "reset after".** That instruction assumed the session created the packet. It did not. Reset is destructive, and leaving the environment as it was found is the correct end state. **The packet is still loaded now.** To clear it: open the Demo Admin site and press **Reset the demo**.

Nothing else was stopped on. Two further premise corrections are recorded under (b) and (e) — both were wrong in ways that would have caused a silent regression if followed literally.

## (a) The rule, and the header

**Written into `CLAUDE.md`'s Working style, directly beneath "Mockup-first":**

> **A MOCKUP IS THE STRUCTURAL AUTHORITY ONLY FOR THE CHANGE BEING BUILT FROM IT. ONCE THAT SCREEN IS BUILT, GATED AND VERIFIED, AUTHORITY TRANSFERS TO THE DEPLOYED SCREEN AND THE MOCKUP BECOMES A HISTORICAL DESIGN ARTIFACT — ruled 2026-09-24.**
> - **While the build is in flight** the mockup governs layout and information hierarchy, and a departure from it is a delta to be logged. That is the whole of its authority.
> - **After the gate**, the deployed object is the authority — it carries every ruling the mockup predates, and it is what the next session reads. **A stale mockup is never "restored toward".**
> - **AND IT IS NOT REGENERATED TO MATCH THE BUILD EITHER.** Redrawing a file nobody renders spends a session re-asserting a claim to authority the file no longer has, and it goes stale again at the next ruling. **It gets a superseded header instead** — one HTML comment at the top naming the object that replaced it and the date — so a reader who opens it knows within one line that it is history, not intent.
> - **THIS SUPERSEDES §7's "fix the mockup in the next mockup pass"**, which the bullet below quotes: the drift §7 warns about is real, and a superseded header answers it more cheaply and more durably than regeneration. Where the operating core and this section disagree on mockup handling, this section wins (skill precedence, top of file).
> - **Consequence for TODO:** a parked "update mockup X to the build" item is closed by this ruling plus the header, not by a mockup pass.

**The §7 clause was reconciled in the same edit rather than left to contradict the new rule** — the adjacent bullet quotes the operating core's "fix the mockup in the next mockup pass" verbatim, so without the explicit supersession the file would have argued with itself on the next read.

**Header applied to `mockups/supervisor_command.html`** (first lines):

```html
<!--
  SUPERSEDED 2026-09-24 — the built SO_supervisorCommand is the authority for this screen.

  This file was the structural authority while the supervisor screen was being built.
  That screen is built, gated (gate C) and verified, so authority transferred to the
  deployed object; this file is now a historical design artifact and is NOT maintained.

  Known divergences, recorded rather than fixed (…):
    - Layout. The build was reorganised by ruling into wide-left / rail-right. This DOM
      still puts the trend chart beside the runway and the reason/queue cards inside the
      left column. Do not restore that shape from here.
    - Figures the build could not carry: the runway's "on track" band, the day-over-day
      comparisons.

  Read the deployed SO_supervisorCommand for what this screen IS. Read this only for what
  it was once meant to be.
-->
```

`mockups/analyst_watchlist.html` left alone, as instructed. **`mockups/case_detail.html` is now the stalest file in the folder** and is the obvious next candidate — TODO item added with a trigger, not applied, because the brief named one file.

## (b) Task 2 — the spec quoted, and why nothing was applied

**The item's full logged spec (TODO:100):**

> **Overnight copy (added 2026-09-10):** the watchlist mockup header "scored overnight batch 05:00" and the case-detail mockup's "Overnight scoring flagged…" become on-arrival wording, because packet trades score on arrival. **The built watchlist's empty-state message stays as is (ruled)** — it is still true for the overnight-scored baseline.

**It does not prescribe exact wording** — "become on-arrival wording" names the strings to replace and not the replacements. So under the brief's own test: propose, invent nothing.

**But the more useful finding is that there is no built screen to apply it to, and the item is substantially already done:**

- The built watchlist **already carries on-arrival wording** — `.work/SO_analystWatchlist.sail:753`, tooltip: *"Scored in Snowflake on arrival, not overnight — the packet is scored as it lands."*
- The watchlist mockup's `"scored overnight batch 05:00"` **no longer exists**; the v5 rewrite removed it.
- `SO_caseDetail.sail` contains **no** overnight copy at all.
- The single surviving instance in the repo is `mockups/case_detail.html:277` — *"Overnight scoring flagged TRD031208 at 83% fail probability — case opened from the prediction feed."* — **a mockup line, now governed by (a)'s ruling.**

**So nothing was applied and nothing is proposed for a built screen.** If Scott wants the mockup line touched at all, the ruling says it gets the superseded header rather than a copy edit. Item closed with both halves recorded.

## (c) The Matched-time gate

**Ruled intent, quoted verbatim from `CLAUDE.md`:**

> **MATCHED IS STATE-ONLY ON BASELINE DATA, AND THE STAMP IS CONDITIONAL ON THE PACKET — ruled 2026-09-09.** Case Detail renders "Matched Yes / No" and withholds `matchedAt`. `SO Trade.matchedAt` is Snowflake baseline, it is never mutated by a demo run, and it is therefore **stale by construction**: beside a cutoff-derived settlement date it renders a stamp from another year and asserts a contradiction the screen cannot resolve. … **The gate opens in Phase 5**, where packet trades author `MATCHED_AT` on the **evening of their relative-to-now trade date** …; the display condition is **"a stamp exists that was authored on this clock", not "the field is populated"**.

**Why the condition had to be recency, measured this session.** A probe over all twenty cases returned, at `NOW=2026-09-24 13:53`:

| population | `isMatched` | `matchedAt` |
|---|---|---|
| 17 fixture cases (baseline trades) | **Y on every row** | `2023-01-10` … `2025-05-02` |
| 3 packet cases (`TRD9DEMO01/02/03`) | **Y on every row** | `2026-09-23 14:12 / 14:37 / 14:05` |

**Presence discriminates nothing** — every row is matched. Recency is the only available signal, and the margin is ~16 months to the nearest baseline stamp against ~1 day to the packet ones, so a **7-day window** cannot be tripped by baseline data and cannot miss a packet left loaded for several days.

```
local!stampOnThisClock: and(
  not(a!isNullOrEmpty(local!matchedAt)),
  todate(local!matchedAt) >= today() - 7,
  todate(local!matchedAt) <= today()
),
```

**THE STAMP CARRIES ITS DAY WHENEVER IT IS NOT TODAY'S, and that is the substance rather than a detail.** A packet trade matches on its **trade** date and settles the **next** one, so the honest stamp is usually yesterday's. Rendering a bare `"· 14:12"` beside a cutoff of today would have asserted it matched this morning — **a fresh instance of the exact contradiction the 2026-09-09 ruling existed to remove.** So: `hh:mm` when the stamp is today, `d mmm hh:mm` otherwise. That mask is already in service elsewhere in this build, so it is known to render here rather than assumed.

Null-guarded per the promoted timestamp rule: `a!isNullOrEmpty` precedes every `todate` and `text` call on the field.

**Both paths verified as `alex.analyst` via sail**, on the same screen and the same field:

```
TRD9DEMO01 (packet)          TRD026800 (fixture, baseline trade)
  Trade date  Wed 23 Sep       Trade date  Wed 23 Sep
  Settles     Thu 24 Sep T+1   Settles     Thu 24 Sep T+1
  Matched     Yes · 23 Sep 14:12   Matched     Yes
```

The packet row's three lines are mutually coherent — matched on trade date, settles the next. The fixture row withholds the stamp, as the original ruling requires.

## (d) Task 4 — NOT satisfied; the move was made

`GETTING_STARTED.md` still carried ~120 words of build-specific prose naming three project groups, and **its own footnote conceded the point**: *"The durable home for it is the project's own `CLAUDE.md`."*

**One detail lived only there**, so it was carried into `CLAUDE.md` **before** deletion — the three-presenter-states bullet, whose middle state is the dangerous one:

> **Demo Admins + `SO Analysts`:** the console renders and looks healthy, but intake reads a **desk-scoped** set of predictions and silently creates cases for that one desk only — no error, a short watchlist, and a demo that quietly loses two of its three stories. **The preflight does not catch this**, because `SO Analysts` nests under `SO Users` and so passes any viewer check; only the `SO Supervisors` test catches it, which is why the preflight names that group and not `SO Users`.

`GETTING_STARTED.md` now carries one parameterized paragraph with **zero project nouns**, pointing at the Build parameters block and the operator-site section.

## (e) The fails card, re-rendered

**The brief's stated basis for shortening the label was false, and following it literally would have shipped a regression.** It said the card's summary line "continues to carry the full framing". It did not — the line read only `"5 most recent · 4 of 5 on insufficient securities — consistent with the predicted reason on this case"`, entirely about the reason mix. Replacing the self-explanatory `"outside your desk view"` with the terse `"Other desk"` on that basis would have quietly undone last session's display-honesty fix, whose whole point is that **nothing distinguishes absent from invisible unless the screen says so**. The framing was moved into the summary line rather than deleted.

**Widths — and a correction to `CLAUDE.md`.** docs-search settled the mechanism, and it is the opposite of what the project file claimed. `AUTO` on a grid column is *"determined by the length of the longest unbroken value in that column"* — it sizes to its own content and does **not** absorb slack; the docs also say to **avoid mixing `AUTO` with weighted widths**. `NARROW` has **no minimum width** and a fixed column is only ever "at least as wide as the longest word" — and in the Instrument column that word was the ten-character **header**. That is the whole fault. All five columns went relative, budgeted from the longest unbroken token each must seat:

| column | width | longest token |
|---|---|---|
| Date | `2X` | `Sat` (3) |
| Trade | `2X` | `TRD026800` (9) |
| Instrument | `3X` | header `Instrument` (10) |
| Reason | `4X` | `Insufficient` (12) |
| Value | `2X` | `8.3M` (4) |

`CLAUDE.md`'s grid bullet, which asserted *"one column — the widest, normally Instrument — takes `AUTO` and absorbs the remainder"*, is **corrected in place** with the documented behaviour and the real `a!gridColumn` width vocabulary (which excludes `EXTRA_NARROW`, `WIDE_PLUS`, `EXTRA_WIDE` — those are `a!columnLayout`'s).

**Rendered as `alex.analyst`, hero case:**

```
Date, Trade, Instrument, Reason, Value
Sun 6 Jul  | TRD040796 | Other desk | Operational error        | —
Thu 19 Jun | TRD022509 | Other desk | Insufficient securities  | —
(+3 more)

5 most recent · 4 of 5 on insufficient securities — consistent with the predicted reason on this case
5 of 5 are booked on other desks — their dates and reasons are shown, their instrument and value are not yours to read.
```

**Rendered as `alex.analyst`, fixture case `TRD026800` — a mixed case, which is the better control:**

```
Tue 15 Jul | TRD003842 | BAS GY     | Funding gap       | 28.6K EUR
Mon 7 Jul  | TRD021939 | Other desk | Operational error | —
4 of 5 are booked on other desks — …
```

It reads **4 of 5**, not 5 of 5 — the count is row-accurate rather than a blanket claim.

**Rendered as `sam.supervisor`, same case — the clause disappears:**

```
Tue 15 Jul | TRD003842 | BAS GY          | Funding gap       | 28.6K EUR
Mon 7 Jul  | TRD021939 | AAPL 4.35 12/39 | Operational error | 1.9M USD
5 most recent · 0 of 5 on insufficient securities — a different pattern from this case
```

Where alex sees `Other desk / —`, sam sees the real instrument and value, and the hidden-row sentence is suppressed by `showWhen: local!hidden > 0`. **The count is scope-derived, not asserted** — the same two-identity control that caught the fabricated zero last session, passing in both directions.

`Sun 6 Jul` is a weekend date: the documented synthetic-history artifact, deliberately not fixed.

---

## Verified / not verified

**Verified.** `updateInterface` accepted v9 (the authoritative object validator); readback **byte-identical** (88,290 chars both sides); `validateDesignObject` → `hasErrors: false`. Renders as two personas across three cases, quoted above. Throwaway `SO_zzMatchedProbe` deleted and **verified by absence (HTTP 404)**.

**Not verified.**
- **Geometry — one line per column at laptop width.** A session cannot measure pixels (CLAUDE.md §4); what is verified is the width **values**. **Browser check for Scott:** open any case detail at laptop width and confirm Date, Trade, Instrument, Reason and Value each render on one line, that the **Instrument header no longer wraps**, and that `Other desk` sits on one line.
- **The seven-day boundary itself.** Verified at ~1 day (packet, shows) and ~9 months (fixture, withheld). Nothing on the instance sits near the boundary, so the edge is reasoned, not measured.
- **The `local!hidden` = 0 branch on a packet case** — every packet case's counterparty history is out-of-desk for alex, so the suppression was proven on a fixture case as supervisor instead.

## Promotion candidates

**4 considered; 0 promoted to appian-supplemental, 1 corrected in CLAUDE.md, 2 staged, 1 declined.**

1. **CORRECTED IN PLACE (project file, not promoted):** `AUTO` on a grid column sizes to its own longest unbroken value and does not absorb slack; `NARROW` has no floor; a fixed column is sized by its longest word, header included. Not a supplemental entry — the supplemental already carries the `NARROW`/header half, and the `AUTO` half is documented behaviour that only *this project's* file contradicted. Fixed where the error was.
2. **STAGED (gate 1):** *when a field is populated on every row, presence cannot gate its display; the discriminator is recency, and it is safe only across a margin you have measured.* Trap: gating on non-null looks right and fires on everything. Working form: measure both populations first, then pick a window with slack at both ends, and state the measured margin in the comment. *Trigger: the next screen that must show a value only for freshly-authored rows.*
3. **STAGED, carried:** a `showWhen` hides output; only nesting the declaration prevents evaluation. *Trigger unchanged.*
4. **RE-STAGED with a note: the "does a scope-starved query throw or return empty?" candidate did NOT fire.** Its trigger was "an account holding no viewer right on a record type has a live sail session". `test.presenter` now has a live session but has **also been added to `SO Supervisors`**, so it holds viewer rights and is no longer the specimen. *Trigger restated: any account with a live sail session that holds no viewer right on a record type — which no current account does.*
5. **DECLINED:** the re-date script's CWD bug is generic scripting hygiene, not an Appian fact. Filed as TODO.

**Promotion checkpoint: current through this entry (2026-09-24, mockup authority / Matched gate).**

## TODO changes

**Closed 5:** TODO:99 Matched-time gate divergence (build moved, not the ruling); TODO:100 overnight + supervisor mockup, **both halves**; TODO:112 the supervisor-mockup trap; the `test.presenter` login item (session now live, both memberships confirmed); "the crash itself" (fixed in v12). Section header *"BLOCKING — … NOT fixed"* retitled to **RESOLVED**.

**Added 3:** the re-date script writes to CWD not `fixtures/` (one-line fix, next ritual session); `mockups/case_detail.html` as the next superseded-header candidate (Scott's go-ahead); the `SO Demo Admins` **group description** still reads as the Demo-Admins-only model (Designer, Scott — group admin is not available over the Dev MCP).

## BUILD_PLAN changes

Phase 5: entry added for the mockup-authority ruling, the Matched-time gate and the fails-card rebalance.
