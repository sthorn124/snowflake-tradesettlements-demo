# Closeout — 2026-09-24 — chip labels become natural-language questions

**Scope.** Label strings only. `SO_supervisorCommand` v10→**v11**, `SO_caseDetail` v12→**v13**. Nothing else touched: the questions sent, echoed and shown as tooltips are byte-identical to Part 1d, and `SO_askPanel`, `SO_askSnowflake`, the extraction and the agent are all unchanged. **No Cortex calls made** — none were needed.

**Identity.** Dev MCP as `scott.thorn`. Persona renders via sail as `sam.supervisor` and `alex.analyst`. Environment verified clean (0 `TRD9` rows); P4-VERIFY fixtures re-dated per the ritual, since this session renders Phase 4 screens.

---

## The six labels, as rendered

**Supervisor**, as `sam.supervisor`:
```
Who has the highest fail rates?
How do fail rates differ by asset class?
How much notional is at risk, by currency?
```

**Case detail**, as `alex.analyst` on fixture case `TRD026800` (Vanguard Prime / Equity):
```
How does Vanguard Prime compare with the book?
Why do Equity trades usually fail?
Is this trade unusually large for Equity?
```

All six render as `<click>` buttons. `LINK` style, `SMALL`, `MINIMIZE`, `loadingIndicator` and `tooltip` all retained.

**Tooltips verified individually**, each found on a `tooltip:` line in the rendered YAML carrying its full, unchanged question:

| chip | tooltip |
|---|---|
| Who has the highest fail rates? | Which counterparties have the highest settlement fail rates? |
| How do fail rates differ by asset class? | What is the settlement fail rate by asset class? |
| How much notional is at risk, by currency? | What is the notional at risk for High and Critical risk trades, by currency? |
| How does Vanguard Prime compare with the book? | How does Vanguard Prime's settlement fail rate compare with the rest of the book? |
| Why do Equity trades usually fail? | What are the most common fail reasons for Equity trades? |
| Is this trade unusually large for Equity? | How does this trade's 11.8M EUR notional compare with typical Equity trades? |

## The length check — and it inverts the brief's assumption

Measured against the data rather than estimated. **Longest counterparty name across all 50: `Iron Gate Securities` (20 chars)**; longest asset-class display label: `FX forward` (10).

| label | worst case | chars |
|---|---|---|
| Supervisor 1 | fixed | 31 |
| Supervisor 2 | fixed | **40** |
| Supervisor 3 | fixed | **42** |
| Case 1 | Iron Gate Securities | **52** |
| Case 2 | FX forward | 38 |
| Case 3 | FX forward | 45 |

**The brief asked me to check the composed case labels against "the length that fit untruncated in Part 1d". That comparison does not mean what it looks like, and the risk is on the other panel.**

The two panels sit in different containers, which I verified in the source rather than assumed:

- **Supervisor Ask panel: `a!columnLayout(width: "MEDIUM_PLUS")`** — a narrow rail. The longest label previously shipped there was **32** chars. Supervisor labels 2 and 3 are **40 and 42** — 25% and 31% over the only length proven to fit in that container. **This is the genuine truncation risk.**
- **Case Ask panel: the full-width `AUTO` column** of case detail. Its Part 1d label was 31 chars, but in a card that wide, 31 was nowhere near the limit — it was simply short. **Exceeding it is not evidence of truncation**, so 52 chars is plausible there and I did not shorten it.

**Nothing was shortened.** Shortening a 52-character label in a wide card while leaving a 42-character one in a narrow rail would have followed the instruction's letter and missed its point. Both are reported instead, and geometry is a browser check by project rule (CLAUDE.md §4) — sail carries no pixel widths.

**The tooltip covers the failure mode either way.** Even if a supervisor label truncates, hovering now shows the full question — which is precisely the gap Part 1d closed.

**Drop-in shorter alternatives, if your browser check shows truncation in the rail** (same voice, both ≤32):

| current (chars) | shorter (chars) |
|---|---|
| How do fail rates differ by asset class? (40) | Which asset class fails most? (29) |
| How much notional is at risk, by currency? (42) | How much is at risk, by currency? (33) |

Say the word and it is a two-string change.

## Browser check for Scott

1. **Both panels** — do the labels now read as questions rather than report titles?
2. **Sentence case** — after you untick *Use uppercase capitalization for button labels* on `SO_SettlementOperations`, the labels should render exactly as written above. They were authored in sentence case for this.
3. **Truncation, supervisor panel specifically** — labels 2 and 3 are 40 and 42 characters in the MEDIUM_PLUS rail, against 32 previously proven. If either truncates, the alternatives above are ready.
4. **Truncation, case panel** — worst case is 52 chars on a counterparty named `Iron Gate Securities`; the fixture cases show shorter names, so this one only appears on the right case.
5. **Hover** — every chip should show its full question.

## Verified / not verified

**Verified.** Both saves byte-identical on readback; questions confirmed unchanged in the deployed source of both screens; all six labels rendered as `<click>` buttons through sail as the correct persona; all six tooltips confirmed present and carrying the full question.

**Not verified.** All geometry — whether any label truncates at laptop width, which is browser-only. No Cortex call was made, so answer behaviour is unchanged by construction rather than re-measured.

## Promotion candidates

**None.** This was a string change. The container-versus-string-length observation below is a project fact, not a portable one, and is recorded in `BUILD_LOG.md` rather than staged.

## TODO changes

Updated 1: the uppercase-button-labels item now records that Scott is doing it in Designer. Added 1: watch the two over-length supervisor labels in the rail, with the shorter alternatives recorded so the fix is a two-string change rather than a re-derivation.

## BUILD_PLAN changes

Phase 6: label change recorded against Part 1d.
