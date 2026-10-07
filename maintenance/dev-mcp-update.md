# Dev MCP update procedure

**Executed by the Kiro session, not copy-pasted by a human.** When the operator says "run the update procedure" (or `#dev-mcp-update`), the session reads this file and works through it: it performs the machine steps itself, prompts the operator at each step only a person can do, and stops at the phase boundary. Every step is verified before the next; nothing is deleted; the previous install stays as rollback.

## When this runs, what it produces, and its shape

- **When:** a new Dev MCP bundle is available — the preflight version check (core §2) reports that `getDevMcpVersionInfo`'s plugin version or build stamp no longer matches the pin in `reference/toolchain.md` §1, or that `sail --version` no longer matches the sail pin in §12, or the operator triggers it.
- **What it produces:**
  - the new server installed side by side with the old one, and the MCP registration pointed at it;
  - the sail CLI from the same bundle linked in its place;
  - Appian's `appian` skill from the same bundle installed at `~/.kiro/skills/appian`;
  - the delete and remove deny list in `kiro-setup/permissions.yaml` regenerated from the new tool inventory, for the operator to merge into `~/.kiro/settings/permissions.yaml`;
  - `reference/toolchain.md` §1, §2, §5, and §12 re-verified against the new server's source, the new skill, and the new sail's help;
  - the server-behaviour and sail entries in `reference/silent-failure-taxonomy.md` and `reference/mcp-capability-boundaries.md` re-checked, and the supplemental's citations of the vendor skill re-checked against the new copy;
  - the three version pins refreshed (server, skill, sail);
  - one commit.
- **Shape:** two Kiro sessions with a mandatory restart of the Dev MCP's process between them.
  - Phase 1 installs under the old server; Phase 2 verifies under the new one, because a running server process keeps the code it started with.
  - **What the session hands to the operator:**
    - downloading the bundle (it sits behind the site's login);
    - every edit under `~/.kiro/settings/` (the registration and the permission rules), because Kiro denies a session any write there;
    - the server restart;
    - the browser SSO and MFA sign-in;
    - approval of the final commit.
  - **The restart method:** the one recorded in `maintenance/kiro-port.md` M6 — Reconnect the `appian` server from the MCP panel (the cheapest action that replaces the process), with a full quit and reopen as the fallback.

## Parameters — determined at runtime, never hardcoded

| Name | How the session determines it |
|---|---|
| `SITE` | the hostname of `LCP_URL` in the `appian` entry of `~/.kiro/settings/mcp.json` (or of the workspace `.kiro/settings/mcp.json` if that defines one, since it wins). Read the entry's `args` and `LCP_URL` only; never print other env values |
| `OLD_INSTALL` | the `--directory` value in the current registration |
| `NEW_INSTALL` | a fresh directory that is not `OLD_INSTALL`; the convention is `~/appian-dev-mcp-server-<build stamp>` once the bundle's `BUILD-INFO.txt` has been read, or the documented `~/appian-dev-mcp-server` if that path is free |
| `BUNDLE` | the newest `lcp-mcp-server-bundle*.tar.gz` or `appian-dev-mcp-server-bundle*.tar.gz` in `~/Downloads` (the download name changed between generations: build `20260930-110421` arrived as `lcp-mcp-server-bundle`), identified by the `build_timestamp` in its `BUILD-INFO.txt`, never by its name or date, and confirmed with the operator if more than one candidate exists |
| `PIN` | the version pin in `reference/toolchain.md` §1: plugin version, build stamp, install path, install date, auth-source hash |
| `SKILL_PIN` | the vendor skill pin in `reference/toolchain.md` §5: the `version=` line of the installed `~/.kiro/skills/appian/.bundle-manifest` (a composer commit), or, for an install that predates bundled skills, the commit of Appian's public `appian/dev-mcp-skills` repository it was copied from |
| `SAIL_PIN` | the sail pin in `reference/toolchain.md` §12: `sail --version` output, binary path, sha256 |

## Step 0 — Bundle (operator step; the session walks them through it)

The bundle downloads from the operator's own Appian site and versions with the site's plugin. Both paths sit behind the site's login. There are two, and the session prints both with `SITE` filled in:

- **`https://SITE/suite/plugins/servlet/stateless/downloads`** is the documented downloads page and the operator-facing entry. Give it first.
- **`https://SITE/suite/plugins/servlet/stateless/lcp-mcp-bundle`** is the direct bundle link that `getDevMcpVersionInfo` prints in its recommendations. It was observed in the tool's output; its download behaviour has not been measured. Offer it as a shortcut, and fall back to the downloads page if it does not produce the bundle.

The session tells the operator to sign in and download the bundle to `~/Downloads`, and waits for confirmation before proceeding.

**Ordering rule.** Run `getDevMcpVersionInfo` first and read its recommendations. If the site's plugin is behind the App Market, the site administrator must update the plugin before anyone downloads — a download taken before that just reinstalls the current generation. If the plugin and the local bundle already carry the same build stamp, there is nothing to update; say so and stop.

## Phase 1 — Install (this session)

1. **Prerequisites.** `python3 --version` must be 3.13 or later (the bundle's `pyproject.toml` states `requires-python`; check it after extraction too). `uv --version` must succeed; if `uv` is missing, install it with `curl -LsSf https://astral.sh/uv/install.sh | sh` and verify. If Python is below the requirement, stop and ask — never attempt a Python upgrade unprompted.
2. **Locate the bundle.** Find `BUNDLE` in `~/Downloads`. If more than one file could be it, or the name carries a browser suffix, confirm the exact filename with the operator. Never delete the bundle.
3. **Inspect before extracting.** List the tarball's top-level entries. `pyproject.toml` must be at the root so that the documented `--directory` layout results; if the archive wraps everything in a folder, extract and adjust `NEW_INSTALL` to that folder. Read the extracted `BUILD-INFO.txt`: its build stamp is the version being installed. If it equals `PIN`'s build stamp, this is the current generation — stop and revisit the ordering rule. If the bundle ships `skills/appian`, read the `version=` line of its `.bundle-manifest`: it should equal `BUILD-INFO.txt`'s `composer_commit` (it did in build `20260930-110421`); report a mismatch before going on.
4. **Install side by side.** `mkdir -p NEW_INSTALL`; `tar -xzf BUNDLE -C NEW_INSTALL`; verify the tree (`src/lcp_mcp_server` present, module name `lcp_mcp_server` unchanged across generations). `OLD_INSTALL` is not modified or deleted; it is the rollback.
5. **Sync and verify.** `uv --directory NEW_INSTALL sync`, then confirm `.venv` exists and `uv --directory NEW_INSTALL run python -c "import lcp_mcp_server, playwright"` succeeds. Then `uv --directory NEW_INSTALL sync --extra browser` — if the bundle defines no `browser` extra the command errors with "Extra `browser` is not defined"; that is harmless when Playwright is already a core dependency, and the session reports it as such rather than as a failure. Then `uv --directory NEW_INSTALL run playwright install chromium`, and verify with `playwright install --dry-run chromium` and a headless launch test.
6. **Link sail from the new bundle.**
   - `NEW_INSTALL/bin/` holds the sail binaries and one setup script per platform. Run the one for this machine (`NEW_INSTALL/bin/setup-mac.sh` on macOS).
   - It repoints an existing `sail` link that points at a sail binary, and refuses to replace anything else. If it refuses, report what `sail` currently resolves to and let the operator decide.
   - Verify: `sail --version` should report the new bundle's version, and `sail --help` should run.
   - `OLD_INSTALL/bin/` keeps the previous binary for rollback.
7. **Install Appian's skill from the same bundle.**
   - **Why the bundle.** From build `20260930-110421` the bundle ships `skills/appian` with a `.bundle-manifest` and an installer, `bin/install-skills.sh`. The bundled skill documents the server it ships with. Appian's public `appian/dev-mcp-skills` repository, where earlier installs copied it from, lags it. Measured on 2026-10-05: that repository's HEAD `6e87fb6` (2026-09-23) differed from the `20260930-110421` bundle in 9 of 66 files. The bundle's copy documents `errorAlertGroupUuid`, which the server had taken in place of `errorAlertGroupName` since build `20260911-210447`. It also documents `expressionFilePath`, which the server had taken since at least 26.6.90 and the public copy never mentioned. A bundle without `skills/appian` predates this; skip the step and say so.
   - **Read the installer before running it**, and diff it against `OLD_INSTALL/bin/install-skills.sh` when that exists. As read from the `20260930-110421` copy, it does the following:
     - It installs into every detected client (`~/.kiro`, `~/.claude`, `~/.codex`). Always pass `--skills-client kiro`.
     - It replaces an installed copy wholesale when every file matches that copy's own `.bundle-manifest`.
     - It refuses to write through a symlink.
     - When the installed copy has no manifest, or has local edits, it does not overwrite. Instead it stages the new copy at `~/.kiro/skills/appian.incoming`.
   - **Diff first.** Compare `~/.kiro/skills/appian` with `NEW_INSTALL/skills/appian`, ignoring `.bundle-manifest` and `.DS_Store`, and report which files differ. If nothing differs and a manifest is present, there is nothing to do.
   - **Installed copy has a manifest** (installed by the bundle's installer). Run `NEW_INSTALL/bin/install-skills.sh --skills-client kiro`. The rollback is `OLD_INSTALL/skills/appian`. If the installer reports local edits, stop and report them. The vendor skill is never edited (`reference/mcp-capability-boundaries.md`: corrections go in the supplemental), so an edit is a breach to show the operator, not something to merge.
   - **Installed copy has no manifest** (a pre-bundle install copied from `appian/dev-mcp-skills`). Don't let the installer stage `appian.incoming`. That folder would sit under `~/.kiro/skills/` with a `SKILL.md` named `appian`, and could register as a second `appian` skill. That has not been measured; avoid it rather than test it.
     1. Ask the operator before moving anything.
     2. Move the old folder out of the skills directory, to `~/appian-skill-rollback/appian-<source>` (for example `appian-dev-mcp-skills-6e87fb6`).
     3. Run the installer. With no destination folder it installs a clean copy with its manifest.
   - **Verify:**
     - `diff -rq NEW_INSTALL/skills/appian ~/.kiro/skills/appian` reports nothing.
     - The installed manifest's `version=` equals `BUILD-INFO.txt`'s `composer_commit`.
     - `~/.kiro/skills/` holds no `appian.incoming`, and the workspace holds no `.kiro/skills/appian`.
     - The new skill is read by sessions started after the restart, the same boundary as the server.
8. **Registration.** Find every Dev MCP registration: `~/.kiro/settings/mcp.json`, and the workspace `.kiro/settings/mcp.json` if it exists. The workspace entry wins for a same-named server.
   - **A session cannot write either file** (Kiro hard-denies it), so this step prepares and checks; the operator edits.
   - **Back up first.** Copy the current file to a dated backup outside `~/.kiro/settings/` (for example `~/appian-devmcp-config-backups/mcp.json.<date>`), so the rollback exists before anything changes.
   - **Show the operator** the current `appian` entry, with env values redacted except `LCP_URL`, and the replacement: the documented block, `uv run --directory NEW_INSTALL python -m lcp_mcp_server` with `env` carrying `LCP_URL`, where only the `--directory` value changes.
   - **If the current entry differs structurally** from the documented shape, propose aligning it to the documentation and flag every difference with what the new server's `config.py` does with each variable. Previous-generation variables such as `LCP_USERNAME`, `LCP_PASSWORD`, `LCP_API_PATH` and `LCP_AUTH_METHOD` are the usual differences.
   - **An `appian-runtime` entry** is the runtime MCP server, a different server this procedure never touches. If any entry other than the Dev MCP is named `appian`, report the shadow (`reference/toolchain.md` §2) and leave the renaming to the operator.
   - **After the operator's edit,** re-read the file (names and `args` only) and confirm only the `--directory` changed.
9. **STOP — phase boundary.** Print exactly this: *"Phase 1 complete. Restart the Dev MCP so it runs the new install: Reconnect the `appian` server from the MCP panel (measured M6 as the cheapest restart; a full quit and reopen is the fallback), and confirm with `pgrep -fl lcp_mcp_server` that the running command shows the new directory. Then open a new chat and say 'continue the update procedure'. The first Dev MCP tool call may open a browser sign-in window: complete SSO and MFA there; the session is captured under `~/.appian-devmcp/`."* Do nothing further in this session.

## Phase 2 — Re-verify (a fresh session after the restart)

1. **Confirm the new server is the one running.** Call `getDevMcpVersionInfo` (this may be the call that opens the browser sign-in; wait for the operator to complete it). Its `mcpServer` build stamp must equal `NEW_INSTALL/BUILD-INFO.txt`; if it still equals the old pin, the restart did not take. Check `pgrep -fl lcp_mcp_server` (the `--directory` in the running command) and the `appian` entry's `args`, then stop. Read the tool's recommendations: plugin and bundle from the same build is the expected state.
2. **Find the real version.** The plugin version and build stamp from the tool; `pyproject.toml` and `__init__.py` in `NEW_INSTALL` (the package version string may not change between generations — the build stamp is the discriminator); any changelog the bundle ships. Record what was found and where.
3. **Re-verify `reference/toolchain.md` §1 against the new source.** Read `NEW_INSTALL/src/lcp_mcp_server/browser_auth.py`, `config.py`, and `server.py`, and `diff` each against `OLD_INSTALL`'s copy. If `OLD_INSTALL`'s build stamp differs from `PIN`'s, a build was installed without a re-pin (it happened: `20260911-210447` ran for two weeks unpinned). Diff against the pinned install too, because the repo text describes that one, and record the gap in §1. State what the code shows for: the default auth method and the environment variables read; the session storage path and layout; persistence across restarts; expiry detection and whether the server reopens the browser itself; logout; anything new. Rewrite the section from the code, not from the old text. Diff the tool inventory too — new tools close boundaries:
   - **What to diff:** the names of the `@mcp.tool`-decorated functions in `tools/*.py` in both installs. Parse them with Python's `ast` rather than a line pattern, because decorators span several lines. A count of `async def` lines also counts helper coroutines (13 of them in DevMCP 26.6.90).
   - **Cross-check:** confirm the new count equals the tools Kiro lists for server `appian`, in the MCP panel or the session's own tool list.
   - **Regenerate the delete deny list.**
     - Every `delete*` and `remove*` tool in the new inventory goes into the `match` list in `kiro-setup/permissions.yaml`, one name per line.
     - Show the operator the added and removed names. The operator merges them into `~/.kiro/settings/permissions.yaml`; the session cannot.
     - The session-start report flags any entry the installed file lacks.
   - **On macOS:** write any extraction with `[[:space:]]`, never `\s`. BSD `sed` does not support `\s` and silently leaves every line unchanged; that is how three helpers were once counted as tools (`reference/mcp-capability-boundaries.md`, tool count note).
4. **Update the version pin** in `toolchain.md` §1: plugin version and build stamp as reported by the tool (with the tool named as the source), `NEW_INSTALL`, today's date, and the sha256 of the new `browser_auth.py`. Keep the "on server update, say 'run the update procedure'" note.
5. **Re-verify sail against `toolchain.md` §12.**
   - `sail --version` must report the new bundle's version.
   - Capture `sail --help` and every subcommand's `--help`, and diff them against the surface §12 records. Count the captured sections before trusting a diff. In zsh an unquoted `$cmds` is not word-split, so a loop over subcommands runs once, and two identical captures of the root help passed for an unchanged surface. Run the loop under `bash` or with `${=cmds}`. Compare commands, flags, value formats, and login modes. Rewrite §12 from the new help, not from the old text.
   - If the operator has a persona session logged in, repeat the read-only measurements against it, stating the account: `pages`, a `load`, `show` with the network blocked, and an unknown target under `--json` for the error stream.
   - Entries that need a write to re-measure are left flagged as not re-measured unless the operator approves a demo write: the submit's pre-form snapshot, `load --fresh`'s destination, the batch drops, and the import-and-logout session sharing.
   - Refresh `SAIL_PIN`: the version string, the binary path, and its sha256.
6. **Re-check the vendor skill against what cites it.**
   - **Diff the old and new copies.** Compare `NEW_INSTALL/skills/appian` with the copy it replaced: `OLD_INSTALL/skills/appian`, or the rollback folder from Phase 1 step 7 for a pre-bundle install. List the files that changed.
   - **Find what cites the changed files.** For each changed file, search the supplemental (`skills/appian-supplemental/SKILL.md`), `reference/`, and `.kiro/steering/` for citations of that file and of the parameters or rules that changed. Where the supplemental corrects the pack, check that the correction still applies to the new text. A correction the new pack makes itself is retired through the promotion loop (core §9), not by deleting it. A new pack instruction that contradicts a measured supplemental entry is reported; the supplemental still wins until a re-measurement rules on it.
   - **Watch for skill changes that announce server changes.** When the new skill describes a parameter differently, check the matching server-behaviour entries in step 7 against the new server first. Example: `errorAlertGroupName` was documented as required on create, and the 20260930 skill documents `errorAlertGroupUuid` instead.
   - **Refresh `SKILL_PIN`** in `toolchain.md` §5: the manifest `version=`, the build it came from, and the install date.
   - **Confirm the supplemental's path to the references still resolves:** `~/.kiro/skills/appian/references/`.
7. **Sweep the repo for old-path and old-behaviour references.**
   - **Names first:** `OLD_INSTALL`, the old state directory, retired variable names.
   - **Then behaviour, which a name sweep misses.** Check every entry in `reference/silent-failure-taxonomy.md` and `reference/mcp-capability-boundaries.md` that describes what the server does:
     - auth expiry and the ping false positive;
     - transport marshalling of test inputs and document content;
     - tool-surface gaps such as instance enumeration, multiple node instances, attended tasks, group membership, and agent reads.

     Include `toolchain.md` §2 and §4, and the sail entries: taxonomy class M, boundaries §10, and toolchain §12.
   - **For each entry:** verify it against the new code, the new help, or a read-only live call, and mark which generation it belongs to. Read the tool's current docstring and parameters, not only the diff. A diff shows what changed since the last install, not what the last re-check missed: three entries contradicted source text that had been there since 26.6.90 (`updateProcessModel`'s node sync, `updateSite`'s page merge, `listColumns`). Leave plugin-side entries that a server update cannot change with a note saying so.
8. **Summarize the behavioural delta** for the operator: what the new server, the new skill, and the new sail do differently, which boundaries narrowed or closed, and which entries could not be re-measured without a write and were left flagged.
9. **Commit and push on approval**, with the message `toolchain: re-verified against Dev MCP <version>`.
10. **Rollback stays available until the next update.** The operator decides when to remove the pieces.
    - **What holds the previous generation:**
      - `OLD_INSTALL`, with its `bin/` sail binary and `skills/appian`;
      - any `~/appian-skill-rollback/` folder;
      - the dated `mcp.json` backup from Phase 1 step 8.
    - **How to roll back:**
      - re-running `OLD_INSTALL`'s setup script points `sail` back at the old binary;
      - `OLD_INSTALL/bin/install-skills.sh --skills-client kiro --force` restores the old skill, provided that bundle shipped one; otherwise move the rollback folder back;
      - the operator restores the `mcp.json` backup and restarts the server.
