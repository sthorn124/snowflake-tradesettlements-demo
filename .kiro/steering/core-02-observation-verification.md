---
inclusion: always
---

# Operating core — §3 Observation, §4 Verification

## 3. Observation precedes fixes

- **Never guess before reading evidence.** Before theorising about a defect, read the deployed object, the stored expression (read back, not what was sent), the process instance's variables, the node's actual configuration, or the row itself. The reported symptom is frequently not the defect; the deployed source frequently is not what the last session believed it deployed.
- **Reproduce before changing.** Reproduce the failure, change one thing, re-measure. A control on data known to be good, or on a path known to work, is what isolates a cause; without it a fix is a guess that happened to coincide.
- **A single wrong-side reading is one draw, not a verdict.** Replicate before acting; an apparent regression has been measured as variance on a held-constant specimen.
- **A negative capability claim names its evidence** — "tried here, failed, here is the error" — never "the docs do not mention it". A capability is present if something on the instance uses it; find the working example and copy its configuration before concluding anything cannot be done.
- **Stop and report rather than improvise** when a capability is missing, when an input contract cannot be read (an agent's declared input names, a node's parameter names), or when the only next step is guessing spellings. Reporting a blocker is a complete outcome; a workaround invented under uncertainty is not.
- **Read the docs, then the instance, in that order — and the instance wins.** Docs establish what a parameter is; only the instance establishes what this environment does.

## 4. Verification doctrine

- **Writes are verified by existence and readback, never by operation status.** `COMPLETED`, HTTP 200, `error: null`, a green save and "valid" prove nothing happened. A write path is proven by exercising the actual control and counting persisted rows per record type; a delete is proven by absence (404 / zero rows) read as a full-scope account; a document is proven by existence and byte size. Direct payload inserts validate shape and bypass the control's accumulator, so they are not verification of the control.
- **Object validator over `validateExpression`.** `validateExpression` evaluates both branches of an `if`, is not a keyword check, and accepts parameters the object validator rejects; the rendered tree lists attributes that are not settable. Only the object validator (`validateDesignObject`, `createInterface`/`updateInterface`, `createExpressionRule`) is authoritative for interfaces and rules, and an interface counts as done only at `diagnostics.error: null` through `testInterface`.
- **Content, state, and behaviour are verified from the terminal, per persona, through sail; geometry and paint only in the browser.**
  - **What sail verifies.** The sail CLI (`reference/toolchain.md` §12) reads and drives published pages as whichever account its session holds [S5, S10–S13, S15, S16, S21]:
    - content, in page order;
    - field state: required, invalid, disabled, read-only;
    - visibility and conditionally rendered content, such as status-driven bands;
    - navigation through record links, tabs, related actions, and process launches;
    - behaviour: cascades, validation, and submits.
  - **Read the YAML, not just the listing.** The listing sail prints is a summary. Full grid rows, tag values, milestone details, and a changed sort order exist only in its stored YAML [S7].
  - **What sail cannot verify.** The YAML carries style values (hex colours, size and style enums) and the requested layout parameters. It carries nothing computed: no pixel sizes, positions, line breaks, or truncation [S8]. So wrapping, truncation, overflow, alignment, card heights, focus, hover, link colour against the site accent, chart drawing, and branding are never sail-verifiable. The Dev MCP's tree and harness renders cannot verify them either: they prove structure (component order, colour values, requested widths, error-free evaluation) and carry no geometry.
  - **Reporting.** Every UI summary separates terminal-verified facts, each with the account it ran as, from browser-only ones. It never describes a layout as confirmed on terminal evidence. Where a parameter's whole job is geometry, verify the parameter's value, not the shape of the content it governs.
- **A write driven through sail is verified by a fresh read of its target, never by the submit output.**
  - The submit prints the page as it was before the form opened, so the old value is still on screen after a successful write [S13].
  - The reload its own note suggests, `load --fresh`, fetches the site's default page, not the record [S13].
  - Verify by navigating to the specific page or record afterwards and, where the app has one, by its own attribution: an activity entry naming the acting user [S13]. Where the submit started a process, also read the instance's `initiator` through the Dev MCP (§6).
  - A submit that validation blocked exits 0 with `✓ Interacted` [S12]. Read the ⚠ lines and the field states, never the exit code.
- **Build prompts may end with persona-scoped verification steps** — "as `<persona>` via sail: these pages resolve, this band renders, this action appears only when …" — instead of flagging those facts for browser verification; each of those three kinds of fact was read from the terminal as a persona [S4, S5, S10]. The session runs them against the operator's persona sessions and reports each result with its account. Geometry still goes to the browser checklist.
- **Readbacks must state the identity and scope they ran under, or they prove nothing.** Record-level security filters every read silently — `listRecordData`, `a!queryRecordType`, counts, min and max, related-record traversals — with no marker distinguishing absent from invisible. Write the scope into the readback ("as `<user>`, member of `<groups>`"). Before concluding rows are absent, re-read as a member of every scope or prove absence another way. A design-account render proves nothing about a persona: on one site, the design account and a persona disagreed in both directions on pages, KPI values, masked values, and available actions [S32].
- **Readbacks both over-report and under-report schema; measure behaviour, never trust metadata.** A column width has read back wider than the physical column (after an ALTER that changed nothing and returned 200) and narrower than it (a 4000-character column reported as 255). Document metadata reports an extension the runtime resolves differently. A create response has omitted relationships that exist. An integration reads back with function names that do not match what runs, and a boolean set to `false` reads back `null`. The rule is the same in every case: probe through the path production uses — a write of the real length through the real Write Records node, a runtime `document()` call, one live integration call — and treat a readback as a claim to be tested.
- **Visibility, security, and document access are verified behaviourally**, as a member and as a non-member: through sail as each persona for pages, content, values, and actions [S32], and in the browser for document access, which sail cannot reach [S9]. Nothing automated distinguishes "hidden by rule" from "hidden by a broken rule", and a visibility expression that throws hides its target without reporting.
- **A hidden branch is unevaluated, so a clean render proves nothing about it.** Anything behind `showWhen: false`, an inactive wizard step, a toggled section, or a view-switch local runs untested until it is revealed. Flip the default in a probe copy, render, restore, verify the restored source byte-identical, and re-render.
- **Gates are proven by break-test, not by a happy path.** Force the upstream failure and confirm the guarded node did not fire; a passing happy path says nothing about a gate.
- **A generated harness goes stale silently and positively.** Regenerate it in the same change that edits its source, and before trusting a harness render check that one string you know you changed appears in it.
- **Every summary lists what was NOT verified and why**, with the browser checklist the human can run for what stays browser-only — steps, personas, expected strings. Partial runs are reported as partial, never as a path exercised.
- **Verification ceremony scope:** these are build-time and change-time rules. Routine operation of a working build needs no readback, no row count, no wrapper; ceremony retires with the defect it was built for.
