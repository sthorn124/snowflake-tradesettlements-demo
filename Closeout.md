# Closeout — 2026-09-22 — Deterministic escalation policy + console simplified to one fixed run

Two closing fixes for Phase 5. Story 02 now escalates because the process computes a breached window, not because the agent happened to flag it; and the console has nothing left to type. Environment verified clean before work and left clean after: 17 fixture cases, 12 comments, 14 audit rows, 0 demo trades.

## (a) Changes, with readback

**`SO_triageCase`** (`0000f04e-ff8f-8000-2381-7f0000014e7a`) — modified exactly as ruled, nothing else touched:

- **Three new process variables:** `lagHrs`, `hoursRemaining` (both Decimal), `windowBreached` (Boolean).
- **Node 11** (unpack) gained two reads, both self-contained: broker confirmation lag through the case→trade relationship, and hours-to-cutoff through **`SO_cutoffDisplay`'s** signed `hoursRemaining` — the measured clock rule reused rather than re-derived.
- **New node 13, "Escalation policy: window breached?"**, sits between node 11 and the status write: `lagHrs > 0 and hoursRemaining <= lagHrs`. It is a separate node so both inputs are committed before the comparison reads them.
- **Node 12 "Route"** — the escalate condition is now `windowBreached OR counterparty_default OR the agent's escalate flag`, evaluated first, so a breach outranks straight-through and the analyst lane by the XOR's first-match ordering. The `counterparty_default` override is unchanged. Straight-through and analyst conditions are untouched.
- **Node 23 "ESC: Event Escalated"** now composes three branches — breach, reason override, agent flag — and **every one renders the fail reason through `SO_failReasonDisplay`, lower-cased into the sentence**, closing the standing TODO.

Readback: each `updateProcessModelNode` returned the node as sent; `validateDesignObject` → `hasErrors: false`.

**`SO_demoAdminConsole`** (`…_564828`, v5 → v8) and new constant **`SO_DEMO_RUN_NAME`** (TEXT, `DEMO`, `…_571667`):

- Both run-name text fields removed; both buttons pass the constant. Panel 2 is **Load the demo**, panel 3 is **Reset the demo**.
- **Status line above the buttons**, derived from panel 1's existing queries — no new state: `No demo data loaded.` / `Demo loaded — 15 trades, 3 cases.`, with the existing in-progress copy after a Load press.
- **Panel 1 legend:** "green checks = ready · grey dots are reference counts, not problems · nothing here changes anything"; the top line now reads "You need nothing but this page. The demo run is called DEMO."
- **Snowflake message labelled and demoted:** prefixed "Snowflake's response:" and rendered SMALL muted on success; full prominence (STANDARD, ink, bold) on refused or failed.
- **Grammar:** "Will delete 1 case" — and the same bug was found live in panel 1's leftover line ("1 cases from run DEMO") and fixed too.
- Run-name upper-casing removed as pointless with a single literal; the concept card now explains the fixed name and its consequence.

Readback: `validateDesignObject` → `hasErrors: false`; both states rendered (below).

**Unchanged, as required:** `SO_intakeRun`, `SO_intakePlan`, `SO_createTriageCase`, both integrations, the connected system, everything Snowflake-side.

## (b) Break-test results, quoted

Six throwaway cases created, triaged live, read back, deleted. Every quoted value is from `testProcessModel` output or a row readback.

**1. Breached window, mid score → Escalated.** Case 61, `TRD049998`, lag 15.74h, cutoff +2h.
```
lagHrs: 15.74   hoursRemaining: 1.97   windowBreached: true   confidence: 0.40
status: Escalated
```
Event 146, verbatim:
> "Escalated by policy: funding gap — broker confirmation lag 15.7h against 1.9h remaining, so the remediation cannot complete inside the window. Agent confidence 0.40; the breached window decides this case whatever the score."

Note the fail reason reads **"funding gap"**, not `funding_gap` — the display rule, lower-cased into the sentence.

**2. Non-breached, mid score → Pending Analyst, unchanged.** Case 65, `TRD026800` (Vanguard Prime, high tier, 11.8M EUR), lag 10.24h, cutoff +14h.
```
lagHrs: 10.24   hoursRemaining: 14.00   windowBreached: false   confidence: 0.65
status: Pending Analyst
```
Event 154: "Referred to analyst: confidence 0.65 below threshold 0.80 | proposed Arrange cover borrow / partial release".

**3. Non-breached, high score → straight-through, unchanged.** Case 63, `TRD049996`, lag 0.5h, cutoff +10h.
```
lagHrs: 0.5   hoursRemaining: 9.95   windowBreached: false   confidence: 0.90
status: Resolved - Straight Through   disposition: Settled - Corrected
```
(Case 62 also landed here at 0.87 — it was meant to be the mid-score test, but the agent scored it high; case 65 was added to cover the analyst lane.)

**4. `counterparty_default` → escalates on reason, unchanged path.** Case 64, `TRD049997`, not breached, confidence 0.92.
```
windowBreached: false   confidence: 0.92   status: Escalated
```
Event 152, verbatim:
> "Escalated by policy: counterparty default requires a human credit decision; straight-through not permitted for this reason."

**Residue:** all six deleted; cases back to 52, comments to 52, events to 124 — the exact pre-session baseline, cascade confirmed again.

**What I could not isolate, stated plainly.** I tried twice (cases 61 and 66) to prove the policy overriding a *high* score on a breached window. Both times the agent set `escalate: true` itself — with a blown window it reliably does. So precedence over straight-through rests on the gateway's first-match ordering, visible in the readback, not on a measured case. The stochasticity that caused this work shows up in the other direction: story 02 twice produced the same score and different lanes.

## (c) P4-VERIFY dead code removed

The name is now a constant that can never equal `P4-VERIFY`, so three things on the console were unreachable and were deleted:

1. the `local!simProtected` local and panel 2's red "that's the built-in test data's name" warning;
2. the `local!isProtected` local and the protected branch of the delete preview;
3. the `P4-VERIFY` short-circuit inside the `resetRows` query, which returned `{}` for the fixture name.

**Still in force, untouched:** both process models keep their own `P4-VERIFY` guard, and the Snowflake procedures keep theirs. Nothing that actually protects the fixtures was removed — only the console's now-unreachable copy of it. `ri!sessionPrefill` is left declared but unused, so the site page's configuration does not have to change.

## (d) Your browser pass

1. Open the Demo Admin site. Panel 1 all green; status line reads **"No demo data loaded."**; **Reset the demo** is greyed out.
2. Press **Load the demo**. Expect "Feed loaded", then in small grey type: `Snowflake's response: OK run=DEMO trades=15 predictions=15 high_or_critical=3`.
3. Reload after ~2 minutes. Status line should read **"Demo loaded — 15 trades, 3 cases."**
4. Watchlist as `sam.supervisor`: exactly three cases — 01 **Awaiting review** ~62, 02 **Escalated**, 03 **Resolved · straight through**.
5. Open case 02's event history. Expect the escalation line to state the arithmetic: broker confirmation lag ~26.1h against the hours remaining, "the breached window decides this case whatever the score", with the reason reading "funding gap".
6. As `alex.analyst` (EQ_FLOW): all three stories are EQ_FLOW, so the same three cases appear; confirm no other desk's work is visible.
7. Press **Reset the demo**. Expect "Cleaned up", `Snowflake's response: OK run=DEMO trades_deleted=15 predictions_deleted=15`, "Appian was: 3 cases · 3 comments · 9 audit rows", "Appian now: 0 · 0 · 0".
8. Reload: panel 1 back to demo-run 0, leftover 0, built-in 17, comments 12, audit 14; status line back to "No demo data loaded."; Reset greyed out again.

**Browser-only checks (geometry and paint, which no render can settle):** where the status line sits relative to the button and whether it reads as a heading or a caption; whether the demoted "Snowflake's response:" line is legible at SMALL grey or too quiet; whether the panel-3 preview line wraps at your window width; and the greyed-out Reset button's contrast.

## (e) TODO / BUILD_LOG / packet-spec updates

- **packet-spec §5, story 2** now says it escalates **by policy**, names the mechanism, and records that two runs at the same score routed differently.
- **CLAUDE.md business rules** gained the policy as a standing rule, including why it is not left to the agent.
- **BUILD_PLAN**: console wiring closed as simplified; the escalation policy added as a completed item; Part C still ahead.
- **TODO**: story-02 ruling closed. Added — the fixed name removes multi-SC concurrency (decide before another SC takes the asset); no integration test screen exists, so REFUSED is exercised from the integration object; and a stale throwaway interface from an earlier session, `SO_zz_probeQuery`, which I did **not** delete because §12 says another session's throwaway goes on the owner's word.
- **BUILD_LOG**: full entry with the quoted break-tests and the readbacks.

## Verified / not verified

**Verified** (Dev MCP as `scott.thorn`, SO Supervisors, full scope): environment clean before and after; the four lanes by live triage and row readback; the escalation event text; `validateDesignObject` clean on both changed objects; console rendered in both states with `diagnostics.error: null` — no-data (status line, Reset disabled, no text fields) and loaded (status line, "Will delete 1 case", Reset enabled).

**Not verified:**
- The console's loaded state was rendered with a throwaway case, **not** a real Snowflake load — reaching the true loaded state needs the integrations, which this session does not call.
- Everything geometric, listed in (d).
- **Canon deviation, deliberate and disclosed:** I did not run the P4-VERIFY re-date ritual before rendering the console. The ritual exists so time-anchored fixtures do not render as a book past cutoff; the admin console shows counts only and no cutoff-derived value. Flag it if you would rather it ran unconditionally.
- The two parked intake instances from 2026-09-22 are still `ACTIVE` and still not cancellable over the Dev MCP.

## Promotion

**1 candidate, promoted to CLAUDE.md** (project rule, not portable): escalation for a breached window is a process-layer policy, not an agent judgment. It fails the supplemental's noun test — it is about this build's triage lanes — but it is exactly the kind of ruling CLAUDE.md exists to hold.

The general form behind it — *a demo beat that must land cannot depend on a model's boolean; compute it in the process from data the model also sees* — is **staged, not promoted**: it is method rather than platform, and one project's experience. *Trigger: the next build that wires an agent's flag to a branch.*

Carried forward unchanged: the Dev MCP's blindness to process instances stays staged; NTZ-as-UTC and chart-type stay staged.
