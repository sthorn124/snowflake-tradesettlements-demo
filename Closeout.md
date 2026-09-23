# Closeout — 2026-09-22 — Console redesign: a healthy screen is quiet

Presentation pass on `SO_demoAdminConsole`, plus the one functional check and the one deletion you authorised. The default healthy view went from 312 words to 42. Environment left clean: 17 fixture cases, 12 comments, 14 audit rows, 0 demo trades.

## (a) Word counts, default healthy view

| | v8 | v9 |
|---|---|---|
| Visible prose (excl. button labels and count values) | **312 words** | **42 words** |
| Longest line | 34 words | **11 words** |

Both budgets met: under 60 words total, no sentence over 15. Counted from the strings that actually render on the unexpanded healthy view — collapsed Details contents excluded, since they are not visible until asked for.

## (b) The new structure, as rendered

**Header — three lines, no box.**
1. "Demo Admin · Settlement Operations"
2. "One demo at a time. Load starts it, Reset removes it."
3. "Signed in as … · 22 Sep 21:25"

The blue callout card, "You need nothing but this page", and the DEMO-name explanation are all gone. The SC never types the name, so they never need to know it.

**Card 1 — the verdict.** One line:

> **Ready**   ·  data 50,000/50,000  ·  9/9 connections  ·  agent OK

- Failing checks surface here in red with their detail, without expanding anything: baseline data mismatch, `✕ No connection to <names>`, `✕ No record of the AI agent running`.
- **Only failing connection names render.** Nine passing names told the SC nothing.
- A neutral grey "Loaded now: 15 demo trades · 3 cases" line appears only when something is loaded.
- **"Details"** — a standard `a!sectionLayout`, collapsible, initially collapsed. Inside: label + value only, through the existing `SO_adminCheck` so the three-state vocabulary stays in one place. Baseline trades 50,000 · Baseline predictions 50,000 · Demo trades · Demo cases · Built-in test cases 17 · Case comments 12 · Audit rows 14 · Connections 9 of 9 · AI agent last run.
- **The agent footnote was deleted, not tooltipped.** `helpTooltip` renders only beside a visible label, and the line was narration about a check rather than a check.

**Card 2 — "Run the demo".** Status line, then the two buttons side by side, each with a one-line caption:
- **Load the demo** — "15 trades score in Snowflake; risky ones open cases. About 2 minutes."
- **Reset the demo** — "Removes this demo's data from both systems."

**Results.** Success is one green line plus the small grey "Snowflake's response:" verbatim. Refusals and failures keep full prominence — ink, STANDARD, bold. The reset "was / now" counts stay; they are the evidence line.

**One correction beyond the spec, worth knowing.** In v8 the "Leftover data" check went **red whenever a demo was loaded** — the expected state during a demo read as a fault. The verdict now covers data, connections and agent only; demo rows are reported as neutral state. Confirmed by render: with a case loaded, the verdict still reads green **Ready**.

## (c) The Reset enable finding

**Checked, already correct, nothing changed.** The condition is `disabled: not(local!statusLoaded)`, where

```
local!statusLoaded: or(local!tradeReserved > 0, local!otherCases > 0)
```

`tradeReserved` counts `TRD9*` rows in Snowflake and `otherCases` counts non-fixture Appian cases, so Reset is enabled when **either** side holds demo rows. The residue state you describe — Snowflake rows present, zero Appian cases — keeps the button live, and pressing Reset again is the recovery. This was already fixed when the button stopped keying on case count during the B2 console wiring; I have added a comment at the button recording why, so a future edit does not quietly narrow it back.

Verified by render: with zero rows the button reads `disabled: true`; with one case it reads `disabled: false`.

## (d) Your browser checklist

1. **One glance.** Open the console. You should see a title, one line of orientation, a green **Ready** line, and two buttons — nothing else competing.
2. **Details.** Expand "Details": nine label+value lines, no narration. Collapse it again; it should stay collapsed on reload.
3. **Load.** Press **Load the demo**. Expect "Feed loaded" plus small grey `Snowflake's response: OK run=DEMO trades=15 predictions=15 high_or_critical=3`, and the status line moving to "Demo loaded — 15 trades, 3 cases."
4. **Verdict stays green while loaded** — the point of the correction in (b).
5. **Reset.** Press **Reset the demo**. Expect "Cleaned up", the verbatim response, and the was/now evidence line ending 0 · 0 · 0.
6. **Failure prominence, by inspection not execution.** The REFUSED path is unreachable from the console now that the name is a constant, so read the styling rather than trigger it: refused and failed results render at STANDARD ink bold where success renders SMALL grey. If you want to see it fire, call `SO_simulateFeed` from its integration object in Designer with a bad name.
7. **Geometry, browser-only:** whether the two buttons and their captions align cleanly side by side at your window width, whether the captions read as captions rather than body text, the collapsed Details affordance's visibility, and the greyed-out Reset contrast.

## (e) Deletion confirmed

`SO_zz_probeQuery` (`_a-0001f054-7a62-8000-9c49-011c48011c48_562148`), a throwaway from an earlier session labelled "THROWAWAY: traversal + aggregation probe. Delete after use.", was **deleted on your word** — `deleteInterface` returned "Deleted successfully". The TODO item that carried it is closed.

## (f) Files updated

`Closeout.md` (this), `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`, and `CLAUDE.md` — the Demo Admin section now carries the quiet-screen rule so the next session does not re-narrate the console.

## Verified / not verified

**Verified** (Dev MCP as `scott.thorn`, full scope): both renders `diagnostics.error: null` — healthy/no-data (verdict green, Details collapsed, Reset disabled) and loaded (verdict still green, "Loaded now" line, Reset enabled); the section renders with `isCollapsible: true, isInitiallyCollapsed: true`; word counts above; the deletion; environment clean before and after.

**Not verified:** everything geometric, listed in (d) 7. The loaded render used a throwaway case rather than a real Snowflake load, since this session calls no integrations. The refused/error styling is verified as configuration, not by firing it.

## Promotion

**1 new candidate, STAGED.** Removing the last consumer of a local variable makes an interface **unsaveable** until the local is deleted: `updateInterface` rejected the redesign with `HTTP 400 — Unused Local Variables at line: 122 — local!otherSessionList`. An unused local is an error, not a warning, so any edit that drops a display line must drop its locals in the same pass. Measured once, here. *Trigger: the next interface edit that removes a rendered section.*

Carried forward: the agent-boolean method note stays staged; Dev MCP process-instance blindness stays staged; NTZ-as-UTC and chart-type stay staged.
