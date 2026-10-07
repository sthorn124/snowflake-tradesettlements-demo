---
inclusion: always
---

# Appian Dev MCP build: operating core (Kiro IDE)

These steering files are the generic operating core for an Appian application built through the Appian Dev MCP from the Kiro IDE.
- **What a build does with them.** The template ships them in `.kiro/steering/`. A build keeps them as written and adds its own sections to `.kiro/steering/project.md`: vocabulary canon, data model, naming prefix, groups, business rules, repeatability rules, files in the repo.
- **What they contain.** Nothing in this core names a client, an application, a record type, a dataset, or a demo scenario; everything in it applies to every build.
- **Citations.** Bracketed S-numbers cite rows of the sail evaluation's measurement record in `examples/persona-verification-walkthrough.md`.

**Where each section lives.** The core keeps the section numbers it had as a single `CLAUDE.md`, so "core §N" anywhere in the repo resolves:

| Sections | File |
|---|---|
| this preamble | `core-00-preamble.md` |
| §1 Grounding, §2 Preflight | `core-01-grounding-preflight.md` |
| §3 Observation, §4 Verification | `core-02-observation-verification.md` |
| §5 Docs-search | `core-03-docs-search.md` |
| §6 Identity | `core-04-identity.md` |
| §7 Log, §8 TODO, §9 Promotion, §10 Close-out | `core-05-records-closeout.md` |
| §11 Regression, §12 Writes against demo data | `core-06-regression-writes.md` |
| §13 Project sections and build parameters | `project.md` |

**Other steering:**
- **Reference files** load when relevant, by description (`ref-*.md`).
- **Three procedures** load on request:
  - `#kiro-first-session` (the port's required measurements);
  - `#dev-mcp-update` (the update procedure);
  - `#generate-project-instructions`.

**Enforcement, not only instruction.** These mechanisms hold some of the rules below even when a session forgets them:
- **`.kiro/hooks/session-preflight.json`** (SessionStart) runs the machine-side preflight and puts its report in context (§2).
- **`.kiro/hooks/gates.json`** (PreToolUse) refuses every Dev MCP tool except reads while `BUILD_PLAN.md` is the template stub (§2 step 1). (The runtime-server ban is the permission deny below; a duplicate PreToolUse hook was removed — §6.)
- **`~/.kiro/settings/permissions.yaml`**, written by the operator from `kiro-setup/permissions.yaml`, denies the runtime server's tools and the Dev MCP's delete and remove tools (§6, §12). A session cannot edit it: Kiro denies agent writes to `~/.kiro/settings/`.
- **`.kiro/hooks/closeout.json`** (Stop) re-checks the close-out push when a turn ends (§10).

A refusal from any of them is the mechanism working. Report it; never route around it.

**This port is measured.**
- **Where it came from.** It was written from Kiro's documentation on 2026-10-05, then measured on the first Kiro sessions (2026-10-05 to 2026-10-07, Kiro IDE 1.2.4).
- **What was measured.** The Kiro layer: hooks, permissions, MCP configuration, and which restart replaces the server process. Steering inclusion modes were not one of the nine measurements. All nine required measurements in `maintenance/kiro-port.md` are recorded, so the session-start report no longer prints `PORT UNMEASURED`; it reports every measurement ticked. `#kiro-first-session` remains available if a machine ever needs to re-run them.
- **What it covers.** Everything about Appian, the Dev MCP and sail in these files was already measured, as it was before the port.

**Skill precedence.**
- **The user-level `appian-supplemental` skill** (`~/.kiro/skills/appian-supplemental/`) governs environment, platform, and Dev MCP facts and the portable working method.
- **A project skill** (a `<prefix>-standards` or client-standards skill in the workspace's `.kiro/skills/`), if the build has one, governs SAIL styling, naming, colours, and this build's layout applications.
- **This core and the build's `project.md`** govern the project's data model, vocabulary, and business rules, and win on conflict for project matters.
- **`appian-supplemental` wins over the vendor pack** (Appian's `appian` skill) and the docs only where it records a measured correction.
- **New environment behaviour starts in the build log.** Surprising behaviour discovered in a build is recorded there as a promotion candidate first. It reaches `appian-supplemental` only through the promotion gate (§9), and `project.md` then keeps at most an application pointer.
