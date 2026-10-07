# Closeout — 2026-10-07 — migrated to the Kiro method

**Scope.** Maintenance only, run from the claude.ai Project with push access to this repo, following `maintenance/migrate-from-claude-code.md` (Kiro template `appian-fs-sc/appian-devmcp-method-kiro`, commit `eda5386`). No Dev MCP call, no object changed, no data touched. The last build session remains 2026-09-24 (chip labels become natural-language questions; `SO_supervisorCommand` v11, `SO_caseDetail` v13); the 2026-10-05 identity probe and its cleanup are logged separately.

**Why.** Appian policy no longer allows building Appian applications from Claude Code over the Dev MCP. This build continues under the Kiro IDE, with planning and prompts still in the claude.ai Project.

**What changed, by file.**
- Added `.kiro/` (hooks, scripts, steering), `kiro-setup/`, `CREDITS.md`, `maintenance/kiro-port.md`, `maintenance/migrate-from-claude-code.md`; `.gitignore` gained the Kiro lines.
- Replaced the template-owned files with the Kiro template's copies: `GETTING_STARTED.md`, `reference/`, `examples/`, `maintenance/dev-mcp-update.md`, `skills/appian-supplemental/SKILL.md` (now version 2026-10-05.2). The build's one local addition, the demo-presenter note in `GETTING_STARTED.md`, was promoted into the template first, so it is still here.
- Moved the build's project sections from `CLAUDE.md` into `.kiro/steering/project.md`, unchanged except four reference fixes (core pointers, the files-list line, Kiro's tool-name forms, the runtime ban's enforcement). The Build parameters table is outside any code fence, where the session-start hook reads it.
- Removed `CLAUDE.md`. Regenerated `PROJECT_INSTRUCTIONS.md` from the Kiro block with the existing BUILD CONTEXT.

**How the build runs now.** Every Kiro session on this folder gets the operating core from `.kiro/steering/`, a session-start report from the hook (plan status, Build parameters, BUILD_LOG tail, TODO counts, git state, credits), a plan gate that allows Dev MCP writes because `BUILD_PLAN.md` is populated, a Stop hook that re-checks the close-out push, and the operator's permission rules denying the runtime server and the Dev MCP's deletes. Close-out is core §10 as before, with `CREDITS.md` rebuilt from Kiro's own records.

**Verified.** `preflight.py` reads every Build parameter by name and finds the plan populated; `plan_gate.py` exits 0 on a write; `project.md` mentions `CLAUDE.md` once, in its files list; the working tree held exactly the listed changes before the commit; push verified by `HEAD` equal to `origin/main`.

**Not verified.** Nothing has run in Kiro on this repo yet. The first Kiro session records the B-checks in `maintenance/kiro-port.md`.

**Rulings needed.** None.

**Promotion candidates.** None found; the presenter note was promoted during the migration.

**TODO changes:** added three items under Before demo: the first Kiro session on this build (with the B-checks), paste the regenerated Project instructions, make the repository private.

**BUILD_PLAN.md changes:** none; no plan item was built.
