# v6 — step 3 tightening (DRAFT, not applied)

Threshold unchanged at 0.80. Extended context unchanged. Step 3 only; steps 1, 2,
4, 5, 6, Tool discipline, Grounding and Run summary are untouched.

---

## v5 step 3 — CURRENT, verbatim

> 3. Weigh the remaining case facts, but only facts that are actually concerning count against confidence: an unusually large notional for the desk, a counterparty with a high risk tier or an above-average historical fail rate, a tight window. Favorable facts — modest size, a roomy window, a low-risk counterparty with a below-average fail rate — are reassurance and must not lower confidence; a case whose facts are favorable across the board deserves 0.85 or higher. Concerning facts compound: two or more together lower confidence substantially. The fail probability is why the case exists — never lower confidence because it is high.

## v6 step 3 — PROPOSED, verbatim

> 3. Weigh the remaining case facts. Only genuinely concerning facts count against confidence; every other fact is reassurance or neutral information.
>
>    **The prediction is the premise of the case, never a concern.** The fail probability *and* the prediction's risk tier are the reason this case exists at all. Never lower confidence because the probability is high, or because the risk tier is Critical or High. Doing so double-counts the premise of the case against its own remediation.
>
>    **Concerning facts are exactly these:** an unusually large notional for the desk; a counterparty at HIGH risk tier, or a historical fail rate materially above the dataset average of 9.2% — treat 13.8% or above as materially above; a tight window; a trade that is NOT matched; one or more onward deliveries of the instrument in the next two settlement cycles.
>
>    **Favorable or neutral facts, which must never lower confidence:** a counterparty at LOW or MEDIUM risk tier, or a historical fail rate at or near the dataset average; a modest notional; a roomy window; a matched trade; zero onward deliveries; and the instrument's identity, ISIN and settlement venue, which are informational only and never bear on confidence.
>
>    Concerning facts compound: two or more together lower confidence substantially. A single mild concern does not.
>
>    A case whose facts are favorable across the board deserves 0.85 or higher. If you find yourself listing "mild concerns" that are each individually favorable or neutral by the definitions above, you have miscounted — do not aggregate them into a lower score.

---

## What changed, and why each clause exists

| Change | Why |
|---|---|
| Risk tier added to the "never a concern" clause | v5 covered only *fail probability*. The 0.78 draw counted **"High risk tier prediction"** as one of two concerns. That is the exact gap. |
| Concerning facts enumerated exhaustively ("exactly these") | v5's open-ended list let the model nominate new concerns. Closing the list removes the discretion that produced the variance. |
| Counterparty threshold keyed to tier + a stated number | See the correction below — this is the clause that does the real work. |
| Matched status and onward deliveries placed on both lists | New context fields. Matched/zero-onward are favorable; NOT-matched/non-zero-onward are genuine risk and must stay concerning. |
| Instrument identity explicitly inert | Ticker, ISIN and venue are for the analyst to read, not for the model to weigh. |
| Final "if you are listing mild concerns, you have miscounted" | Targets the observed failure sentence directly. |

---

## ⚠ Correction to the brief's clause (b)

The brief specified: *"a counterparty fail rate at or below the dataset average is a favorable fact and never a concern."* **As literally worded this would not fix the defect.**

Measured across all 50 counterparties: **mean 9.20%**, median 5.87%, range 2.15%–21.58%.

Zephyr Securities — the clean specimen's counterparty — sits at **9.55%, which is above both the mean and the median.** A rule that only protects rates *at or below average* leaves 9.55% available to be counted as a concern, which is exactly what the 0.78 runs did. It also means v5's assessment calling 9.55% *"below-average"* was factually wrong; it produced the right answer for the wrong reason, which is why it was never stable.

The tiers separate cleanly in the data, so v6 keys the rule to tier with a numeric backstop:

- `low` tier: 2.15%–5.95%
- `medium` tier: 8.19%–11.59%  ← Zephyr, 9.55%
- `high` tier: 18.75%–21.58%

"LOW or MEDIUM tier is not a concern; HIGH tier or ≥13.8% is" places the boundary in the empty gap between the medium and high bands, so it is robust to the exact rate and cannot be flipped by a counterparty sitting a few basis points either side of a mean.

If you would rather keep the literal wording, say so — but the clean specimen will keep straddling the gate.

---

## Expected effect on the three specimens

| Specimen | Now | Expected under v6 |
|---|---|---|
| Hero TRD9NY101 | 0.72 → Pending Analyst | **Unchanged lane.** Diamond Trust is genuinely HIGH tier at 19.89%, and the notional is large for the desk — two real compounding concerns. Held for review is correct and should become *stable*, not merely likely. |
| TRD016924 | 0.78 / 0.87 across runs | **0.85+, stable.** Medium tier, near-average rate, matched, zero onward, roomy window — favorable across the board with no admissible concern. |
| TRD044567 | 0.50 → Escalated | **Unchanged.** Step 2's timing rule fires first (26.07h lag vs 23h window) and caps confidence at ≤0.5 regardless of step 3. |

Nothing in v6 touches step 2, so the escalation path cannot regress.

---

## Apply note

`agent/instructions.md` line 3 still reads *"what is currently deployed (v4)"* — stale since v5. Update to v6 when this is applied in Agent Studio.
