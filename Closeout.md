# Closeout — 2026-09-24 — chip redesign, narration enforced downstream, agent instructions v2

**Scope.** `SO_askPanel` v5→**v6** (short labels, tooltips, LINK style, new `labels` input), `SO_caseDetail` v11→**v12** (chip labels), `SO_supervisorCommand` v9→**v10** (chip labels + the by-currency question), `SO_askSnowflake` v7→v8→**v9** (extraction rewritten), `snowflake/agent-instructions-v2.sql` authored **and run by Scott**, `CLAUDE.md` currency list corrected. Three throwaway read-only probes, all deleted and verified absent. Demo loaded and reset through the console path.

**Identity.** Dev MCP as `scott.thorn`. Persona reads via sail as `alex.analyst` and `sam.supervisor`. **30 live Cortex calls** this session.

---

## (a) Chips — the design, and the cause of the hover complaint

The docs carried both cause and cure in one sentence: *"If a button's label is too wide for its container, the text will truncate. **If the tooltip parameter is configured**, users can hover over the button (web) or long press (mobile) to see the full label."* ([Button Component 26.6](https://docs.appian.com/suite/help/26.6/Button_Component.html#usage-considerations)) **The tooltip was simply never set** — nothing was broken, a parameter was missing.

**Style chosen: `LINK`**, the lightest of the four documented options — *"transparent background **and** border that switches to a colored border when highlighted"*, against `OUTLINE`'s permanent border, `GHOST` and `SOLID`. With `size: "SMALL"` and `width: "MINIMIZE"` (*"width is determined by button label"*), and `loadingIndicator` intact and still accepted by the validator. The **Ask** button keeps `OUTLINE`, so the one real action still outranks the three suggestions.

**Uppercase is a SITE setting and I cannot reach it.** *"By default, all buttons… use uppercase capitalization for labels. You can configure this in a site object… If you deselect **Use uppercase capitalization for button labels**, you can control button label capitalization in each button component."* `updateSite` exposes no branding fields over the Dev MCP, so this is a Designer tick-box on `SO_SettlementOperations`. **The labels are written in sentence case deliberately** — the day that box is unticked they read correctly with no code change.

**The six labels, rendered live** (hero values for the case side):

| panel | chip label | full question (sent, and in the tooltip) |
|---|---|---|
| Supervisor | Highest fail-rate counterparties | Which counterparties have the highest settlement fail rates? |
| Supervisor | Fail rate by asset class | What is the settlement fail rate by asset class? |
| Supervisor | At-risk notional by currency | What is the notional at risk for High and Critical risk trades, by currency? |
| Case | Diamond Trust vs the book | How does Diamond Trust's settlement fail rate compare with the rest of the book? |
| Case | Common fail reasons: Equity | What are the most common fail reasons for Equity trades? |
| Case | This notional vs typical Equity | How does this trade's 18.7M EUR notional compare with typical Equity trades? |

**A constraint note:** Tasks 1.1 and 3.3 both require changing the **supervisor** chips, which live in `SO_supervisorCommand` — a file the constraint list omitted. Both tasks are impossible without it, so I treated that as an oversight and changed only the `rule!SO_askPanel(…)` call there.

## (b) The raw-response structure, and the extraction decision

Six captured runs (3 supervisor, 3 case) via a temporary statement swap on `SO_askSnowflake`, restored after. **The evidence overturned my Part 1c assumption.**

On the supervisor side narration sits in `thinking` elements, which my `WHERE type='text'` filter already excluded. **On the case side it arrives as `type:"text"` — which is why it reached the screen.** All three case runs were structurally identical:

```
0  text        "I'll look into Vanguard Prime's fail rate versus the re…"   ← NARRATION, type=text
1  tool_use    SettlementAnalyst
2  tool_result
3  tool_use    system_execute_sql
4  tool_result
5  text        "I need to use the logical column name counterparty_name"    ← NARRATION, type=text
6  tool_use    system_execute_sql
7  tool_result                                                              ← BOUNDARY
8  text        "Vanguard Prime fails at 24.37 percent, 240 of 985 trade…"   ← THE ANSWER
9  suggested_queries / table
```

**Across all six runs: every narration `text` element precedes the last `tool_result`; every answer `text` element follows it.** That is exactly the structural rule Task 2.3 specified, so the extraction changed to keep only text after that boundary.

**Duplication: not reproduced.** Part 1c saw a paragraph emitted twice; none of these six runs duplicated, so I could not determine whether it was two separate post-boundary `text` elements. **If it is, the new extraction would still join both** — the rule does not address duplication, and I am not claiming it does.

**Two things the implementation had to get right:**
- **`COALESCE(last_tool, -1)`** — with no tool_result, `MAX(...)` is NULL and `i > NULL` matches nothing, which would have silently swallowed a one-sentence "the data cannot answer this" reply. The coalesce lets it through whole.
- **FLATTEN runs ONCE, and the boundary comes from a window function.** The obvious CTE form references the flattened set twice, and Snowflake may re-evaluate it — **calling `DATA_AGENT_RUN` a second time**, which would double the latency and the cost and filter one answer against another answer's tool index.

**Verified on six fresh runs before moving on:** narration absent from every one, none empty, facts unchanged, 19–24 s.

## (c) Agent instructions v2 — quoted and verified

Scott ran `snowflake/agent-instructions-v2.sql` in Snowsight. Readback through a fresh throwaway probe:

- **`instructions.response` matches the authored `.sql` character for character**, 1,201 chars (v1: 847).
- **Preservation:** `tools`, `tool_resources`, `instructions.orchestration`, `sample_questions` all identical to the v1 readback; top-level key set `['instructions','tool_resources','tools']` unchanged; `instructions` key set unchanged; `owner`, comment, `profile`, `created_on` and `versions: ["VERSION$1"]` all unchanged.

The two added rules, verbatim:

> Write asset classes as Equity, Bond, ETF and FX forward, and never write a stored code containing an underscore such as fx_forward. Never add notional amounts together across different currencies, because the data carries no exchange rates and the total would be meaningless: report the amount for each currency separately, or give trade counts instead.

**Narration was deliberately NOT re-attempted in v2.** v1 already forbade it and was ignored on 5 of 21 runs. The guarantee now lives in the extraction; the prohibition stays in the instructions only as belt and braces.

## (d) Verification — 18 runs against the final state

| # | question | narration | chart/table ref | stored codes | cross-currency sum | facts stable | latency |
|---|---|---|---|---|---|---|---|
| C1 | Diamond Trust vs the book | **0/3** | 0 | none | n/a | yes | 23 / 23 / 23 s |
| C2 | Common fail reasons: Equity | **0/3** | 0 | none | n/a | yes | 32 / 27 / 16 s |
| C3 | This notional vs typical Equity | **0/3** | 0 | none | none — scoped to EUR | yes* | 21 / 26 / 21 s |
| S1 | Highest fail-rate counterparties | **0/3** | **1/3** | none | n/a | yes | 20 / 18 / 19 s |
| S2 | Fail rate by asset class | **0/3** | 0 | **none — labels correct** | n/a | yes | 13 / 13 / 12 s |
| S3 | At-risk notional by currency | **0/3** | 0 | none | **none — per currency** | yes | 13 / 14 / 15 s |

**Narration: 0 of 18.** The extraction change did what the instructions could not.

**Both Part 1c canon defects are fixed.** S2 now writes **"FX forward", "Bond", "ETF"** instead of `fx_forward`/`bond`/`etf`. S3 now reports per currency and says so: *"Notional at risk … is reported per currency below, since these amounts cannot be combined without exchange rates."* No unlabelled house total.

**C3 improved beyond the wording fix.** v2's currency rule made it scope the comparison to **6,280 EUR-denominated Equity trades** rather than Part 1c's undifferentiated 18,784 — a better analysis, not just safer phrasing.

**Two residual defects, both honest:**
- **S1 run 3 ended "The full top ten is below."** — a table reference v2 forbids. Worth the mechanism: the raw response genuinely contains a `table` element after the text, which the extraction drops, **so the agent is pointing at something it produced and we deliberately do not render.** 1 of 18.
- **C3 run 3 mislabelled a denominator**: *"roughly 37 times the median"*, where 37× is the multiple of the **average** (0.51M EUR); against the median (0.16M) it is ~117×. The underlying figures were identical across all three runs — this is a wrong word attached to a right number. `yes*` above.
- Cosmetic: S3 runs 2 and 3 gave figures to the cent (`EUR 7,789,544,505.30`); run 1's rounded `7.79 billion` reads far better on a screen.

## (e) Arithmetic reconciliations

| answer | check | result |
|---|---|---|
| C1 | 228 + 6,188 = **6,416**; 1,013 + 48,987 = **50,000** | exact baseline |
| C2 | 912 + 780 + 537 + 382 = **2,611** | exactly the Equity fail count |
| S2 | 2,611 + 977 + 2,043 + 785 = **6,416**; 18,776 + 7,948 + 16,697 + 6,579 = **50,000** | exact baseline |
| **S3** | per-currency trade counts 3,589 + 3,919 + 2,105 + 1,413 + 746 + 256 + 436 = **12,464** | **equals Part 1c's High+Critical (10,638 + 1,826), and baseline 12,461 + the packet's 3** |

S3's reconciliation crosses both panels and two sessions: a per-currency breakdown produced today sums to the tier counts measured in Part 1c, which themselves exceeded the recorded baseline by exactly the three seeded packet stories.

## A documentation defect found by the agent's own answer

**`CLAUDE.md` said the book runs "EUR/GBP/JPY/CHF". It runs seven currencies** — EUR, USD, GBP, JPY, AUD, CAD, CHF — measured from S3's breakdown. USD, AUD and CAD were missing from the project's own description of its data.

**I checked before raising an alarm, and there is no live defect.** `SO_fxToUsd` already covers **ten** currencies (AUD, CAD, CHF, EUR, GBP, HKD, JPY, SEK, SGD, USD), a superset of what the data holds — so every "USD eq." figure on the watchlist and supervisor screens was always computed correctly. Only the prose was wrong. **`CLAUDE.md` corrected in place**, naming the seven and recording that the rule covers ten.

## (f) Browser checks for Scott

1. **Chip weight, both panels** — do three `LINK`-style chips now read as suggestions rather than three competing actions, against the `OUTLINE` **Ask** button?
2. **Chip readability** — is every label complete and untruncated at laptop width, on both panels?
3. **Hover** — hovering a chip should now show the **full question** as a tooltip. This is the fix for your specific complaint; please confirm it actually appears.
4. **Spinner still works** — press a chip: within ~1 s it should spin and disable, then clear when the answer lands.
5. **Answers** — free of narration (18 of 18 here), no `**` markers, no `fx_forward`/`etf`/`bond`, no single cross-currency total.
6. **Optional, one Designer tick-box:** `SO_SettlementOperations` → Branding → deselect **Use uppercase capitalization for button labels**. The labels are already sentence-cased and will read correctly the moment you do.

## (g) Environment restored, evidenced

Loaded `OK run=DEMO trades=15 predictions=15 high_or_critical=3`; intake created 3 cases; hero `TRD9DEMO01` chips composed correctly. Reset `OK run=DEMO trades_deleted=15 predictions_deleted=15`, cases 96/97/98 deleted, `errDelete: false`. After: **0 `TRD9` rows**, watchlist back to 10 open fixture cases with live cutoffs. All three throwaway probes deleted and **verified absent** from the integration listing.

---

## Promotion candidates

**1 promoted-shaped, 1 carried, 1 discharged.**

1. **NEW, STAGED (gate 1): where an LLM's output must obey a hard rule, enforce it on the RESPONSE STRUCTURE rather than in the prompt.** Measured across two sessions on the same agent: an explicit prohibition in the deployed instructions was violated on **5 of 21** runs; a structural filter on the response — keep only the text elements after the last tool call — produced **0 of 18**. Trap: escalating prompt wording when the failure is non-compliance rather than misunderstanding. Working form: find a boundary in the response shape that separates what you want from what you don't, verify it holds across N runs, and filter on it; keep the prompt rule as belt and braces. Survives the noun test. *Trigger: the next build where model output must satisfy a formatting or content guarantee.*
2. **Carried and re-confirmed:** `sail load` replays cached interaction state; `--fresh` is required after a redeploy.
3. **DISCHARGED — the Part 1c candidate "an LLM instruction is a strong prior, not a constraint" is superseded by (1)**, which states the same observation *and* its working form. Recorded as merged rather than dropped.

**Promotion checkpoint: current through this entry.**

## TODO changes

Closed 3: residual narration (**0 of 18** after the extraction change); raw stored enums (fixed by v2 — "FX forward", "Bond", "ETF"); the uncurrencied house total (fixed by v2 plus the by-currency question). Added 3: S1's table reference (1 of 18); C3's mislabelled denominator; the uppercase Designer tick-box. Also corrected `CLAUDE.md`'s currency list.

## BUILD_PLAN changes

Phase 6: Part 1d recorded — chips redesigned with tooltips and LINK style, narration enforced downstream and measured at 0 of 18, agent v2 deployed and verified, both Part 1c canon defects closed.
