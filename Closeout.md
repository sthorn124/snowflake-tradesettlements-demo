# Closeout — 2026-09-24 — INVESTIGATION: demo console crashes for a Demo-Admins-only identity

*Scope and identity:* **Observation only. No object was changed, no security was changed, nothing was fixed.** Dev MCP as `scott.thorn` (SO Supervisors — full scope) for design-surface reads and one contrast render. The only filesystem change is an empty `~/.sail-test.presenter` directory, created per harness convention so the operator's login lands in the right place.

**Blocked, stated up front:** items 2 and 3 asked me to read as `test.presenter`. **There is no sail session for that account and I cannot create one** — a login needs a password, which a session never asks for, types or stores (CLAUDE.md §6). Per §2 step 9 I report "no live session for `test.presenter`, run the login" and do not fall back to another identity. Everything below is either design-surface fact, a design-account render, or clearly-labelled inference. **The one measurement that would settle the ranked causes is the persona login**, and it is the first thing the fix session should have.

---

## 0. Environment, and Scott's site-security change

**Baseline verified and unaffected by the security edit.** Console as the design account: `Ready · data 50,000/50,000 · 9/9 connections · agent OK`, **Demo trades 0 · Demo cases 0 · Built-in test cases 17 · Case comments 12 · Audit rows 14**, `Status: No demo data loaded.`, Reset `disabled: true`. No demo is loaded; the site change touched security only.

**Finding 1 — the site's security, as it now reads** (`getObjectSecurity` on `14c4f1a3-e77d-4d37-b971-5be0e803736b`):

| role | groups |
|---|---|
| administrator | SO Administrators (`53dbfcbc-…`) |
| editor | — |
| **viewer** | SO Users (`622bcff2-…`), SO Supervisors (`_e-…5309`), SO Analysts (`_e-…5311`), **SO Demo Admins (`_e-0000f057-1d8f-8000-9b9b-01075c01075c_5425`)** |

**What it read before is NOT determinable from the tool surface.** `listObjectVersions` returns a single version, `savedBy scott.thorn@appian.com`, `savedOn 2026-09-24T16:09:02Z` — about ninety seconds before my first read — and there is no earlier snapshot to retrieve. **Inference, flagged:** the other three viewer groups are exactly the application's default security trio, and the 2026-09-09 build-log entry records only that the *page* was gated on `cons!SO_DEMO_ADMINS_GROUP` — it never records the *site object's* role map. So the site was almost certainly created with app-default security and SO Demo Admins was never on it, which is precisely the gap Scott closed.

**The shape of that gap is worth naming:** the page-level `visibilityExpr` gates on the Demo Admins group, but the site object's viewer list did not include it. A page gate controls what you see *once you are in the site*; it cannot let you *into* it. The build log recorded the gate and not the grant, so the check that was run at build time confirmed the wrong half.

---

## 1. Line 232 and its inputs

Deployed `SO_demoAdminConsole` v11, lines 226–240 verbatim (field references elided for width where marked `…`):

```
226  local!agentEvents: a!queryRecordType(
227    recordType: 'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History',
228    fields: { …timestamp, …user, …relationships.{b87d38c6}eventType.fields.{fd5aa5de}eventName },
229    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: …timestamp, ascending: false))
230  ).data,
231  local!agentLast: a!localVariables(
232    local!idx: wherecontains(true, a!forEach(
233      items: local!agentEvents,
234      expression: and(
235        a!isNullOrEmpty(index(fv!item, '…{c4acbfe1-…}user', null)),
236        contains({ "Agent Triage Complete", "Straight-Through Resolution", "Escalated" },
237          a!defaultValue(index(fv!item, '…eventType.fields.{fd5aa5de-…}eventName', ""), ""))
238      ))),
239    if(a!isNullOrEmpty(local!idx), null, index(local!agentEvents, index(local!idx, 1, 1), null))
240  ),
```

- **What `wherecontains` compares:** the literal `true` (Boolean) against the value returned by the `a!forEach` on lines 232–238. In a healthy render that forEach returns a list of Booleans, one per event row.
- **Which query feeds it:** `local!agentEvents`, lines 226–230 — and note it is consumed on line 233 **with no `a!isNullOrEmpty` guard and no `if` wrapper**.
- **The UUID:** `eede988b-5576-4daa-a49c-fa962d90b16b` is the record type **SO Settlement Case Event History** (confirmed against `listRecordTypes` for the application, and self-evident from the field references inside the same query).

**The diagnostic content of the error message.** `Invalid types, can only act on data of the same type (Boolean, eede988b-…)` names the two operand types. The second is not `List of Variant`, not `Null`, not `Text` — it is **the record type itself**. So at the moment `wherecontains` ran, its second argument was record-typed data from SO Settlement Case Event History, i.e. **the forEach did not yield Booleans**. That is the fact the fix has to explain; it is stronger evidence than "the query came back empty", because an empty list would not carry that type.

---

## 2. Reproduce as the persona — BLOCKED; design-account contrast recorded

- **As `test.presenter`:** not run. No session exists, and creating one requires a password. `~/.sail-test.presenter` created and left empty.
- **As `scott.thorn` via `testInterface`:** renders completely, **`diagnostics.error: null`**, 1,305 ms — verdict line, all seven Details lines, both buttons, Reset correctly `disabled: true`.

**The delta is therefore between Scott's reported browser error and a clean design-account render**, which is exactly the shape CLAUDE.md §4 warns about: "a design-account render proves nothing about a persona". I am treating Scott's quoted error as the persona-side evidence; I have not reproduced it myself and do not claim to have.

---

## 3. Identity shape — what `test.presenter` can read

**I could not read as the persona, so this table is CONFIGURATION, not observation.** It is `getObjectSecurity` on each record type the console touches. It settles "does this identity hold a viewer right" decisively; it does **not** settle "does an unreadable record type return empty or throw", which is the question that discriminates the two candidate causes below.

`test.presenter` ∈ SO Demo Admins only. SO Demo Admins sits **outside** the SO Users tree by design (CLAUDE.md:405).

| # | record type | viewer groups | Demo Admins a viewer? |
|---|---|---|---|
| 1 | SO Trade `8539c3b7` | SO Users | **No** |
| 2 | SO Trade Predictions `b1967741` | SO Users | **No** |
| 3 | SO Counterparty `caca5336` | SO Users | **No** |
| 4 | SO Instrument `553867ce` | SO Users | **No** |
| 5 | SO Settlement History `c80aeca9` | SO Users | **No** |
| 6 | SO Settlement Case `09405a10` | SO Users | **No** |
| 7 | SO Case Comment `c8cdbb02` | SO Users, SO Supervisors, SO Analysts | **No** (both extras nest inside SO Users) |
| 8 | **SO Settlement Case Event History `eede988b`** | SO Users | **No** ← the record type in the error |
| 9 | SO Settlement Case Event Type `beb76989` | SO Users | **No** |

**Uniform: SO Demo Admins holds no viewer right on any of the nine record types the console queries.** Every record type carries the application's default map — `administrator: SO Administrators`, `viewer: SO Users` — and the Demo Admins group was deliberately built outside that tree.

So the console asks a Demo-Admins-only identity to run **twenty queries against nine record types it cannot read**, including the nine "connection" probes whose entire purpose is to prove those record types are reachable. Nothing was widened to establish this; it is read from the security role maps.

**Classified visible / empty / error:** unavailable without the login. The honest entry for all nine rows today is **"no viewer right; observed behaviour not yet measured"**.

---

## 4. The class — every console query and what its consumer assumes

Twenty queries. The column that matters is the last one.

| # | local (line) | record type | downstream consumer | shape-safe? |
|---|---|---|---|---|
| 1 | `tradeBaseline` (97) | SO Trade | `tointeger(a!defaultValue(index(index(agg,1,null),"n",0),0))` | ✅ aggregation, double-defaulted |
| 2 | `tradeReserved` (106) | SO Trade | same | ✅ |
| 3 | `predBaseline` (115) | SO Trade Predictions | same | ✅ |
| 4 | `allCases` (129) | SO Settlement Case | `fixtureCases` / `otherCases` both open `if(a!isNullOrEmpty(local!allCases), 0, …)` | ✅ explicitly guarded |
| 5 | `commentCount` (143) | SO Case Comment | aggregation, double-defaulted | ✅ |
| 6 | `eventCount` (154) | SO Settlement Case Event History | aggregation, double-defaulted | ✅ |
| 7–15 | `pTrade` … `pEventType` (169–204) | all nine | `a!map(name:…, ok: not(a!isNullOrEmpty(local!q)))` | ✅ — and this is the *designed* empty-means-failed path |
| **16** | **`agentEvents` (226)** | **SO Settlement Case Event History** | **`wherecontains(true, a!forEach(items: local!agentEvents, …))` — line 232** | ❌ **NO GUARD** |
| 17 | `loadStamp` (259) | SO Trade Predictions | `index(index(query,1,null), field, null)` | ✅ |
| 18 | `resetRows` (326) | SO Settlement Case | `resetCaseIds` opens `if(a!isNullOrEmpty(local!resetRows), {}, …)`; `count()` is null-safe | ✅ |
| 19 | `resetCommentCount` (338) | SO Case Comment | `if(a!isNullOrEmpty(local!resetCaseIds), 0, …)` | ✅ |
| 20 | `resetEventCount` (351) | SO Settlement Case Event History | same | ✅ |

**Answer to "is line 232 the only landmine or merely the first": on shape, it is the only one.** Nineteen of twenty results are either aggregated-and-defaulted or opened with an explicit `a!isNullOrEmpty` guard. `local!agentEvents` is the single query whose result is fed straight into an iterator and a type-sensitive comparison without a guard, and it is the one that blew up.

**That conclusion holds only if the failure mode is shape.** If an unreadable record type *throws* rather than returning empty, then the guards on the other nineteen are irrelevant — a throw is not caught by `a!isNullOrEmpty` — and line 232 is simply the first expression to touch a poisoned value, not the only vulnerable one. **This is the crux, and it is exactly what the persona login resolves.**

---

## 5. The intended viewer model, as documented — and it contradicts itself

- **CLAUDE.md:266** — "Business groups Viewer; process initiators where they start things; **Reset/Verify and Admin page are Demo Admins only**."
- **CLAUDE.md:405** — "`SO_DemoAdmin` is a SEPARATE SITE … gated to **SO Demo Admins**, a group deliberately **outside the SO Users tree**. An SC running the demo is not a persona … Membership is the presenting SC's own account — never `alex.analyst` or `sam.supervisor`."
- **BUILD_PLAN:10** — "the presenting SC's own account in `SO Demo Admins` for the separate Demo Admin site."
- **TODO:66** — "**Presenter must be in SO Supervisors (document or rule)** — *Part E setup doc.* Intake and triage run as the presenter, and SO Trade Predictions is row-secured: a desk-scoped presenter's intake would find only its own desk's stories, silently."
- **GETTING_STARTED.md**, added 2026-09-24 — a presenter "must be in **SO Demo Admins** … and also in **SO Supervisors**, or intake reads a desk-scoped set of predictions and silently creates cases for that one desk only."

**These do not agree, and the disagreement is the root of this incident.** Two of them say Demo-Admins-only; two say Demo Admins *plus* SO Supervisors. The "outside the tree" decision was made for one specific reason — so the reset tooling never appears as a tab beside the watchlist — and that reason is about **where the site shows up**, not about **what data the presenter can read**. Nothing in the documentation ever reasoned about a presenter with no data scope; the console was built and verified only ever as `scott.thorn`, who is in SO Supervisors.

`test.presenter` is the first identity that matches the letter of "Demo Admins only" — and it is a configuration the design never actually endorsed for a *working* presenter, while CLAUDE.md:266's phrasing plainly invites it.

**So the ruling the fix needs is not "which line" but "who is this screen for":** a presenter who is also a Supervisor (in which case the fix is documentation plus possibly one guard), or a genuinely Demo-Admins-only operator (in which case the console needs either grants on nine record types or a reduced-visibility rendering that does not pretend to check data it cannot see).

---

## Two ranked candidate causes — inference

**Candidate 1 — most likely: an unreadable record type returns a degenerate non-Boolean result, and line 232 is the one consumer with no guard.**
The error names the second operand's type as the record type itself, which is what you would expect if the `a!forEach` yielded rows rather than Booleans — for instance because the projected fields could not be resolved for this identity and the row passed through unprojected. Every other consumer either aggregates (so a degenerate result collapses to a defaulted 0) or opens with `a!isNullOrEmpty`. On this reading the console is one guard away from rendering for a Demo-Admins-only identity, though what it would then *show* is nine failed connection probes and zeroed counts — accurate, and useless.

**Candidate 2 — plausible and more expensive: the read is refused rather than empty, so the failure is access, not shape.**
Under CLAUDE.md §4 and supplemental §5, a row-secured read normally returns *empty and silent*; but that rule is about **row**-level scoping for an identity that can read the record type at all. `test.presenter` has no viewer right on the **object**, which is a different boundary and may well raise rather than return. If so, line 232 is merely where the poison first touches a type-sensitive function, guarding it moves the error downstream, and the nineteen "safe" consumers are not safe at all.

**The two are distinguished by one cheap measurement**: log `test.presenter` in and render the console; if the nine probes come back as nine red "no connection" lines and the crash is gone once line 232 is guarded, Candidate 1 holds. If any query raises, Candidate 2 holds.

## Smallest coherent fix scope — inference, and it is a ruling before it is a code change

**If Candidate 1 holds, the smallest coherent scope is still larger than line 232.** Guarding that one line stops the crash, but it buys a console that renders "Not ready · 0/9 connections · no record of the AI agent running" in red to a presenter whose environment is in fact perfectly healthy — a readiness screen that lies in the alarming direction, which CLAUDE.md's own three-state rule was written to prevent ("a checklist that paints normal states red teaches its reader to ignore red"). So the coherent unit of work is *the panel*, not the line: either SO Demo Admins gains viewer on the nine record types (making the checks meaningful), or the console detects that it cannot read them and renders a reduced view that says so plainly instead of reporting nine failures. **If Candidate 2 holds, the line-level fix is not even available** and the scope is necessarily the grants or the reduced rendering.

**Either way the ruling comes first:** decide whether a demo presenter is Demo-Admins-only or Demo-Admins-plus-Supervisors, because that single decision picks the fix and also resolves the documentation contradiction in item 5. My own reading — flagged as opinion, not finding — is that the cheapest durable answer is to make the presenter's required groups explicit and consistent everywhere, since intake already needs SO Supervisors for reasons that have nothing to do with this crash (TODO:66), and a presenter who cannot read the data cannot sanity-check the demo they are about to give.

---

## Not verified

The persona render, the visible/empty/error classification, and therefore the discrimination between the two candidates. All three need one operator login. No fixes were made, no objects changed, no security altered, and nothing was widened to find any of the above.
