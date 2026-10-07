# Migrating a Claude Code build repo to the Kiro method

**For a build repo that was set up from `appian-devmcp-method` (the Claude Code template) and continues under Kiro.** Executed by the Kiro session opened on the build repo, or by hand. It moves the build onto this template's Kiro layer without touching the build's own content: objects, plan, log, prompts, mockups, fixtures, and project rules all stay as they are.

## What changes and what does not

- **Replaced with this template's copies:** `GETTING_STARTED.md`, `reference/`, `examples/`, `maintenance/dev-mcp-update.md`, `skills/appian-supplemental/SKILL.md`. These were template-owned in the build already ("copied unchanged, edit them in the template"). Before replacing one, confirm it matches some version of the Claude Code template; a file that matches none has a local edit that must be carried over by hand.
- **Added:** `.kiro/` (hooks, scripts, steering), `kiro-setup/`, `CREDITS.md`, `maintenance/kiro-port.md`, `maintenance/migrate-from-claude-code.md`, and the `.gitignore` lines for `.kiro/settings/`, `.kiro/state/` and `__pycache__/`.
- **Moved:** the build's project sections, everything below `## 13. Project sections` in `CLAUDE.md`, go to the bottom of `.kiro/steering/project.md`, below the template's §13 text. The build's filled-in **Build parameters** table stays outside any code fence, because the session-start hook reads only a block outside a fence.
- **Removed:** `CLAUDE.md`. Its core is now the `core-*.md` steering files, and its project sections are in `project.md`. Git history keeps the file. Any `.claude/` folder in the repo goes too.
- **Untouched:** `BUILD_PLAN.md`, `BUILD_LOG.md`, `TODO.md`, `Closeout.md`, `prompts/`, `mockups/`, `agent/`, `.work/`, and every build-specific file. Historical mentions of `CLAUDE.md` in the log, the plan, the TODO, SQL comments and specs stay as written; they name the file that held the ruling on that date.

## Steps

1. **Confirm the starting point.** `git status` is clean and `HEAD` equals `origin/main`. Record the build's HEAD in the log entry at the end.
2. **Check the template-owned files for local edits.** For each file in the replaced set, compare the build's copy with the Claude Code template's history (`git log --format=%h -- <file>` in a clone of `appian-fs-sc/appian-devmcp-method`, then `git show <commit>:<file> | cmp - <build copy>`). A file that matches a template version is replaced outright. A file that matches none is diffed against its closest version, and the local addition is moved: a noun-free addition goes into this template (as a promotion); a build-specific one goes into `project.md`.
3. **Copy this template's files into the build** (from a clone of `appian-fs-sc/appian-devmcp-method-kiro` at the commit named in the log entry): `.kiro/` without `steering/project.md`, `kiro-setup/`, `GETTING_STARTED.md`, `CREDITS.md`, `reference/`, `examples/`, `maintenance/`, `skills/appian-supplemental/SKILL.md`. Append the Kiro lines of this template's `.gitignore` to the build's.
4. **Build `project.md`.** Start from this template's `.kiro/steering/project.md`. Below its §13 text, append the build's project sections from `CLAUDE.md` (everything after the §13 block and its explanatory paragraphs, from the build's own heading on). Then fix the references inside the moved text so they resolve in Kiro:
   - "`CLAUDE.md` §N" and "top of file" become "core §N" and "core-00-preamble";
   - "this file" in a files list becomes `.kiro/steering/project.md`;
   - tool-name forms written as `mcp__appian__<tool>` are Claude Code's; in Kiro the Dev MCP's tools appear as `mcp_appian_<tool>` or `appian::<tool>` and the permission layer names them `appian/<tool>` (`reference/toolchain.md` §2). The rule those forms express (which server a tool belongs to, and that the runtime server is never used) is unchanged;
   - a runtime-server ban written as an instruction now also has an enforcement: the operator's `~/.kiro/settings/permissions.yaml` denies `appian-runtime/*` (core §6). Say so where the ban is stated;
   - "Claude Code" as the session becomes "the Kiro session".
   Add one line to the build's files list: `CLAUDE.md` was replaced on the migration date by `.kiro/steering/` and this file; older references to it mean this file.
5. **Delete `CLAUDE.md`** (`git rm`), and `.claude/` if present.
6. **Regenerate `PROJECT_INSTRUCTIONS.md`** from this template's `GETTING_STARTED.md` §2 block, keeping the build's existing BUILD CONTEXT values. The operator pastes the fenced block into the claude.ai Project's instructions; the old block says the build runs in Claude Code.
7. **Verify by readback.**
   - `python3 .kiro/scripts/preflight.py`: the report finds the plan populated, reads every Build parameter by name (none `UNSET` that the table fills), and finds the BUILD_LOG tail.
   - `echo '{"tool_name":"mcp_appian_createfolder"}' | python3 .kiro/scripts/plan_gate.py; echo $?` prints `0` (the plan is real, so the gate allows a write).
   - `grep -rn 'CLAUDE.md' .kiro/steering/project.md` returns only the files-list line added in step 4.
   - `git status` lists the expected changes and nothing else.
8. **Record and hand off.** Append a `BUILD_LOG.md` entry (what moved, the template commit, the files replaced, what was carried over by hand, the readbacks), update `TODO.md` if anything was deferred, rewrite `Closeout.md` so the Project reads the migrated state, commit, push, and verify `HEAD` equals `origin/main`.
9. **On the operator's machine, before the first Kiro session on the build:** `GETTING_STARTED.md` §1 steps e through j once per machine (Kiro, the bundle, the two settings files, the first-launch prompt). A machine that already runs another Kiro build has them. Then open the build folder in Kiro, trust the workspace, and say "run the preflight". The B-checks in `maintenance/kiro-port.md` are recorded by the first build session that reaches each one.
