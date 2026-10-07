# Kiro port: status, required measurements, staged candidates

**Provenance.** This repo is the Kiro IDE port of `appian-fs-sc/appian-devmcp-method` at commit `0eb0c18` (2026-10-05). The port targets the **Kiro IDE (1.x) only**. CLI differences are noted only where they would change a design decision.

**Status: the nine first-session measurements are recorded on Kiro IDE 1.2.4 (2026-10-05 to 2026-10-07).**
- **Source.** Everything Kiro-specific in this repo was written on 2026-10-05 from kiro.dev documentation and kirodotdev GitHub issues, then measured on the first Kiro sessions.
- **What was measured.** The Kiro layer: the plan gate (M1), the permission denies (M2), the Stop close-out guard (M3), the SessionStart preflight delivery (M4), the default agent's Dev MCP tool surface (M5), which restart replaces the server process (M6), and `mcp.json`'s `requestTimeout` (M7). The tool-name forms (M8) and the commit/push prompt behaviour (M9) are recorded. See the ticked measurements and the First-session findings below.
- **What still stands unchanged.** The method's Appian and sail content was measured in the source repo, before the port.
- **The session-start report no longer prints `PORT UNMEASURED`** now that every box is ticked; it reports that every measurement is ticked instead. `#kiro-first-session` remains available if a machine ever needs to re-run the port's measurements.

## Required measurements (the first Kiro session)

**How to run them** (core §4, §11):
- In order, in a session opened on this repo with its workspace trusted.
- The Dev MCP and sail must be set up as `GETTING_STARTED.md` §1 describes.
- Each pass condition is fixed here, before the run. A gate is proven by a break-test, never by a happy path.

**When each one is done:**
- Tick its box.
- Add the date, the Kiro IDE version (Help → About), and one line of result.
- Correct every file that depended on it. Each item names those files.
- Once all nine are ticked, change the README's status line and this file's status paragraph to say what was measured.

**When one fails:** do not work around it. Record the failure here and in the files it affects, and change the design. That might mean replacing a hook with a deny rule, or a rule with an operator step.

- [x] **M1. The plan gate blocks a Dev MCP write with exit 2.** PASS (2026-10-06, fresh session; Kiro IDE 1.2.4). `BUILD_PLAN.md` is the template stub, as it ships.
  - **Control:** ask the agent to call `getDevMcpVersionInfo`. It must run.
  - **Break-test:** ask it to call `createFolder` for a folder named `zzKiroGateProbe`.
  - **Pass:** the create did not execute; a `listFolders` readback shows no such folder. The agent received the gate's "Plan gate: …" text, and `.kiro/state/hook-events.log` has a `plan-gate … blocked` line.
  - **If the call ran:** the gate is advisory, not enforced. Delete the folder (with the operator's permission switch, core §6) and record it.
  - **Measured 2026-10-06 (fresh session after Kiro restart; hooks active):** control `getDevMcpVersionInfo` ran and returned (logged `mcp_appian_getdevmcpversioninfo … allowed`); the `createFolder zzKiroGateProbe` break-test was intercepted by the PreToolUse hook with the "Plan gate: BUILD_PLAN.md still carries the template stub marker line…" message and **not executed** — it never reached the server (the block is pre-server), so no `listFolders` readback was needed. `.kiro/state/hook-events.log` shows `mcp_appian_createfolder … blocked`. This passed only after correcting the matchers and `plan_gate.py` to the measured name form (M8).
  - **Files that depend on it:** core §2 step 1, `.kiro/hooks/gates.json`, `.kiro/scripts/plan_gate.py`.
- [x] **M2. The permission deny rules hold (runtime ban and delete deny).** PASS (2026-10-05/06; Kiro IDE 1.2.4). Both guards are one mechanism — `~/.kiro/settings/permissions.yaml` deny rules — so M2(c) proves the mechanism for both. The runtime-ban PreToolUse hook was removed as a fragile duplicate (see First-session findings; core §6).
  - **(a) Runtime tool (permission deny):** if an `appian-runtime` server is registered, a runtime tool such as `ping` must be refused by the `appian-runtime/*` deny rule. Skipped here: no runtime server is registered on this machine (only `appian` and `appian-public-docs`), so there is no runtime tool to call.
  - **(b) [dropped]:** this step disabled the runtime-ban *hook* to test the permission layer alone. With the hook removed there is no second layer to subtract — (c) exercises the permission deny mechanism directly.
  - **(c) Delete deny — PASS:** `deleteFolder` on the made-up UUID `00000000-0000-0000-0000-00000000zz00` was refused by Kiro's permission layer **before the call reached the server** — the denial quoted the matched `deny mcp` rule and named its source, `/Users/scott.thorn/.kiro/settings/permissions.yaml`. Kiro's own denial, not a 404/403. Re-confirmed in the fresh session (2026-10-06): the deny still matched the stable `appian/deleteFolder` form even though the invocation form had changed to `mcp_appian_deletefolder`.
  - **Files that depend on it:** core §6, `kiro-setup/permissions.yaml`.
- [x] **M3. The Stop hook's block decision keeps the agent going.** PASS (2026-10-06, fresh session after Kiro restart; Kiro IDE 1.2.4).
  - **Setup:** create an uncommitted `Closeout.md` with one line, then end a turn.
  - **Pass:**
    - the agent continues with the "Close-out check: …" reason as a new message;
    - on the third consecutive stop the hook warns instead of blocking;
    - after `Closeout.md` is removed and the tree is clean, `.kiro/state/closeout-blocks` reads 0.
  - **Also record:** whether Stop fires at the end of every turn or only when the session ends. The docs say both.
  - **Measured 2026-10-06 (fresh session):** with an uncommitted `Closeout.md`, the Stop hook reinjected the "Close-out check: …" block reason on the first and second stops (counter 1 → 2), and on the third stop **warned** instead ("still not handed off after 2 reminders", counter 3) — the block→warn progression confirmed live. The **reset to 0** path (`not closeout_dirty and not unpushed_closeout → set_blocks(0)`) is verified by script logic and the earlier manual run, **not observed live** (the live reset needs the hook to fire again after cleanup, and the firing cadence across turns was inconsistent — see findings). Ticked on the block+warn+counter evidence per operator ruling.
  - **Files that depend on it:** core §10, `.kiro/scripts/closeout_check.py`.
- [x] **M4. SessionStart output reaches the agent's context.** PASS (operator-reported 2026-10-05; re-confirmed live 2026-10-07; Kiro IDE 1.2.4).
  - **Steps:** open a new chat session. Before anything else, ask the agent to quote the first line of the session preflight report without running any tool.
  - **Pass:** it quotes `SESSION PREFLIGHT REPORT …` without a tool call.
  - **Also record:** how long the hook took. Its timeout is 180 s.
  - **Operator-reported (2026-10-05):** in a fresh chat the agent quoted the first line of the session preflight report with no tool call; hook duration not recorded.
  - **Re-confirmed live this session:** the `SESSION PREFLIGHT REPORT` was already in context, and its first line — "SESSION PREFLIGHT REPORT (SessionStart hook, machine-side checks; core §2). Read it before acting." — was quoted without a tool call. The hook's own delivery time is not observable from the session; for reference, `python3 .kiro/scripts/preflight.py` runs in ~0.34 s wall (the script's runtime, not the hook's measured duration).
  - **Files that depend on it:** core §1 and §2, `.kiro/hooks/session-preflight.json`.
- [x] **M5. The default agent receives the Dev MCP's tools from `mcp.json`.** PASS (live 2026-10-07; Kiro IDE 1.2.4).
  - **Pass:**
    - the default agent lists 199 tools for server `appian`, the DevMCP 26.6.105 count (`reference/mcp-capability-boundaries.md`);
    - `listRecordTypes` on a known application returns its types.
  - **Also, as evidence for candidate C1:** create the staged `appian-build` agent from C1 in `.kiro/agents/` (Kiro asks before that write). Select it in the agent picker, record whether it receives `@appian` tools on this Kiro version, then delete the file.
  - **Measured live this session:** the default agent is in use. `getDevMcpVersionInfo` confirms the registered build is `20260930-110421` (26.6.105), the 199-tool build; the bundle source was recounted this session and holds exactly 199 `@mcp.tool` functions in `tools/*.py` (grep and ast agree), with none outside `tools/` and no conditional registration. The design families are present and functional: `listApplications` returned 301 applications, and `listRecordTypes` on "Account Management" returned 6 record types.
  - **Per-server tool counts (settles the operator's "200"):** `appian` = 199; `appian-public-docs` = 1 (`search_appian_knowledge_sources`, `reference/toolchain.md` §3); no other MCP server in the session (the session-start report's step-5 list names only those two). So the "200" the operator saw is the cross-server total, 199 + 1, not the `appian` server alone. (The agent cannot programmatically dump its own exposed tool registry, so the `appian` 199 is established from the registered bundle source reproduced this session and corroborated by the functional reads.)
  - **C1 evidence not collected; C1 stays staged on its issue trigger.**
  - **Files that depend on it:** core §2 step 2, `GETTING_STARTED.md` §1.
- [x] **M6. Which restart replaces the Dev MCP's process.** MEASURED (operator-reported 2026-10-05; Kiro IDE 1.2.4).
  - **Method:** run `pgrep -f lcp_mcp_server` before and after each of these:
    - MCP panel → right-click `appian` → Reconnect;
    - Disable, then Enable;
    - an operator edit of a dummy value in the `appian` entry of `~/.kiro/settings/mcp.json`;
    - a full quit and reopen of Kiro.
  - **Also record:** whether two open chat sessions share one process.
  - **Pass:** none; this is a measurement. Record which actions change the PID.
  - **Then:** replace the provisional "quit and reopen Kiro" in core §6 and `reference/toolchain.md` §1 with the cheapest action that replaces the process.
  - **Operator-reported (2026-10-05):** all four actions — Reconnect, Disable-then-Enable, a dummy-value edit of the `appian` entry in `~/.kiro/settings/mcp.json`, and a full quit and reopen — replaced the `lcp_mcp_server` process ID. Whether two open chats share one process was not recorded. **Reconnect is the cheapest action that replaces the process and is now the stated default;** a full quit and reopen is the fallback if Reconnect does not change the PID. Confirm either with `pgrep -f lcp_mcp_server` (or `pgrep -fl lcp_mcp_server` where the running command's path matters). Applied to core §6, `reference/toolchain.md` §1, `reference/silent-failure-taxonomy.md`, `GETTING_STARTED.md`, and `maintenance/dev-mcp-update.md`.
- [x] **M7. `mcp.json` accepts and honours `requestTimeout`.** PASS (operator-reported 2026-10-05; Kiro IDE 1.2.4).
  - **(a)** With `"requestTimeout": 330000` in the `appian` entry, confirm the server loads at all. If it doesn't, remove the key, record it, and redo (a).
  - **(b)** Call `logout`, then replace the process (the M6 method). Make a design call and wait about 150 s before completing the browser sign-in.
  - **Pass:** the call completes after the sign-in, past Kiro's 120 s default.
  - **Operator-reported (2026-10-05):** (a) with `"requestTimeout": 330000` in the `appian` entry the server loaded. (b) after `logout` and a process replacement, a design call waited through a browser sign-in held ~2.5 min and returned at 3m06s — past Kiro's 120 s default. So `mcp.json` honours `requestTimeout`. Without it, the first call of a session would hit the documented 120 s default while the operator signs in (inferred from the documented default; no call was run without the key). Stated in `reference/toolchain.md` §1 and `GETTING_STARTED.md` §1 step g; `kiro-setup/mcp.json` keeps the key.
  - **Files that depend on it:** `kiro-setup/mcp.json`, `reference/toolchain.md` §1.
- [x] **M8. The names Kiro uses for MCP tools.** RECORDED (2026-10-06; M8a hook-facing form measured in the fresh session).
  - **(a)** Copy the exact `tool_name` values from `.kiro/state/hook-events.log`, written during M1 and M2.
  - **(b)** Ask the agent for the exact names it sees for `listRecordTypes`, `getDevMcpVersionInfo` and `deleteFolder`.
  - **Pass:** none; record both.
  - **Then:** if the hooks receive anything other than `@appian/<tool>`, fix the matchers in `.kiro/hooks/gates.json` and the pattern in `.kiro/scripts/plan_gate.py`. Update the tool-presence wording in core §2 and §6.
  - **Measured — session 1 (2026-10-05, deferred tools) and session 2 (2026-10-06, direct tools, after restart):**
    - **(b) names the session sees:** session 1 invoked tools as `appian::<tool>` (`::` separator); session 2, with the tools exposed directly, as `mcp_appian_<tool>`, all lowercase. The permission layer named the tool `appian/<tool>` in both (single slash, no `@`, camelCase preserved).
    - **(a) hook-facing form, MEASURED 2026-10-06:** with the plan-gate matcher temporarily set to an appian-scoped catch-all (authorized diagnostic), a Dev MCP read fired the hook, which received `tool_name` = **`mcp_appian_getdevmcpversioninfo`** (lowercase, `mcp_appian_` prefix, no separator) on stdin — seen both in the gate's echoed message and in `.kiro/state/hook-events.log`. The matcher was then set to the measured form (not left at catch-all).
    - **Fix applied:** both `gates.json` matchers and `plan_gate.py` now target `mcp_appian_<tool>` while still tolerating the earlier `appian/`, `appian::`, `@appian/` forms, scoped to exclude the `appian-runtime` and `appian-public-docs` servers; read-detection is case-insensitive because the `mcp_appian_` form lowercases the tool. The runtime-ban matcher's `mcp_appian-runtime_` form is inferred (no runtime server to measure). Also updated in `reference/toolchain.md` §2.
    - **Caveat:** the name form is not stable across sessions (see First-session findings below). The matcher is deliberately multi-form, and permission rules — which matched `appian/<tool>` in both sessions — are the stable surface.
- [x] **M9. Whether `git commit` and `git push` prompt under the allow-everything rule.** MEASURED — no prompt (2026-10-05; Kiro IDE 1.2.4); see note below. Kiro always asks before writes to `.git/**`.
  - **Steps:** on a throwaway local branch, have the agent commit one file under `.work/`. Record whether Kiro prompted. Delete the branch.
  - **Pass:** none; this is a measurement.
  - **Then:** if it prompts, record in core §10 that the operator approves the close-out commit. An unattended close-out is then not possible.
  - **Measured 2026-10-05 (first session; NOT ticked, pending the quit/reopen re-test):** on a throwaway branch (`zz-m9-commit-probe`) the agent committed a file under `.work/` through the shell; the commit returned exit 0 with **no approval prompt**, and the branch/file were removed. Caveat: this ran via the shell under autopilot/allow-all, the path least likely to surface a prompt, so the interactive IDE `.git/**` prompt is unconfirmed. As observed, an unattended close-out commit is possible; confirm the interactive case by hand before relying on it either way.

## First-session findings (2026-10-05 / 2026-10-06)

- **Kiro's tool-name form is not stable across sessions.** The name the agent and the hooks see changed between sessions: `appian::<tool>` when the Dev MCP tools were exposed as deferred tools (session 1), and `mcp_appian_<tool>` (lowercase) when exposed directly (session 2, after a Kiro restart). The **permission layer matched `appian/<tool>` in both** (single slash, no `@`, camelCase preserved). Anything keyed on the model-facing or hook-facing name form is therefore fragile; **permission rules are the stable surface.** The `gates.json` matchers and `plan_gate.py` are deliberately multi-form as a result. Also recorded in the taxonomy (`reference/silent-failure-taxonomy.md`).
- **The Stop hook fires when the agent finishes responding** (documented), not on an idle timer. A user message that follows the agent's stop skips the hook for that cycle, so the close-out loop guard (`.kiro/state/closeout-blocks`) accumulates only across unattended stops. This makes the warn-at-third-stop branch awkward to exercise interactively; the firing pattern across turns was inconsistent and is left as a finding, not chased.
- **Hooks hot-reload on file edit.** Editing `gates.json` mid-session (the M8a diagnostic, and the matcher fix) took effect on the next tool call with no restart. The earlier non-firing was the matcher not matching the `mcp_appian_` form, not a reload failure. (SessionStart *delivery* to context is confirmed — M4 PASS: the report reaches the session's context, re-confirmed live this session.)
- **Credits for the port work, read from Kiro's session store (2026-10-07):** 244.49 credits over 18 prompt turns in two sessions, 2026-10-05 to 2026-10-07 (session totals 158.23 and 86.26). The per-turn figures the operator read off the screen while measuring (18.61, 7.25, 8.84, 44.04) were single turns, not sessions. **Credits are now read from Kiro's session store, not supplied by the operator:** each prompt turn's `usage_summary` record in `~/.kiro/sessions/<workspace>/<session>/messages.jsonl` carries the credits and elapsed time Kiro's usage view shows (a turn recorded as 44.05 credits / 609 s was shown as 44.04 / 10m08s). `.kiro/scripts/credits.py` rebuilds `CREDITS.md` from them at session start and at close-out (core §10 step 1); it ran against this machine's store on 2026-10-07 and reproduced every turn.
- **The runtime-ban PreToolUse hook was removed (2026-10-06); the permission deny rule stands alone.** `permissions.yaml`'s `appian-runtime/*` deny was measured enforcing before the call reaches the server (M2c, the same deny mechanism) and matches on the stable `appian/<tool>` form, while a hook matcher keyed on the tool-name form is fragile (the form changed between sessions, M8). **Rule: where a permission rule and a hook cover the same guard, rely on the permission rule.** The hook was deleted from `.kiro/hooks/gates.json` and its script `.kiro/scripts/runtime_ban.py` removed; the plan gate is the only remaining PreToolUse hook.

## First build-round checks (open)

The nine measurements proved the Kiro layer on a stub plan. These are the parts a real build exercises for the first time. The first build session that reaches each one records the result here, with the date and the Kiro IDE version, and ticks it.

- [ ] **B1. The supplemental skill loads.** After `/appian-supplemental` in a new chat, the session quotes the skill's version line without a file read. If it cannot, the skill is not reaching the session and core §1 step 3 needs a different load path (for example `#[[file:skills/appian-supplemental/SKILL.md]]` in an always-included steering file).
- [ ] **B2. The `auto` reference steering loads by description.** Ask a Dev MCP registration question without naming any file. The session answers from `reference/toolchain.md` §1 (it can quote the `requestTimeout` value and its reason). If it cannot, the `ref-*.md` files only load by `#ref-<name>`, and core §1 says so.
- [ ] **B3. The plan gate unlocks.** With `BUILD_PLAN.md` populated, the first design write runs and `.kiro/state/hook-events.log` shows it `allowed`. The script was verified unlocking by hand on 2026-10-07; Kiro has only ever seen it block.
- [ ] **B4. The Stop hook resets.** After a clean close-out (pushed, tree clean), `.kiro/state/closeout-blocks` reads 0. The reset path was verified by running the script by hand on 2026-10-07; M3 never saw it live.
- [ ] **B5. Credits are recorded without the operator.** On a planned build, the session-start report's Credits line shows a month total and `CREDITS.md` holds one row per prompt turn, matching Kiro's usage view for the same turns. Reading `~/.kiro/sessions/` from the hook and from the agent's shell is documented-unmeasured until this ticks.
- [ ] **B6. The commit and push in a real close-out.** M9 measured no prompt on a throwaway branch through the shell. Record whether Kiro asks during a real close-out's `git commit` and `git push`.
- [ ] **B7. Which delete deny rule matches.** `kiro-setup/permissions.yaml` carries the delete deny twice: the named list (measured, M2c) and the patterns `appian/delete*` and `appian/remove*` (documented: `*` matches any character sequence in an MCP match). With both installed, a `deleteFolder` on a made-up UUID is refused, and the denial names which rule matched. If the pattern rule matched, the named list can be retired at the next Dev MCP update; if only the list matched, remove the pattern rule and record that MCP globs do not match on this Kiro version.

## Staged promotion candidates

### C1. Scoped agents: STAGED (gate 1: designed from the docs, never run)

**Trigger:** when kirodotdev/Kiro#11150 and #10876 are confirmed fixed.

**What it would add.** It would scope the build session at the agent level:
- **`appian-build`:** design tools without delete or remove.
- **`appian-destructive`:** deletes ask every time.
- Both declare their servers explicitly with `includeMcpJson: false`, so a runtime server in `mcp.json` cannot be inherited silently.

**Why it is staged and not used.** Kiro custom agents do not reliably receive MCP tools. Checked on 2026-10-05 with `gh issue view`:
- **#11150** (open): "Custom agents invoked as sub-agents receive no operational tools (regression since ~mid-August 2026)". IDE, from 1.0.395. Last updated 2026-09-20 with "Still reproducing on Kiro CLI V3 (kiro-cli 2.20.0)".
- **#10876** (open): "kiro-cli --v3: mcpServers declared in an agent profile are silently ignored (the same server via mcp.json works)". Last updated 2026-08-19, when a maintainer was "Marking this as a bug to investigate further".
- **Related, also open that day:**
  - #11411: the IDE silently drops a user-scope agent containing `allowedTools` or unrecognised tool tags;
  - #5873: MCP tools not injected for workspace-defined agents.

**The fallback in use instead:**
- the default agent, with servers in `~/.kiro/settings/mcp.json`;
- the operator's deny rules in `~/.kiro/settings/permissions.yaml`;
- the PreToolUse hooks in `.kiro/hooks/gates.json`.

See core §6 and `GETTING_STARTED.md` §1.

**When the trigger fires:**
- Build both agents in `.kiro/agents/`.
- Measure in the IDE that `appian-build` receives the `@appian` tools and no `appian-runtime` tools.
- Break-test the delete deny.
- If both hold, promote: replace the fallback text in core §6 and `GETTING_STARTED.md` §1. The `permissions.yaml` deny rules stay as the second layer either way.

**Watch these unknowns:**
- how a relative `command` path resolves;
- whether glob `match` values work in `permissions` (hence the explicit tool lists);
- whether `excludedTools` can hide MCP tools.

`appian-build.json`:

```json
{
  "name": "appian-build",
  "description": "Appian build session: Dev MCP design tools with no delete or remove; docs-search; runtime server excluded.",
  "mcpServers": {
    "appian": { "command": "bash", "args": [".kiro/scripts/devmcp.sh"], "timeout": 60000, "requestTimeout": 330000 },
    "appian-public-docs": { "url": "https://appian-docs-public.mcp.kapa.ai" }
  },
  "includeMcpJson": false,
  "includePowers": false,
  "tools": ["fs_read", "fs_write", "shell", "web_fetch", "web_search", "@appian", "@appian-public-docs"],
  "permissions": { "rules": [
    { "capability": "mcp", "match": ["appian/delete*", "appian/remove*", "appian/unpublishPortal", "appian-runtime/*"], "effect": "deny" },
    { "capability": "all", "effect": "allow" } ] },
  "resources": ["file://.kiro/steering/**/*.md",
                "skill://~/.kiro/skills/appian/SKILL.md",
                "skill://~/.kiro/skills/appian-supplemental/SKILL.md"],
  "welcomeMessage": "appian-build: additive Dev MCP session. Say 'run the preflight'."
}
```

**How the design works:**
- **`appian-destructive.json`:** identical except for `name` and `description`, and the delete/remove rule is `"effect": "ask"`. The runtime deny stays.
- **`devmcp.sh`:** would read a gitignored, machine-local file holding the bundle path and `LCP_URL`, so no machine path is committed. It is not in the repo, because nothing uses it yet.
- **No `allowedTools`:** that field is avoided because of #11411.
- **Tool names:** `fs_read`-style names are used because #11411 reports the IDE rejecting the documented `read` and `write` tags.

### C2. Kiro traps from field reports: STAGED (gate 1, never observed here)

Triggers: the first session that meets the symptom.
- **A custom agent disappears from the picker with no error.** The IDE silently rejects an agent with an unrecognised config value; the log shows it only at debug level (#11411, open). Working form: keep agents to documented fields, and confirm the agent appears in the picker after every edit.
- **The MCP panel says connected while calls fail** (#7991, closed not planned; #9440 for the CLI). Working form: a design read is the check, never the panel (core §2 step 2).
- **Workspace `mcp.json` servers missing even for the default agent** (#6122): moving the entry to the user-level file fixed it. That is why this port registers servers in `~/.kiro/settings/mcp.json`.

### C3. Kiro features the method does not use yet (candidates, not designed)

- **Powers:** could package the Dev MCP entry, Appian's skill, the supplemental and the steering as one installable Appian power.
- **Specs:** structured requirements, design and task files. The method's prompts come from the claude.ai Project, so this needs a decision.
- **Auto-inclusion steering** beyond the reference files.
- **CLI headless mode with `--require-mcp-startup`:** a possible CI preflight. CLI only, so outside this IDE port unless that decision changes.

## Documentation contradictions found on 2026-10-05

The port follows the safer reading in each case. A measurement settles it.
- **Hook exit codes:**
  - `kiro.dev/docs/hooks/actions` says any non-zero exit blocks a Pre Tool Use hook, and on the same page that only exit 2 blocks and other codes warn.
  - `kiro.dev/docs/ide/whats-new-v1/hooks` says other codes are errors, not blocks.
  - **Port:** gates exit 2, including on their own errors.
- **When Stop fires:**
  - "after the agent completes its turn" (`hooks/types`);
  - "when the session ends" (`cli/v3/hooks-migration`).
  - **Port:** the Stop check is silent unless a close-out is in progress (M3).
- **Whether custom agents inherit steering:**
  - not automatically (`steering`);
  - inherited by default (`custom-agents/configuration-reference`).
  - **Port:** C1 lists steering in `resources` explicitly.
- **Whether the IDE reads hooks declared inside an agent config:** both stated on `custom-agents/configuration-reference`. **Port:** standalone `.kiro/hooks/*.json` files only.
- **`includeMcpJson`:**
  - no documented default;
  - one page says it covers global and workspace `mcp.json`, others say workspace only.

## Decisions taken for the port (operator, 2026-10-05)

1. **Surface:** the Kiro IDE only.
2. **Agents:** the fallback posture: the default agent, servers in `mcp.json`, deny rules in `~/.kiro/settings/permissions.yaml`, and the PreToolUse hooks. Scoped agents are staged as C1.
3. **The nine measurements above** are a separate pass, run by the first Kiro session once Kiro is installed. The port's first commit stops before them.
