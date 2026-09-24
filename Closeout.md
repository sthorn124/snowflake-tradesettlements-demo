# Closeout — 2026-09-24 — console presenter preflight; the presenter model made consistent

**Scope.** `SO_demoAdminConsole` v11 → **v12**: a membership preflight ahead of every query, plus the line-232 guard. Then the presenter model — both memberships, everywhere — written into the four documents that contradicted each other. No security change, no membership change, no process model, nothing Snowflake-side.

**Identity.** Dev MCP as `scott.thorn` (member of `SO Supervisors`, so every readback below is full-scope). Persona reads via sail as `alex.analyst` (`~/.sail-alex.analyst`) and `sam.supervisor` (`~/.sail-sam.supervisor`), both live. `test.presenter` **has no sail session anywhere** — see (a).

**Environment.** Clean baseline, verified: no packet run loaded, the 17 P4-VERIFY fixture cases present and re-dated (analyst watchlist rendered live cutoffs `0h 32m` / `1h 47m` and a non-zero critical-window KPI, which is the tell that the ritual ran).

---

## (a) Task 0 — SKIPPED, and why

**`test.presenter` has no sail session on this machine.** `~/.sail-test.presenter` holds no `session.json`, the default `~/.sail` is empty as it should be, and no other `~/.sail-*` directory holds that account. Per CLAUDE.md §2 step 9 the session reports "no live session for `test.presenter`, run the login" and skips the verification — **no fallback to another identity**, and a session never asks for, types or stores a password.

So the platform question Task 0 would have settled — **does a direct query against a record type the account holds no viewer right on THROW, or return empty?** — is still open. The brief said the fix does not depend on it, and it does not: the preflight prevents the query from being issued at all, which is correct under either answer. The discrimination stays a staged candidate with its trigger unchanged.

## (b) The preflight as built

`SO_demoAdminConsole` **v12**, UUID `_a-0000f057-1da8-8000-9c4b-011c48011c48_564828`.

**Structure.** The first evaluated expression in the interface is the membership test; **all twenty query locals moved inside a nested `a!localVariables` that is the value of the `if`'s true branch**, so they are not merely hidden for a misconfigured viewer — they are never declared.

```
a!localVariables(
  /* THE PREFLIGHT. One membership test, evaluated before anything else.
     cons!SO_SUPERVISORS_GROUP already existed and gates the Supervisor page;
     reusing it keeps one definition of "can read the demo data". */
  local!isPresenter: a!isUserMemberOfGroup(
    username: loggedInUser(),
    groups: cons!SO_SUPERVISORS_GROUP
  ),
  if(
    not(local!isPresenter),
    /* ---------- MISCONFIGURED VIEWER: ONE CARD, NOTHING ELSE ---------- */
    a!formLayout( ... ),
    /* ---------- CONFIGURED PRESENTER: THE CONSOLE, UNCHANGED ---------- */
    a!localVariables( ...the twenty query locals, then the v11 body... )
  )
)
```

**No new constant.** `cons!SO_SUPERVISORS_GROUP` (`_a-0001f054-7a62-8000-9c49-011c48011c48_562328`) already existed and already gates the Supervisor site page. Reusing it keeps **one** definition of "can read the demo data" rather than minting a second that can drift from the first.

**A `showWhen` would not have done this job.** It hides output and still evaluates everything behind it — which is precisely the failure the preflight exists to prevent. The nesting is the mechanism; the `if` alone is not enough, because a local declared at the outer level evaluates regardless of which branch is taken.

**The card, verbatim as rendered** (amber, not red: this is a state with exactly one fix, and red on this screen is reserved for a broken environment):

> **Demo Admin**    Settlement Operations
> Signed in as `<account>`
>
> ┌──────────────────────────────────────────────────────────────┐
> **This account can see the admin site but not the demo data.**   `#96590A` STANDARD STRONG
>
> Add it to SO Supervisors in the Admin Console, under Groups, then reload this page.   `#1B2330` STANDARD
>
> Presenting needs both memberships: SO Demo Admins to open this site, SO Supervisors for the data these checks read. GETTING_STARTED.md carries the two lines.   `#6E7885` SMALL
> └──────────────────────────────────────────────────────────────┘

No verdict line, no checklist, no buttons, no status line. The signed-in line is kept deliberately: "this account" is ambiguous without it, and the reader needs to know **which** login is short a group.

## (c) The line-232 guard

Applied regardless of the preflight, per the staged null-default rule — defence in depth, and it costs one `if()`. `local!agentLast` was the sole naked consumer among the twenty query results: it fed `wherecontains` a value that, on a scope-starved read, was not the Boolean list the function expects, producing the whole-page crash `wherecontains [line 232]: Invalid types, can only act on data of the same type (Boolean, eede988b-…)`.

```
local!agentLast: if(
  a!isNullOrEmpty(local!agentEvents),
  null,
  a!localVariables(
    local!idx: wherecontains(true, a!forEach(...)),
    if(a!isNullOrEmpty(local!idx), null, index(local!agentEvents, index(local!idx, 1, 1), null))
  )
),
```

The other nineteen were already shape-safe (aggregations wrapped in `tointeger(a!defaultValue(...))`, or `a!isNullOrEmpty` tests). Enumerated, not assumed.

## (d) Document changes — before and after

**1. `CLAUDE.md:266`** — the clause that licensed the Demo-Admins-only reading.

- *Before:* "…process initiators where they start things; **Reset/Verify and Admin page are Demo Admins only.** Demo users: …"
- *After:* "…process initiators where they start things; the Demo Admin site and its page are gated to **Demo Admins only — a gate on where the console appears, not on what it can read**. A demo presenter therefore holds **both** `SO Demo Admins` (to see the site and to start Load/Reset) **and** `SO Supervisors` (to hold viewer on the record types the console queries, and to give intake full-desk scope); the console preflights the second one and refuses to query without it. Demo users: …"

**2. `CLAUDE.md:405`** — one clarifying sub-bullet added beneath the separate-site bullet, which is unchanged:

> - **Outside the tree controls WHERE THE SITE APPEARS, not what a presenter can read, and the two were conflated until 2026-09-24.** `SO Demo Admins` grants viewer on no record type, so an account holding only that group sees the site and crashes the console whole-page on its first query. A presenter holds **both** groups — `SO Demo Admins` for the site, `SO Supervisors` (which nests under `SO Users`) for the data — and the console's first evaluated expression is an `a!isUserMemberOfGroup` preflight against `cons!SO_SUPERVISORS_GROUP` that renders one instruction card, running zero queries, when it fails.

**3. `TODO.md:25`** — the 🔴 ruling item, closed:

- *Before:* "- [ ] **🔴 RULING FIRST, THEN THE FIX: is a demo presenter Demo-Admins-only, or Demo-Admins-plus-Supervisors?** *Scott.* …"
- *After:* "- ✅ 2026-09-24 — **RULED: a demo presenter is a member of BOTH `SO Demo Admins` and `SO Supervisors`, everywhere, consistently — the Demo-Admins-only reading is dead.** Implemented as a console preflight … and propagated to CLAUDE.md:266, CLAUDE.md:405, GETTING_STARTED and BUILD_PLAN. Original note: …"

**4. `TODO.md:74`** (the brief's `TODO:66`; the line had moved) — closed as ruled **and** implemented, with a correction:

- *Before:* "- [ ] **Presenter must be in SO Supervisors (document or rule)** — *Part E setup doc.* Intake and triage run as the presenter, and SO Trade Predictions is row-secured: a desk-scoped presenter's intake would find only its own desk's stories, silently."
- *After:* "- ✅ 2026-09-24 — **CLOSED as ruled and implemented … now BOTH document and rule.** … **The row-security consequence in the original note was understated:** without `SO Supervisors` the presenter is not in `SO Users` either, so it holds viewer on **no** record type and the console does not render at all — the desk-scoped-intake failure is what an `SO Analysts` presenter would get instead."

**5. `GETTING_STARTED.md:105`** — verified against the ruling and **corrected**, because its stated failure mode was not the measured one. It described the missing-Supervisors failure as desk-scoped intake; the measured failure is earlier and louder.

- *Before:* "They must also be in **SO Supervisors**, or intake reads a desk-scoped set of predictions and silently creates cases for that one desk only."
- *After:* "They must also be in **SO Supervisors**, which nests under SO Users and is where viewer rights on the record types come from: without it the console's readiness queries read record types the account cannot see and **the page does not render at all** (measured 2026-09-24 …; the console now preflights the membership and names the missing group instead of crashing). A presenter in **SO Analysts** rather than SO Supervisors is the subtler failure — the console renders, but intake reads a desk-scoped set of predictions and silently creates cases for that one desk only."

The file's existing note that this is a build-specific paragraph in a template-owned file is left standing.

**6. `BUILD_PLAN.md:10`** — group naming brought to the ruling.

- *Before:* "…; the presenting SC's own account in `SO Demo Admins` for the separate Demo Admin site."
- *After:* "…; the presenting SC's own account in **both** `SO Demo Admins` (which is what makes the separate Demo Admin site appear) **and** `SO Supervisors` (which is what lets the console read the record types and intake run across all desks) — ruled 2026-09-24."

Plus a Phase 5 completion bullet recording v12.

**7. The site grant, logged — and it reads back richer than "Scott added a group".** `getObjectSecurity` on `SO_DemoAdmin` (`14c4f1a3-…`):

| role | groups |
|---|---|
| administrator | SO Administrators |
| viewer | SO Users, SO Supervisors, SO Analysts, **SO Demo Admins** (`_e-0000f057-1d8f-…_5425`) |

Scott's manual addition is **present and is the correct permanent state.** The page gate is separate and also correct: `visibilityExpr` = `a!isUserMemberOfGroup(username: loggedInUser(), groups: cons!SO_DEMO_ADMINS_GROUP)` — note the keyword is `groups`, not the silently-false `groupsToCheck` the supplemental warns about.

**The build-time gap, named:** the 2026-09-09 build recorded the **page** gate and never checked the **site** grant. They are two different layers and only one was verified. Without the site grant a Demo-Admins-only account cannot resolve the site at all; with it, the account resolves the site and the page expression decides entry. That two-layer structure is now measured from both sides — see (e).

## (e) Verification

**1. As `test.presenter` via sail — BLOCKED, not done.** No session exists. Handed to Scott in (f). This is the one verification item the session could not run, and the instruction card's live behaviour is therefore unproven **as that account**; it is proven as a render (item 2b).

**2. As the design account via `testInterface`.**
- **Configured branch, clean data state:** the **full console, unchanged**, `error: null`, **durationMs 613**. Byte-identical readback after save; `validateDesignObject` → `hasErrors: false`.
- **Misconfigured branch:** exercised through a throwaway copy (`SO_zzPreflightProbe`) with `local!isPresenter: false` forced, because the design account is a supervisor and cannot otherwise reach that branch. Rendered **the instruction card and nothing else** — no verdict, no checklist, no buttons — `error: null`, **durationMs 19**.
- **The 19 ms is the evidence, not a side note.** Twenty queries — nine one-row reachability probes plus aggregations over 50,000-row Snowflake tables — cannot run in 19 ms; the configured branch takes 613 ms doing exactly that. The ~32× gap is what demonstrates the brief's requirement that **zero record queries evaluate** for a misconfigured viewer. Structure alone would not have shown it; a `showWhen` build would have rendered the same card at ~613 ms.
- Probe deleted in the same session, verified by absence (HTTP 404 on readback).
- **Loaded data state: NOT rendered.** Loading a packet is a data change beyond the brief's permitted scope, and the Load click is Scott's in (f). The argument that it is unaffected is structural — no expression inside the configured branch changed, and the readback is byte-identical — but that is reasoning, not a render, and it is listed here as unverified rather than folded into the pass.

**3. As `alex.analyst` and `sam.supervisor` via sail — no change, page gate intact.**
- `pages settlement-ops-admin` as each: *"the site resolved (\"Settlement Ops — Demo Admin\") but no pages are visible"* — zero pages, both accounts. Neither ever reaches the console.
- `pages settlement-ops`: analyst 2 pages (Watchlist, Cases), supervisor 3 (+ Supervisor). Unchanged.
- Screens rendered clean as each persona — watchlist KPIs, six-row grid with live cutoffs; supervisor runway, desk grid, reason bars, all present, no errors.
- **Worth stating because it confirms the model rather than merely passing:** `sam.supervisor` **would pass the new preflight** and is still correctly excluded — by the page gate. The two gates are independent and both are load-bearing, which is exactly what "both memberships" means.

**4. Object checks.** `validateDesignObject` clean; readback byte-identical to what was sent; v12.

**5. Not verified.** The `test.presenter` live path (item 1); the configured branch in the loaded data state (item 2); and — unchanged from before this session — whether a scope-starved record query throws or returns empty, which Task 0 would have settled.

## (f) Hand-off to Scott

1. **Before adding the group** — if you want the card seen live rather than as a render: run the sail login for `test.presenter` (`~/.sail-test.presenter`), open `settlement-ops-admin`, and confirm the instruction card appears with no crash. This is verification item 1, currently blocked.
2. **Add `test.presenter` to `SO Supervisors`** — Admin Console → Groups. (No membership change was made from the session, by constraint.)
3. **Reload the admin site.** Expect the **full console**, verdict line green: `Ready · data 50,000/50,000 · 9/9 connections · agent OK`.
4. **Press Load.** This is the original GATE D click. Expect the procedure's message verbatim: `OK run=DEMO trades=15 predictions=15 high_or_critical=3`, then three cases appearing over roughly the next 45 seconds as intake and triage run in the background.
5. **Press Reset after.** Expect the Appian delete first, then the Snowflake cleanup, and the console returning to the clean-baseline verdict. Both buttons now run as `test.presenter` — which is the real thing being tested at steps 4 and 5: the process models carry `initiator: [SO Demo Admins]`, and the record reads behind them need the Supervisors membership from step 2.

---

## Promotion candidates

**2 found; 0 promoted, 2 staged.**

1. **STAGED (gate 1 — one observation): a `showWhen` hides output; only nesting the declaration prevents evaluation.** Trap: gating a screen with `showWhen` on a section leaves every local behind it evaluating, so a scope-starved viewer still issues every query and still crashes. Working form: make the guarded content the value of an `if` branch and declare its locals in a nested `a!localVariables` inside that branch; verify by render duration, not by structure. *Trigger: the next interface that gates a query-heavy region on identity or state.* Survives the noun test; needs a second measurement before promotion.
2. **STAGED, carried unchanged: does a record query under an account with no viewer right THROW or return EMPTY?** Task 0's question, unrun for want of a session. *Trigger: the first session in which a persona holding no viewer right on a record type has a live sail session.*

**Promotion checkpoint: current through the 2026-09-24 presenter-preflight entry.**

## TODO changes

Closed 2: the 🔴 presenter-model ruling (TODO:25) and "Presenter must be in SO Supervisors" (TODO:74). Added 0 — the two open threads from this session are the promotion candidates above, both with triggers, and the `test.presenter` live check, which is Scott's hand-off step 1 rather than a parked item.

## BUILD_PLAN changes

Phase 5: added the v12 presenter-preflight completion bullet; line 10 (Personas) corrected to both groups.
