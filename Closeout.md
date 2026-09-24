# Closeout — 2026-09-24 — Post-rehearsal cleanup: display honesty, presenter grants, records brought current

*Scope and identity:* Dev MCP as `scott.thorn` (SO Supervisors — full scope) for object work, security and the process-path load/reset; **sail as `alex.analyst` and `sam.supervisor`** for the persona comparison that is the whole of Task 1. No `appian_*`, no `ping`. **One interface changed:** `SO_caseDetail` v7 → v8. **Three process models re-secured.** Four documents updated. No throwaways needed.

*Gate:* baseline verified before starting — 17 cases all `P4-VERIFY`, console `Ready · 50,000/50,000 · 9/9 · agent OK`, 0 demo trades, 0 demo cases. The P4-VERIFY re-date ritual was re-run: the previous re-date was 85 minutes old and this session renders Phase 4 screens, so cutoffs had decayed far enough to matter (case 37 had already passed its cutoff).

---

## (a) The counterparty recent-fails card

### 1. Cause confirmed — same card, same case, two identities

Loaded a real run, opened the hero case (`TRD9DEMO01`) as each persona, read the same five rows:

**`alex.analyst` (EQ_FLOW):**
```
Date, Trade, Instrument, Reason, Value
Sun 6 Jul,  TRD040796, —, Operational error,       0
Thu 19 Jun, TRD022509, —, Insufficient securities, 0
```

**`sam.supervisor` (all desks):**
```
Date, Trade, Instrument, Reason, Value
Sun 6 Jul,  TRD040796, ALV GY,             Operational error,       2.7M EUR
Thu 19 Jun, TRD022509, BAYERN 1.768 09/29, Insufficient securities, 1.7M EUR
```

Identical dates, trade ids and reasons; **only the trade-sourced fields differ.** Date, trade id and fail reason come from **SO Settlement History**, which is not desk-secured, so every viewer sees them. Instrument and notional come through the **trade**, which is desk-secured — and a counterparty's fails are spread across desks by nature, so an analyst reading a broker's history legitimately cannot read most of these trades. **Desk security is the mechanism, confirmed.**

The zero was the real fault, and it was in the code rather than the data: the Value column called `SO_fmtMoney(amount: index(fv!row, …notional, 0), …)` — **defaulting a null notional to 0 and then formatting it.** A fabricated number in a money column, indistinguishable from a real zero.

### 2. The fix as built

**Form chosen: per-row labelling, not a count line.** For an analyst *every* row here is usually out-of-desk, so collapsing them into "5 fails you cannot see" would throw away the dates and reasons she *can* see — and the reason mix is the card's entire argument, the thing the summary line beneath it computes. Per-row labelling keeps the argument intact and hides only the two cells that are genuinely unreadable. A count line would have been the right choice on a card where the hidden rows were the minority; here they are the norm.

- **Instrument cell** — when both the ticker and the notional read null (the trade is unreadable), renders `outside your desk view` at SMALL in muted `#6E7885`. `preventWrapping` dropped on this cell alone, because the phrase is longer than a ticker and truncating it would defeat the point of saying it.
- **Value cell** — when the notional is null, renders an em dash in muted, never a formatted 0. The em dash is the null convention already used across these screens, and the instrument cell beside it says why.
- **The summary line is untouched** and still computes from SO Settlement History, which every viewer can read.

### 3. Readback

`SO_caseDetail` `_a-0000f057-1da8-8000-9c4b-011c48011c48_564319`, **v7 → v8**. `updateInterface` returned the stored expression **byte-identical** to the local `.work` source; `validateDesignObject` → `hasErrors: false`; `testInterface` (case 36) → `diagnostics.error: null`.

**No security was changed anywhere for this task** — the fix is display-side only.

---

## (b) Security grants — readback

**A correction first, because it nearly went the other way.** My working note recorded `53dbfcbc-8eb9-4ecd-943d-7f68c62023bb` as the "admin group UUID". `listGroups` shows it is **SO Administrators**, not SO Demo Admins. **SO Demo Admins is `_e-0000f057-1d8f-8000-9b9b-01075c01075c_5425`**, and it held **no rights at all** on the three process models — which is exactly why a presenter in that group alone could not press Load or Reset.

`updateObjectSecurity` is a **full replacement**, so each call resent the complete role map with only `initiator` changed.

| process model | UUID | before | after |
|---|---|---|---|
| `SO_simulateRun` | `0000f060-f4ba-8000-2418-7f0000014e7a` | `initiator: []` | `initiator: [SO Demo Admins]` |
| `SO_intakeRun` | `0000f060-f4bd-8000-2419-7f0000014e7a` | `initiator: []` | `initiator: [SO Demo Admins]` |
| `SO_resetRun` | `0000f060-f4bf-8000-241a-7f0000014e7a` | `initiator: []` | `initiator: [SO Demo Admins]` |

Every other role preserved verbatim on all three: `administrator: [SO Administrators]`, `viewer: [SO Users, SO Supervisors, SO Analysts]`, `editor / manager / deny: []`.

**Verified independently, not from the PUT response** — a fresh `getObjectSecurity` on `SO_intakeRun` returns `initiator: ["_e-0000f057-1d8f-8000-9b9b-01075c01075c_5425"]`. No group nesting changed, no membership changed, no other identity touched.

**`GETTING_STARTED.md`** gained a short subsection, "The demo presenter's own account": two plain-language lines saying a presenter must be in **SO Demo Admins** (or the console's buttons cannot start their process models and it reports "could not start") **and** in **SO Supervisors** (or intake reads a desk-scoped prediction set and silently creates cases for one desk only).

---

## (c) Records brought current

1. **Reset delete-click residual — CLOSED BY RULING.** Citation recorded in TODO: three live human-clicked Resets with the was/now evidence line read back in the 2026-09-22 and 2026-09-24 sessions, plus `snowflake/verification-summary.sql` **checks 20/21**, which prove tag-scoped deletion is prefix-safe at any code length (runs `VFY1` vs `VFY12`, packet-spec §1). **The same citation closes the console's was/now human check**, and closes **GATE D part (c)** in place. `a!deleteRecords` in a `saveInto` remains session-uninvocable — recorded now as a tooling boundary, not an unverified link.
2. **Parked intake instances — CLOSED on Scott's word**, both terminated in the Admin Console on 2026-09-22. Noted explicitly that this is not independently verifiable from a session: process instances are not readable over the Dev MCP at all, so **the Admin Console is the authority for instance state** and a session can only record the ruling.
3. **CLAUDE.md corrected.** The rule that said the status→action mapping "is now a browser check and only a browser check" is rewritten. It now states what is still true (the header renders outside the view interface, so `testInterface` sees no action set, and a throwing visibility expression hides its action silently) and what is not (browser-only), citing the rehearsal: as `alex.analyst` the header listed `Record Disposition · Assign · Escalate · Add Comment` in the record type's own order, and `Record Disposition` was followed, filled and submitted through to a written disposition. **The mapping is now verified as a persona through sail, per case status; only the header's geometry stays a browser check.**
4. **TODO updates:**
   - **The hero's scripted analyst action is DECIDED** — `Record Disposition → Settled - Borrow Executed`, the disposition `SO_remediationForReason` maps to `insufficient_securities` and the one that makes the agent's proposed cover borrow the thing the analyst accepts. What remains is the script around it, not the choice.
   - **Demo-script inputs list started** under that item: (i) the decided action; (ii) do not press Load twice mid-demo — it re-stamps the scoring batch away from the case timestamps; (iii) if the console shows the amber "Loaded before today" line, Reset then Load before presenting, or every cutoff on the book reads as past.
   - **Matched-time gate divergence moved** into the next-mockup-pass block, beside the supervisor mockup refresh which already lived there.
   - The double-Load talk-track item is marked as captured into the demo-script inputs rather than duplicated.

---

## (d) Verification

| check | result |
|---|---|
| Cause, `alex.analyst` (before) | `—` instrument, `0` value on all five rows |
| Cause, `sam.supervisor` (before) | `ALV GY / 2.7M EUR`, `BAYERN 1.768 09/29 / 1.7M EUR` — same rows, same case |
| Fix, `alex.analyst` (after) | `outside your desk view` + `—`; dates, trade ids and reasons intact |
| Fix, `sam.supervisor` (after) | **unchanged** — `ALV GY / 2.7M EUR`, `BAYERN 1.768 09/29 / 1.7M EUR` |
| Summary line, both personas | identical and unchanged: `5 most recent · 4 of 5 on insufficient securities — consistent with the predicted reason on this case` |
| `SO_caseDetail` | `validateDesignObject` clean · readback byte-identical · `testInterface` (case 36) `error: null` |
| Security | independent `getObjectSecurity` confirms `initiator: [SO Demo Admins]`, all other roles unchanged |
| Environment restored | `Ready · 50,000/50,000 · 9/9 · agent OK` · 0 demo trades · 0 demo cases · 17 built-in · 12 comments · 14 audit rows · `No demo data loaded.` · Reset `disabled: true` |

**Not verified:** all geometry and paint. Specifically — **`outside your desk view` is 22 characters in a `NARROW` column with wrapping now permitted, so it will take two lines.** Whether that makes the rows uneven, and whether the muted SMALL treatment reads as a note rather than as data, are browser checks. Also unverified: that a presenter who is *only* in SO Demo Admins can now actually press the buttons — the grant is confirmed by readback, but the click is a human check, and it belongs on the GATE D pass.

---

## (e) Stopped on, and flagged

1. **`GETTING_STARTED.md` is template-owned, and these lines are build-specific.** CLAUDE.md's own file list says the template files are "copied unchanged from appian-devmcp-method — edit them in the template, not here", and the operating core's premise is that nothing in it names a client, an application or a group. The two lines I added name **SO Demo Admins** and **SO Supervisors**. I wrote them where you asked and marked them in the file as a build-specific note with a pointer, but **they will conflict on the next template pull**. Recommendation: the durable home is the project sections of `CLAUDE.md`, with `GETTING_STARTED.md` carrying at most a parameterised line ("the presenter must hold both the console group and the full-data-scope group named in `BUILD_PLAN.md`"). One line either way — your call.
2. **The recent-fails weekend dates are untouched and remain the deliberate known artifact** (`Sun 6 Jul` is visible in the capture above). Flagging only so nobody reads this session's change as having addressed them; it did not, by design.
3. **Nothing else was stopped on.** No tool-surface surprises: `updateObjectSecurity` worked cleanly on process models, unlike the documented HTTP 500 it returns for documents.

---

## Promotion candidates: 1 found; 0 promoted, 1 staged

- **STAGED, gate 1:** *a null default inside a formatter is a fabricated value, not a fallback — `format(index(row, field, 0))` renders a real-looking 0 where the honest answer is "unreadable".* The null default and the formatting are each defensible in isolation; composed, they manufacture data. Measured here on a money column across a security boundary. **Trigger: the next `a!defaultValue`/`index(..., 0)` found inside a formatter or an aggregate.**
- **Application pointer, no promotion needed:** this is the concrete instance of CLAUDE.md §4's "nothing distinguishes absent from invisible unless the screen says so". The rule existed; the screen just wasn't obeying it. Worth citing rather than restating.
- Unchanged: the grouping-not-named-in-output note; guard-vs-grouping; NULL-timestamp rule (promoted 2026-09-23); fixture-vs-process-rows; unused-locals; agent-boolean; process-instance blindness — **reinforced today**, since closing the parked-instances item required Scott's word precisely because a session cannot see instance state; NTZ-as-UTC; chart-type.

*Promotion checkpoint: current through this entry.*
