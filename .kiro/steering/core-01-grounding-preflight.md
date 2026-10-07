---
inclusion: always
---

# Operating core — §1 Grounding, §2 Preflight

## 1. Grounding order at session start

Read, in this order, before anything else:

1. **This core.** Kiro loads the `core-*` steering files and `project.md` into every session (always inclusion). The preamble lists them.
2. **The client-standards / project skill**, if the build has one. Invoke it by name (`/<prefix>-standards`).
3. **The appian-supplemental skill** (user level) — mandatory before any Appian object work or any SAIL generation or edit. Invoke `/appian-supplemental`, then Appian's skill `/appian`, and read the vendor pack's Dev MCP references the supplemental names (`~/.kiro/skills/appian/references/`) before object work. Kiro loads a skill's full text only when a request matches its description or it is invoked by name, so invoke both explicitly rather than relying on a match.
4. **The BUILD_LOG tail**, the last session entry at minimum, including the promotion checkpoint line. Then read the open sections of `TODO.md` and the current phase of `BUILD_PLAN.md`. The session-start report prints the tail, the checkpoint line, and the TODO counts. Read the full entry in `BUILD_LOG.md` when the report truncates it.

Then run the preflight (§2). Nothing is designed, written, or run before all four are read: the log tail is where the previous session left the environment, and the environment is never assumed to match the plan.

## 2. Session preflight (before any work)

**How the preflight runs in Kiro.** The SessionStart hook (`.kiro/hooks/session-preflight.json`) runs the steps marked **[hook]** before the first message. It puts its report into the session's context, headed `SESSION PREFLIGHT REPORT`.

**Steps marked [agent] are the session's own.** They need Dev MCP tools, which a hook cannot call. Run them in order, before any other work, when the operator says "run the preflight" or gives the first instruction of the session.

**When the hook could not do its part:**
- **It reports a check it could not complete:** that step becomes an agent step.
- **No report is in context** (the hook did not run): run `python3 .kiro/scripts/preflight.py`, read its output, and record in the log that the hook did not fire.

0. **[hook] Port status.** While `maintenance/kiro-port.md` has open required measurements, the report says `PORT UNMEASURED`. Run them first (`#kiro-first-session`), and do no build work until they are done (preamble).
1. **[hook] Confirm the build is planned.** `BUILD_PLAN.md` must exist and contain actual build content beyond the template stub: the stub marker line is gone and the Build Phases section holds at least one checklist item.
   - **If it does not, STOP.** Report that the build is not yet planned, and that Phase 0 happens in the claude.ai Project before build sessions begin (see `GETTING_STARTED.md` §3). Phase 0 is the build plan, the demo narrative, the personas, and the entity-level data model.
   - **In this state:** do not create objects, seed data, or accept build prompts. The only permitted work is reading the environment.
   - **The PreToolUse plan gate enforces this.** It refuses every Dev MCP tool except `get*`, `list*`, `validate*`, `testRule`, `testInterface`, `getDevMcpVersionInfo` and `logout` until the plan is real. A refusal is the gate working.
2. **[agent] Verify the Dev MCP is connected AND the full design-object tool surface is present.**
   - **Check the families.** Confirm the tools from server `appian` include the design CRUD families: record types, fields, relationships, expression rules, interfaces, process models and nodes, sites, constants, documents, `testRule`, `testInterface`, `testProcessModel`, `validateDesignObject`. A runtime subset is not enough.
   - **Count them.** DevMCP 26.6.105 registers 199 tools (`reference/mcp-capability-boundaries.md`).
   - **Then read.** Make one trivial design read, `listRecordTypes` scoped to the **Application UUID** build parameter (§13), and confirm it returns the application's types.
   - **Names.** Kiro's configuration and hooks name these tools `@appian/<tool>`. The form the session itself sees is recorded by first-session measurement M8.
3. **[agent] If the design tools are missing or the read fails: STOP.** Report the tool count and which families are present.
   - **Do not:** diagnose the cause, improvise a reduced-scope pass, substitute runtime tools, or proceed degraded.
   - **Treat it as retry-next-session.** A missing design surface has been measured as transient (it returned on its own the next session), so do not work around it.
   - **The exception is a shadow, which does not clear on retry.** In Kiro, two configuration entries with the same server name do not merge: the higher-priority entry replaces the other whole. Workspace `.kiro/settings/mcp.json` outranks user `~/.kiro/settings/mcp.json` (documented, unmeasured). So a second entry named `appian` silently takes the Dev MCP's place.
     - **Tell:** the tools under `appian` are the runtime family (snake_case `appian_*` plus `ping`), or the report says the effective `appian` entry does not run `lcp_mcp_server`.
     - **What to report:** that a non-Dev MCP server holds the Dev MCP's name (§6, `reference/toolchain.md` §2).
   - **A connected-looking server proves nothing.** Kiro's MCP panel showing `appian` connected, and a `ping` answering, prove transport, not that the design surface loaded. The panel has also shown "connected" for a server whose calls fail (kirodotdev/Kiro#7991).
4. **Check the Dev MCP, skill, and sail versions against their pins: a flag, not a gate.**
   - **[agent] Version tool.** Call `getDevMcpVersionInfo`. Compare the plugin version and build stamp with the version pin at the top of `reference/toolchain.md` §1, and surface the tool's own recommendations. If the site's plugin is behind the App Market, say so: the site admin updates the plugin before a bundle download is worthwhile, because the bundle versions with the site's plugin.
   - **[hook] Local half.** The report compares three things:
     - the registered bundle's build stamp with the same pin;
     - `sail --version` with the sail pin in `reference/toolchain.md` §12. sail ships in the same bundle [S1];
     - the `version=` line of `~/.kiro/skills/appian/.bundle-manifest` with the registered bundle's `composer_commit`.
   - **[agent] Skill against the site.** Compare that manifest line with the plugin's `composerCommit` too. The vendor skill ships in the same bundle and documents that build's tool parameters (`reference/toolchain.md` §5). Report a mismatch, or a missing manifest (a pre-bundle install from Appian's public `appian/dev-mcp-skills` repository), as drift on the same footing as the server's.
   - **On a server mismatch:**
     - report that the server has updated and that `toolchain.md` §1 describes the previous generation;
     - offer to walk the operator through the update procedure (they say "run the update procedure", and the session follows `#dev-mcp-update`);
     - print both bundle download paths for the current site, with `<site>` taken from the registration's `LCP_URL`: the documented downloads page `https://<site>/suite/plugins/servlet/stateless/downloads` (the operator-facing entry), and the direct bundle link the version tool itself prints, `https://<site>/suite/plugins/servlet/stateless/lcp-mcp-bundle` (`maintenance/dev-mcp-update.md` Step 0);
     - note the drift in `BUILD_LOG.md`.
   - **If `sail` is missing or does not execute:** say so, point the operator at `GETTING_STARTED.md` §1, and route persona-scoped checks to the browser checklist until it is installed.
   - **Unlike the plan gate, the session proceeds after reporting.**
5. **Establish which MCP server every tool family belongs to and which identity it executes as** (§6). Servers are named by role: `appian` for the Dev MCP, `appian-runtime` for a runtime server.
   - **[hook] Configuration.** The report lists the server names each MCP config defines (names only, never values). It says which `appian` entry is in effect and whether it runs `lcp_mcp_server`. It also says whether `~/.kiro/settings/permissions.yaml` carries every deny entry in `kiro-setup/permissions.yaml`.
   - **[agent] Session.** Confirm what the session actually has. The runtime family must be absent or refused by the `appian-runtime/*` deny rule in `~/.kiro/settings/permissions.yaml` (the sole enforcement layer for it; §6).
6. **[hook] Compare the repo's `skills/appian-supplemental/SKILL.md` with the installed user-level copy at `~/.kiro/skills/appian-supplemental/SKILL.md`.**
   - **If they differ,** say so, show which is newer, and let the human decide the direction of the sync before continuing: install the repo copy after a template update, or copy the installed skill into the repo after a promotion.
   - **Never overwrite either silently.**
   - **A workspace copy of Appian's skill** (`.kiro/skills/appian`) overrides the user-level bundle copy. The report flags it; it is removed unless the operator chose it.
7. **[agent] Run the per-session ritual named in the Per-session ritual build parameter** (§13) before rendering anything. For example, re-date time-anchored fixtures with the project's idempotent script, so a stale book is not mistaken for a broken screen.
8. **[agent] State the executing identity and its group scope** at the top of the session's work, because every readback that follows is interpreted under it (§4).
   - **sail:** the persona sessions available on this machine are the ones step 9 reports; no sail command reports the acting identity (§6) [S2].
   - **Design account:** compare the executing identity with the **Design account** build parameter and report a mismatch.
   - **Groups:** verify by readback, not from the plan, that the groups named in the **Security groups** build parameter exist, are nested as believed, and have members. A plan has recorded groups as nested that were siblings, and as created when they were not.
9. **[hook] Report the persona sail sessions on this machine.** Persona sessions are machine-local state. They are never written to a tracked file and never reconciled against the plan. The hook does the discovery and the liveness check; the rules below bind the session as much as the script.
   - **Discover.** Take every directory matching `~/.sail-*`, plus the default `~/.sail` if it holds a `session.json`.
   - **Read each `session.json` for its `username` and `hostname` fields only.**
     - The file is a bearer credential [S27], so it is never printed or copied into the session, the log, or `Closeout.md`. Read the two fields with a one-line extractor, never with `cat`.
     - Where the file carries `"source": "devmcp"`, the directory is a designer import, not a persona, and is reported as such [S30].
     - A directory without a `session.json` is reported as holding no session.
   - **Check liveness, read-only:** `sail --data-dir <dir> pages <site>`, where `<site>` is the **Persona site stub** build parameter (§13).
   - **Report** each username as **live** (the page list came back) or **expired** (an authentication error), quoting sail's error for anything else. Name the directory beside each result. If the default `~/.sail` holds a session, say so, because it should stay empty (§6).
   - **That is the whole step.** Nothing is logged in, repaired, or recorded.
   - **The username is only a claim.** It is what the operator typed at login, not something the server verified. Liveness proves the session works; which account it is still gets confirmed by observation, as §6 requires.
   - **Later in the session:** when a build prompt asks for verification as a persona that has no live session, sail's own error is the signal. Report "no live session for `<persona>`, run the login" and skip that verification. Never fall back to another identity.
