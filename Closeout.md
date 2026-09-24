# Closeout — 2026-09-24 — Ask panel relocation, click feedback, answer quality (Part 1b)

**Scope.** `SO_analystWatchlist` v20→**v21** (panel removed), `SO_caseDetail` v9→**v10** (panel added, replacing an inert shell that already existed there), `SO_askPanel` v2→**v3** (click feedback), `SO_askAnswerText` v4→**v5** (formatting defence), `snowflake/agent-instructions.sql` (authored, **not executed**). No process model, security or identity change. One read-only Snowflake probe, deleted and verified absent.

**Identity.** Dev MCP as `scott.thorn`. Persona reads via sail as `alex.analyst` and `sam.supervisor`. Environment **verified at clean baseline** (zero `TRD9` rows); P4-VERIFY re-dated, all three CSVs applied.

---

## (a) The greyed-out root cause — and an honest correction

**"Greyed out and does not work" does NOT reproduce from the terminal, and I am not going to invent a cause that fits.** Measured as `alex.analyst`: no `[DISABLED]` marker anywhere on the page with a row selected; the panel answered correctly with context. My first attempt to switch rows appeared to prove a stale-context bug — until I checked the checkbox state and found **`☑ TRD030639` still set**: my `interact` had never moved the selection, and the panel had been right all along. Reporting that as the cause would have been a fabrication.

**What IS evidenced, and it explains the report without needing a disable bug:**

1. **The one thing in the panel that greys is the Ask button** — it carried `disabled: a!isNullOrEmpty(local!draft)`. On any fresh page the draft is empty, so Ask renders grey. I observed exactly that as `"Ask" <click> [DISABLED]` on the supervisor panel's first render this session.
2. **Nothing else looked pressable.** The chips were `a!richTextItem` + `a!dynamicLink` — they render as prose-coloured text, not controls.
3. **Clicking one produced no feedback for 20–45 seconds** (finding 1).

So the panel presented prose that did not look clickable, one grey button, and no response to a click. "Greyed out and does not work" is a fair description of that from the user's seat, and all three are now fixed.

**The scope half of the finding is real and structural.** The watchlist auto-selects row 1, so context usually existed — but deselecting left `contextLine` empty while the panel still read "ASK ABOUT THIS CASE", asking house-wide under a heading that claimed otherwise. Scope was invisible and could silently be nothing.

**None of it can travel to case detail, by construction: there is no selection there.** `rv!record` fixes the case for the whole page.

## (b) Case detail placement and composed chips

**The shell was already there.** `SO_caseDetail` carried card `7c · ASK — PHASE 6 SHELL, DELIBERATELY INERT` (a disabled text field), sitting after `7a · AGENT ASSESSMENT` and `7b · TIMING`. Neither the brief nor Part 1 knew it existed. So this was replacing a dormant shell in its designed home, not inserting a new card.

**Placement, and why:** immediately after the agent's assessment and its timing, in the main `AUTO` column (full width of the content area). That is the analyst's actual decision order — read what the machine concluded, check the window, then interrogate the book before disposing. **"Before the disposition action" resolves to "last in the reading order":** the disposition is a *record action in the record header* (ratified 2026-09-09), not a card on this view, so there is no button to sit above.

**Composed chips, rendered live on case `TRD026800`:**

```
How does Vanguard Prime's settlement fail rate compare with the rest of the book?
Which risk factors most often drive settlement fails for Equity trades?
How does this trade's 11.8M EUR notional compare with typical Equity trades?
```

Counterparty, asset class and notional all come from the case's own fields. The asset class is rendered through `SO_assetClassDisplay` and **left in title case on purpose** — lower-casing it into the sentence would have produced "etf trades" and destroyed an initialism.

**Context line** carries the same facts plus trade id, ticker and desk, so a free-typed question inherits them too.

## (c) Click feedback — mechanism found; Part 1 had the wrong keyword

**The documented parameter is `loadingIndicator`, not `enableLoadingIndicator`.**

> **Show loading indicator on press** — `loadingIndicator` [Boolean] — "Determines whether the button will display a loading indicator on press **and be disabled while processing**." — [Button Component, 26.6](https://docs.appian.com/suite/help/26.6/Button_Component.html#parameters)

Part 1 read `enableLoadingIndicator` off a rendered button's component tree, had it rejected by the object validator, and concluded no spinner existed. **The tree prints an internal attribute name; the settable keyword is different.** `loadingIndicator: true` was accepted by the object validator this session — so the mechanism was there all along.

**It is button-local, so every ask path is now a button.** The chips became stacked `a!buttonWidget`s, each with its own indicator; the Ask button has one too and **is no longer disabled on an empty draft**.

**What the browser should show, precisely:**
- **On press, within ~1 s:** the pressed button shows a spinner and becomes disabled. It stays that way for the whole call. A second click on *that* button cannot queue a second call.
- **On return (20–45 s):** the spinner clears, the question echoes in bold, the answer appears beneath it with the snowchip provenance line.

**What it will NOT show, and I am not going to claim otherwise:** the question echo and an "Asking Snowflake…" line **cannot** appear before the answer. The call is synchronous — Appian paints once, when the evaluation returns — so any local set in the same `saveInto` is invisible until the answer is already on screen. There is no documented mechanism that repaints mid-evaluation short of the async process-and-poll route the brief explicitly forbade.

**So the wait is made expected instead of narrated.** A standing line sits under the buttons, visible before anyone clicks: *"Answers are computed live in Snowflake and take 20–40 seconds."* Setting the expectation up front beats a progress message that cannot render. **This is a partial satisfaction of Task 3 and should be read as such**: the disable and the spinner are delivered; the echo-and-asking-line is not achievable synchronously.

## (d) The agent's current specification, and the authored change

Read through a throwaway read-only probe (`DESCRIBE AGENT`), now deleted and **verified absent**. Current spec:

- **`instructions.response`**: *"You are a trade settlement risk analyst. Answer questions about settlement failures, counterparty risk, and trade predictions concisely with data-backed answers."* — that is all of it, which is why the agent narrates freely.
- **`instructions.orchestration`**: use the Analyst tool for settlement data questions.
- **`instructions.sample_questions`**: five.
- **`tools`**: exactly one — `cortex_analyst_text_to_sql`, "SettlementAnalyst".
- **`tool_resources`**: semantic view `FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_ANALYTICS`, warehouse `COMPUTE_WH`, `query_timeout` 299.
- No `models` block, no top-level `orchestration` block. Owner `FINSERVADMIN`, single version `VERSION$1`.

**This closes the read-only gap Part 1 flagged as unverifiable.** The agent's only tool is text-to-SQL over a semantic view, which cannot emit DML — now measured rather than assumed.

**Preservation argument.** Snowflake's docs are explicit: `ALTER AGENT … MODIFY LIVE VERSION SET SPECIFICATION` **"completely replaces the existing one. Fields that are not included in the new specification are removed."** There is no partial edit. So preservation is achieved by restating every other field character-for-character as `DESCRIBE` returned it, and changing only `instructions.response`. No `models` or top-level `orchestration` block is added, because adding one would itself be a change.

**The new response instruction, quoted in full:**

> You are a trade settlement risk analyst answering a colleague on a settlements desk. Lead with the answer in your first sentence. Keep the whole reply to two to four sentences. Write plain text only: no markdown, no asterisks, no bold, no bullet points, no headings. Never describe your own process - do not mention verified queries, semantic models, logical or physical column names, SQL, tools, or what you are about to do, and never write phrases like 'let me', 'I will look at', 'first I need to', or 'here is'. Never refer to a chart, graph, table or any visual, because the answer is shown as text only and no visual exists. Whenever you give a rate or a percentage, state the numerator and denominator that produced it, for example '24.37 percent, 240 of 985 trades'. If the data cannot answer the question, say so in one sentence and stop.

Saved as `snowflake/agent-instructions.sql` with the full header. **Not executed.**

## (e) `SO_askAnswerText` changes

Strips **only unambiguous** markdown — `**`, `__`, backticks. **A single `*` is deliberately left alone**: it can be a footnote or a multiplication sign, and stripping it would corrupt an answer to fix a cosmetic.

Blank-line runs are normalised **by construction** rather than by chasing run lengths: split on newline, trim each line, drop the empties, rejoin with exactly one blank line. Verified by `testRule` — six consecutive newlines, `**bold**`, `__under__` and backticks in, clean two-paragraph prose out.

**It does not filter narration, on purpose.** Any display-side filter would have to guess which sentences are working-out, and a wrong guess silently deletes answer prose. Formatting is safe to normalise; meaning is not. That is the agent statement's job.

## (f) Verification

| Check | Result |
|---|---|
| Watchlist without panel, `alex.analyst` | **0** occurrences of the panel; page alive, 35 displays |
| Supervisor panel shape | 3 **buttons**, standing wait line, `"Ask"` **no longer `[DISABLED]`** |
| Supervisor answer, markdown | 23 s; **no `**`, no `\n\n\n`**. "Jade Capital leads at a 27.23% fail rate (281 of 1,032 trades failed)…" |
| Case chips composed | Vanguard Prime / Equity / 11.8M EUR — all from case fields |
| Case chip 1 | **27 s**, answered. Names Vanguard Prime, TRD026800, ENGI FP, 11.8M EUR Equity on EQ_FLOW. 240 + 6,176 = **6,416 / 50,000** — reconciles to recorded baseline |
| Case chip 2 | **24 s**, answered, names the case |
| Case chip 3 | **FAILED — 46 s, then the plain failure line; page intact** |

**Chip 3 failing is a real result, not a blip to hide.** It is also the failure path working in production conditions rather than only under break-test: one calm amber line, everything else on the screen untouched. Under the Part 1 bar — *"a question that cannot clear that bar is replaced, not shipped"* — **the notional-comparison question is now suspect and must be re-run or replaced** in the completion session.

**Narration is still present**, as expected — chip 1 opened *"I'll look at the settlement data model…"* and chip 2 *"I'll analyze what risk factors…"*, and chip 2 referred to a breakdown it never rendered. That is exactly what the agent statement fixes, and it is why it exists.

**Not verified:** the hero with a packet loaded (case detail was proved on fixture case `TRD026800`; no packet was loaded, and loading costs ~2 min plus triage); all geometry and paint; the three-run stability bar; whether chip 3's failure is intermittent or structural.

## (g) Scott's steps

1. **Run `snowflake/agent-instructions.sql`** in Snowsight — one statement, worksheet role `FINSERVADMIN`, warehouse `COMPUTE_WH`. Expected: one row, *"Statement executed successfully."*
2. **Browser, both panels** — click a chip and confirm: **within about a second the button shows a spinner and goes disabled**; it stays disabled for the whole wait; when the answer arrives the spinner clears and the question echoes above it. *Expect no separate "Asking…" line — see (c) for why; the standing "20–40 seconds" line under the buttons is what sets the expectation.*
3. **Formatting** — no `**` markers anywhere, no large blank gaps between paragraphs.
4. **Case detail placement** — does the Ask card read as part of the decision flow, sitting after the agent's assessment and timing?
5. **Watchlist** — confirm the panel is gone and the screen reads as it did before Part 1.

---

## Promotion candidates

**2 found; 1 is a correction to a Part 1 candidate.**

1. **CORRECTION, measured:** a rendered component tree prints **internal attribute names** that differ from the settable keyword — `enableLoadingIndicator` in the tree versus `loadingIndicator` in the documentation and in the object validator. The existing supplemental entry says a tree attribute is not proof of a *writable* one; this adds the sharper form: **the tree's name may not even be the parameter's name, so a rejection should send you to the docs rather than to the conclusion that the feature is absent.** Part 1 concluded "no spinner exists" on exactly that mistake. *Trigger: next session that touches the supplemental.*
2. **STAGED (gate 1): `sail load` replays a cached interaction state and does not refetch; `--fresh` is required to see a redeployed build.** Measured twice: a panel rendered its previous answer and its pre-rebuild shape after a plain `load`, and sail said so explicitly — *"settlement-ops is loaded with 6 interactions already made; loading would fetch a new page and discard that."* Trap: verifying a rebuild against a cached render and concluding it did not deploy. *Trigger: the next session that redeploys an object and re-renders it through sail.*

**Promotion checkpoint: current through this entry.**

## TODO changes

Closed 2: the Ask-panel narration/chart defect (statement authored, pending Scott), the blank-line cosmetics (fixed in `SO_askAnswerText`). Added 3: chip 3 failed and must be re-run or replaced before it ships; the hero-with-packet verification still owed; the echo-and-asking-line is not achievable synchronously and is recorded as a known limit rather than an open task.

## BUILD_PLAN changes

Phase 6: Part 1b recorded — panel relocated to case detail, click feedback delivered via `loadingIndicator`, answer-quality statement authored and awaiting Scott.
