# Toolchain and environment

Setup and environment knowledge for an Appian build driven through the Dev MCP from the Kiro IDE. The Dev MCP and sail facts below were measured under Claude Code before the port and do not depend on the client. The Kiro-side statements (registration, restarts, logs, permissions, skills) come from kiro.dev; the nine first-session measurements in `maintenance/kiro-port.md` are now recorded on Kiro IDE 1.2.4 (2026-10-05 to 2026-10-07), so the items those measurements covered are measured and the rest keep their item-level `documented, unmeasured` tags. Everything here is environment-general; site URLs, accounts, and credentials belong in the build's own notes, never in this repo. Everything here was verified against a build log, a build script, the Dev MCP server's own source, or the sail evaluation. §1 records the server version the server-sourced sections describe, and §12 records the sail version. Bracketed S-numbers cite the sail evaluation's measurement record in `examples/persona-verification-walkthrough.md`.

## 1. Dev MCP registration and authentication

**Verified against DevMCP 26.6.105.** The server reports its own version through its `getDevMcpVersionInfo` tool, which reads the plugin's `/meta` endpoint and the bundle's `BUILD-INFO.txt` and compares them. On the verified machine on 2026-10-05 both halves came from the same build, as that tool reported:

- plugin `Appian Dev MCP` 26.6.105, App Market status up to date (latest 26.6.105);
- build stamp `20260930-110421`, `mcp_src_sha 0dbc574fad85d631`, composer commit `eb82064`;
- built from a detached branch rather than the mainline.

The bundle's package version string (`lcp-mcp-server` 0.1.0 in `pyproject.toml` and `__init__.py`) has not changed across three generations and is not a discriminator; the build stamp is. The MCP initialize handshake names the server `Appian-DevMCP-Server` (`FastMCP("Appian-DevMCP-Server")` in `server.py`) and carries no product version. Installed at `~/appian-dev-mcp-server-20260930-110421` on 2026-10-05 from the bundle download `lcp-mcp-server-bundle.tar.gz`; `src/lcp_mcp_server/browser_auth.py` hashes to sha256 `bcf11935a9eca9c6ad48fbc0f0167924013d6dd2b4ecbdd1607ba04bfd45d385`, byte-identical since 26.6.90. This section and §2 describe that build. **On server update, say "run the update procedure" (or `#dev-mcp-update`) — the Kiro session executes `maintenance/dev-mcp-update.md`**, which installs the new bundle side by side, re-verifies this section and §2 against the new server's source, re-checks the server-behaviour entries in the taxonomy and the capability boundaries, and refreshes this pin. The preflight (core §2) compares `getDevMcpVersionInfo`'s report with this pin every session, `sail --version` with the sail pin in §12, and the vendor skill's manifest with the pin in §5, because all three ship in one bundle.

- **Generations seen on the verified machine.**
  - **Before 26.6.90** (`~/lcp-mcp-server`): basic auth by default, `LCP_USERNAME` and `LCP_PASSWORD`, state in `~/.appian-mcp/`.
  - **26.6.90** (build `20260903-195919`, pinned 2026-09-12): the auth default, the environment variable names, the state directory layout, the expiry handling, and the logout behaviour all changed. Each is read from the source below, which is why the update procedure exists.
  - **Build `20260911-210447`** (sail 26.6.95): registered from 2026-09-21 to 2026-10-05 without a re-pin. Its tool set matched 26.6.90's (157 tools). It renamed `createProcessModel`'s `errorAlertGroupName` to `errorAlertGroupUuid`, while the skill installed beside it still documented the old name.
  - **26.6.105** (build `20260930-110421`): the auth path, the state directory, and the configuration variables are unchanged (`browser_auth.py` byte-identical; `config.py` renames one internal property). It adds 42 tools (157 → 199, none removed), a version gate, tool annotations, one environment variable, and Appian's skill in the bundle.

- **What it is.** The Appian Dev MCP is a local server package (`lcp-mcp-server`, Python module `lcp_mcp_server`) run with `uv`. It is downloaded as a bundle that matches the site's DevMCP plugin, from one of two paths behind the site's login. The documented downloads page, `/suite/plugins/servlet/stateless/downloads`, is the operator-facing entry. The direct bundle link, `/suite/plugins/servlet/stateless/lcp-mcp-bundle`, is the one `getDevMcpVersionInfo` prints (`maintenance/dev-mcp-update.md` Step 0). The download arrives as `lcp-mcp-server-bundle.tar.gz` (26.6.90 arrived as `appian-dev-mcp-server-bundle.tar.gz`, and the pre-26.6.90 generation also used the `lcp-mcp-server-bundle` name). A browser appends ` (N)` to a repeated download, so a bundle is identified by the `build_timestamp` in its `BUILD-INFO.txt`, never by its file name. Beside the server it carries the sail binaries (§12) and, from 26.6.105, Appian's `appian` skill with its installer (§5). The bundle is unpacked into a directory of your choosing: `~/appian-dev-mcp-server` in the documentation; the verified machine keeps one directory per build stamp (`~/appian-dev-mcp-server-<build stamp>`) so the previous one stays as rollback. It talks to the site through the plugin's stateless servlet at `/suite/plugins/servlet/stateless/lcp-api`. Setup instructions are Appian's own: `https://docs.appian.com/suite/help/26.8/devmcp.html`. Install is `uv sync` then `uv run playwright install chromium`. The documented `uv sync --extra browser` step errors ("Extra `browser` is not defined") because 26.6.105, like 26.6.90, defines no `browser` extra (its only optional group is `dev`). Playwright is a core dependency that the first sync already installs, so the error is harmless. Where the Playwright download is blocked, `LCP_BROWSER_CHANNEL=chrome` or `msedge` uses a system browser instead.
- **Where it is registered in Kiro** (measured M5 for the default agent, 2026-10-07: design reads returned through it; the 199-tool count was derived from the bundle source and the 200-tool cross-server total, not read from the session's own tool list). In `~/.kiro/settings/mcp.json`, the user-level MCP configuration that every Kiro workspace on the machine reads.
  - **Who writes it:** the operator, from `kiro-setup/mcp.json` (`GETTING_STARTED.md` §1, step g). A session cannot: Kiro hard-denies agent writes to `~/.kiro/settings/` and `.kiro/settings/` (kiro.dev/docs/permissions).
  - **Not the workspace file:** a workspace `.kiro/settings/mcp.json` also works, and replaces a same-named user entry whole, but it is not used here.
    - A field report has workspace servers missing their tools (kirodotdev/Kiro#6122).
    - A committed workspace file is launched in Kiro cloud sessions, where this local server cannot run (kiro.dev/docs/cloud-sessions).
    - `.gitignore` keeps `.kiro/settings/mcp.json` out of git in case one is created.
  - **Restarts on edit:** Kiro hot-reloads the file and restarts only the servers whose entries changed, at the next idle point (kiro.dev/docs/mcp/configuration).
  - **Timeout:** a tool call times out after 120 s by default. The Dev MCP's first call can wait up to five minutes for a browser sign-in, so `kiro-setup/mcp.json` sets `"requestTimeout": 330000`. **Measured M7 (operator-reported 2026-10-05): `mcp.json` honours `requestTimeout`.** A first call returned at 3m06s through a deliberately held sign-in. Without the key, that call would hit the documented 120 s default before the sign-in completes (inferred from the documented default; no call was run without the key). Keep the key.

  Appian's documented block, which is also the complete one for a single-user SSO site, goes under `mcpServers` (`kiro-setup/mcp.json` adds `requestTimeout`):

  ```json
  "appian": {
    "command": "uv",
    "args": ["run", "--directory", "/ABSOLUTE/PATH/TO/appian-dev-mcp-server", "python", "-m", "lcp_mcp_server"],
    "env": { "LCP_URL": "https://<site>.appiancloud.com" }
  }
  ```

  Optional variables, all read by this build: `USERNAME` (names the per-user session directory, lets several registrations run as different users, and makes the server refuse a login by anyone else); `LCP_AUTH_METHOD: basic` with `USERNAME` and `PASSWORD` for a site where no browser can be opened; `LCP_SIGNIN_PATH` (`/suite/?signin=<idp>` to skip a sign-in chooser); `LCP_AUTH_LANDING_PATH` for a custom post-login page; `LCP_BROWSER_CHANNEL`; `LCP_COOKIE_PATH` and `LCP_BROWSER_PROFILE_PATH` as state-path overrides; and the standard `HTTPS_PROXY`, `HTTP_PROXY`, `SSL_CERT_FILE`. The previous generation's variables are gone: `LCP_USERNAME` and `LCP_PASSWORD` are no longer read at all, and `LCP_API_PATH` now defaults to the servlet path that used to have to be set explicitly (its old default was a different endpoint). Leaving `PASSWORD` or `LCP_PASSWORD` in the block without `LCP_AUTH_METHOD` is a startup configuration error, by design, because the default auth method changed from basic to browser. One variable is new in 26.6.105 and stays unset: `SAIL_MCP_ENABLED=true` puts the server in a pipeline mode in which `createInterface` and `updateInterface` refuse an inline `expression` and point at a `generate_interface_sail` tool that this bundle does not register (`tools/interfaces.py`). The variable defaults to `false`.
- **Authentication flow** (read from `browser_auth.py`, `config.py`, and `server.py`). Browser auth is the default. At startup the server loads any persisted session from `~/.appian-devmcp/<hostname>/<USERNAME or default>/cookies.json`, so the common case opens no browser and the stdio handshake is not blocked. When there is no valid session, the first tool call launches a Chromium window (a persistent profile at `browser-profile/` beside the cookie file) at the sign-in path, and you complete SSO and MFA in it within five minutes. When the browser reaches a post-login Appian page (`/suite/tempo`, `/suite/design`, `/suite/sites`, `/suite/actions`, `/suite/records`, `/suite/reports`, or the configured landing path) the server captures the session cookies — `JSESSIONID`, the `__appian*` CSRF tokens, and remember-me cookies where present — asks `/suite/cors/ping` which user it is signed in as, records that username inside the cookie file, and from then on replays the cookies as a `Cookie` header plus the CSRF token on every plugin call. On the verified machine the captured file holds three cookies, the recorded username, an 8-hour expiry, and owner-only permissions. The identity the tools execute as is the account that signed in, and every readback is scoped by that account's group memberships. If `USERNAME` is configured and the browser authenticates as someone else, the server discards the cookies and fails with a message naming both users. All of this is unchanged in 26.6.105. Measured across the update: after the relaunch, the 26.6.105 server reused the session file that the previous build had written, with no sign-in window. The file's modification time did not change across an authenticated `listApplications` call.
- **Session persistence and expiry.** The session is persisted on disk, and the running server also holds a copy in memory. The disk copy is why it survives server restarts and app relaunches. Session cookies carry no expiry, so the server caps their replayable lifetime at 8 hours, and it treats a 401, a 403, or any non-5xx HTML response on the JSON API path as an expired or server-invalidated session — an SSO bounce, whatever status the identity provider used. On expiry it clears the stored cookies, opens the browser window again, and retries the call once, under a lock so concurrent tool calls open a single window. The normal expiry is therefore self-healing: a sign-in window appears mid-session, you complete it, the call proceeds. To end a session or switch users, the server's `logout` tool deletes the per-user state directory — cookies and browser profile together, because the profile caches the identity provider's own session and would otherwise sign the same user straight back in with no credential prompt and no MFA; the equivalent by hand is deleting `~/.appian-devmcp/*`. **`logout` clears only the files.** The running server keeps the session it loaded into memory and replays it on every call until the site rejects it or the server restarts (`browser_auth.py` loads cookies once and reloads only when its in-memory list is empty; `tools/session.py` deletes files and never touches it). So a user switch is `logout` plus a restart of the server process, proven by a new process id (`pgrep -f lcp_mcp_server` before and after), followed by an identity check. Any of the Kiro restarts below replaces the process (measured M6, 2026-10-05); Reconnect from the MCP panel is the cheapest and is the default, with a full quit and reopen as the fallback (core §6). Measured on 26.6.105 under Claude Code, 2026-10-05 (server behaviour, independent of the client): after `logout` removed the whole per-user directory, two design reads through the running server succeeded within seconds, with no sign-in window, the same scope, and no session file written back. Until that restart, the server keeps working as the old account. After it, the first call should open the browser for a full SSO and MFA sign-in, because the profile is gone too (read from source, not yet observed). A leftover `~/.appian-mcp/` directory is the previous generation's state and is not read.
- **Restarting the server is not an auth fix.** A restart cures a server process that has stopped answering, and nothing else. The symptoms:
  - no sign-in window appears when one should;
  - design calls hang;
  - the design-object tools are absent while the server looks connected and `ping` still answers. This was measured once with the previous generation, and the surface came back by the next session.
- **The Kiro restarts** (measured M6, 2026-10-05):
  - the MCP panel: right-click the server → Reconnect, or Disable then Enable;
  - an edit to the server's entry in `mcp.json`, which restarts only that server;
  - a full quit and reopen of Kiro.

  M6 found all of these replaced the process — the PID changed on each. **Reconnect is the cheapest and is the default, with a full quit and reopen as the fallback** if Reconnect does not change the PID. Confirm a new process id with `pgrep -f lcp_mcp_server`.
- **Rule out two causes a restart does not cure first:**
  - **A shadow.** If the tools under `appian` are the runtime family, or the session-start report says the effective `appian` entry does not run `lcp_mcp_server`, another entry holds the Dev MCP's name (§2).
  - **A version-gate refusal.** It names itself ("Refused: this MCP server and the DevMCP plugin on … come from different builds"), and the cure is the update procedure.
- **For auth errors** the documented order is: expect the browser to reopen on the next call; if it does not, `logout` (or delete `~/.appian-devmcp/*`), restart the server, and call again.
- **Logs:** Kiro's MCP panel shows each server's status; right-click a server → Show MCP Logs, or the Output panel's "Kiro - MCP Logs" channel. The panel has shown "connected" for a server whose calls fail (kirodotdev/Kiro#7991), so a design read is the check, never the panel.
- **Preflight, every session.** Before any work, confirm the design-object tool surface is present (not just `ping` and a runtime subset) and make one trivial design read. If the surface is missing, stop and report; it has been measured as transient and returned on its own the next session. The full preflight is in core §2; its machine-side half runs as a SessionStart hook (`.kiro/hooks/session-preflight.json`). `getDevMcpVersionInfo` tells you whether the plugin and the bundle are the same build before you spend a session debugging a tool.
- **The version gate (26.6.105).** The server now enforces that comparison itself (`version_gate.py`, middleware added in `server.py`).
  - **What it refuses.** Every tool call except `getDevMcpVersionInfo` and `logout` fails with a `Refused: …` error when the site plugin's `mcp_src_sha` differs from the bundle's own, or when the plugin is too old to report one (its `/meta` answers 404).
  - **What it lets through.** A `/meta` read that fails for another reason (an unreachable site, a 401, a login page) lets the call through to fail with its own error. A source checkout with no `BUILD-INFO.txt` skips the gate.
  - **Timing.** A match is cached per site for 300 seconds; a mismatch is never cached.
  - **So:** a site-side plugin upgrade under a running server shows up within five minutes as refusals on every design tool. The cure is the update procedure, not a relaunch.
  - **Evidence.** Read from source. The match path was exercised by the first authenticated call after the relaunch; the refusal path has not been exercised.
- **Expression files.** The get, create, and update tools for expression rules, interfaces, and Web APIs take an `expressionFilePath`. The server has taken it since at least 26.6.90; the bundled skill first documents it in 26.6.105 (§5).
  - **On a get,** the server writes the expression to that local path instead of returning it inline.
  - **On a create or update,** it reads the file, which takes precedence over an inline `expression`. It then applies two fix-ups to either source (`tools/expression_fixups.py`): it quotes record type references whose names contain spaces, and it rejects record references without a UUID.
  - **On a successful write,** it writes the fixed text back to the file. So a successful push can change the local copy (§6, §7): read it back and diff it after every push.
  - **Evidence.** Read from source, not exercised live.
- **Tool annotations (26.6.105).** 167 of the 199 tools declare MCP tool annotations: 79 carry `readOnlyHint`, 23 `destructiveHint`. 26.6.90 declared none. A client may use them to decide what to auto-approve. They are the server's own claim about a tool, not a verified property of it.

## 2. Two servers, one name: the identity trap

Pinned to the server version recorded in §1.

Two Appian MCP servers can be configured on one machine:

- the **Dev MCP**: the design surface, executing as the designer account;
- a **runtime MCP**: invoke process, data fabric query, agent invoke, executing as whatever service account its API key belongs to.

**Under Claude Code, registered under the same name, they silently shared one tool namespace, or one hid the other** [S34]. On one machine, with both named `appian`:

- one session carried only the runtime server's 10 tools under the name, with the design tools absent while a same-named server answered;
- after a relaunch, a session carried both sets merged: 167 tools under one prefix (157 + 10 on 26.6.90).

Nothing in a merged tool's name said which server it ran on or as whom.

- **In Kiro, configuration cannot merge two same-named servers; it can still shadow one** (documented, unmeasured).
  - **How Kiro combines configs.** It reads servers from an agent's own `mcpServers`, the workspace `.kiro/settings/mcp.json`, and the user `~/.kiro/settings/mcp.json`, in that priority. A name defined at two levels is replaced whole by the higher one, and distinct names add up (kiro.dev/docs/mcp/configuration).
  - **So the failure that remains is the shadow:** a second `appian` entry at a higher level replaces the Dev MCP.
  - **Where it is caught:** the session-start report names the effective `appian` entry and whether it runs `lcp_mcp_server` (core §2 step 5).
- **The rule: name servers by role.** `appian` for the Dev MCP, the name in Appian's documented registration block (§1), and `appian-runtime` for the runtime server.
  - **Under Claude Code:** renamed that way on the same machine, the next session listed `appian` with the Dev MCP's 157 tools and `appian-runtime` with the runtime server's 10. Under 26.6.105, a session on 2026-10-05 listed 199 under `appian` and the same 10 under `appian-runtime` [S34].
  - **In Kiro:** configuration, hooks and permission rules name a tool by its server, as `@appian-runtime/<tool>` (permissions: `appian-runtime/<tool>`).
    - **Measured 2026-10-05/06 (M8).** The name the session and the hooks see is not stable: `appian::<tool>` with deferred tools (2026-10-05), `mcp_appian_<tool>` (lowercase) with direct exposure after a restart (2026-10-06). Kiro's permission layer matched `appian/<tool>` (single slash, no `@`, camelCase preserved) in both. The **hook-facing** `tool_name` was measured 2026-10-06 as `mcp_appian_getdevmcpversioninfo`. The `.kiro/hooks/gates.json` matchers and `.kiro/scripts/plan_gate.py` now target `mcp_appian_<tool>` while tolerating the earlier `appian/`, `appian::`, `@appian/` forms, scoped to exclude the `appian-runtime` and `appian-public-docs` servers; reads are matched case-insensitively (the `mcp_appian_` form lowercases the tool). Because the form is unstable, the permission rules (`appian/<tool>`, stable in both sessions) are the enforcing surface and the matcher is deliberately multi-form (see `maintenance/kiro-port.md` M8 and `silent-failure-taxonomy.md` A).
- **The symptom of a shadow:** the preflight's design-surface check fails while `appian` looks connected, or the tools under `appian` are the runtime family.
- **The tell between families holds.** Dev MCP tools are camelCase and unprefixed (`listRecordTypes`, `getRecordType`, `testRule`, `testProcessModel`, `createExpressionRule`). Runtime tools are snake_case with a product prefix (`appian_invoke_process_model`, `appian_data_fabric_sql_query`, `appian_search_tools`, `appian_invoke_agent`) plus `ping`.
- **The consequence of using the wrong family:** a process started through the runtime server under a foreign service account completes green with every row-secured read empty and every PK-targeted write succeeding. See `silent-failure-taxonomy.md`.
- **The rule for use:** design-session work uses the Dev MCP only. Runtime tools are not used for tests or checks, and the service account gets no scope in the application.
  - **In Kiro the ban is the operator's `~/.kiro/settings/permissions.yaml` deny rule for `appian-runtime/*`** (core §6). Measured 2026-10-06 refusing before the call reaches the server (M2c, the delete-deny on the same deny mechanism), and it matches on the stable `appian/<tool>` form. A PreToolUse hook once duplicated this guard but was removed, because a hook matcher keyed on the tool-name form is fragile (the form changed between sessions, M8); where a permission rule and a hook cover the same guard, the permission rule is relied on.
- **Confirming identity:** a throwaway expression rule returning `loggedInUser()`, run through `testRule`, then deleted. The delete needs the operator's permission switch (core §6).
- **Where the runtime server comes from.** If a machine uses it at all, it is a remote entry under `appian-runtime` in `~/.kiro/settings/mcp.json`. Kiro's remote form takes `url` and `headers`.
  - **The key stays out of the file:** the service-account API key goes into the `Authorization` header from an environment variable, never as a literal.
  - **Expansion is limited:** the IDE expands `${VAR}` only for variables approved in its "Mcp Approved Env Vars" setting (documented, unmeasured; kiro.dev/docs/mcp/configuration).
  - **History.** Under Claude Code it arrived through the Claude desktop app's own config, by way of the `mcp-remote` bridge. It was invisible to the client's server listing, and the app rewrote that file from memory [S34]. None of that applies in Kiro.

## 3. Docs-search MCP registration

- **What it is.** Appian's public documentation search, a remote MCP server registered beside the Dev MCP in `~/.kiro/settings/mcp.json` (§1), in Kiro's remote form:

  ```json
  "appian-public-docs": { "url": "https://appian-docs-public.mcp.kapa.ai" }
  ```

  Its tool is `search_appian_knowledge_sources`. It is consulted before any layout edit and before any uncertain parameter, keyword, or icon name (core §5).
- **It expires.** Its token expires and the server drops out of a session with no warning beyond the tool being unavailable.
  - When that happens, say so in the response and settle the question by measurement on the instance. Do not silently skip the grounding step.
  - The operator re-enables or re-authorizes it afterwards from Kiro's MCP panel. Kiro documents OAuth for remote servers; how this server behaves there is unmeasured.
- **What it is for and not for.** It establishes what a parameter is and what the general component surface documents. It cannot establish what a specific environment can do; a working example on the instance outranks it, and "the docs do not mention it" is never evidence of absence.

## 4. Inherited servers and context (check for them)

A Kiro session receives more than this repo configures (documented, unmeasured):
- every server in the user-level `~/.kiro/settings/mcp.json`, in every workspace;
- the servers bundled in installed Powers (kiro.dev/docs/powers);
- global steering in `~/.kiro/steering/`, global skills in `~/.kiro/skills/`, and `AGENTS.md` files, which Kiro always includes.

So a session can carry tool servers and instructions that nothing in the repo mentions.

- **Why it matters.** A tool in a session may belong to a server nobody registered for this build, running under whatever account it was configured with. That is the same class of trap as §2, one level up: the identity behind a tool is not visible from the tool's name.
- **How to check.** At preflight:
  - read the session-start report's server list (names only);
  - read Kiro's MCP panel, which lists every server the session has, Powers included;
  - read the session's own tool listing.
- **Rule.** A build names the servers it uses (Dev MCP, docs-search, and any project-specific server) in `.kiro/steering/project.md`.
  - Every other server present in the session is ignored, and no data leaves the build through a server the build did not name.
  - A Power that adds MCP servers is not installed on a build machine without naming them there.

**Under Claude Code** the same trap came through the Claude desktop app's connectors, which every Claude Code session inherited invisibly. The history is in the source repo.

## 5. Skills and packs

- **Vendor pack.** Appian's base skill for the Dev MCP. From build `20260930-110421` it ships inside the Dev MCP bundle as `skills/appian`. Earlier bundles did not ship it, and it was copied from the `skills/appian` folder of Appian's public repository `https://github.com/appian/dev-mcp-skills`. The skill is Appian's. This repo never carries a copy of it; the only skill this repo holds is `skills/appian-supplemental`.
  - **Where it lives in Kiro.** At user level as `~/.kiro/skills/appian/`, with `SKILL.md` at the top of that folder. Its `references/` directory carries the layout, component, and object references that the supplemental names for grounding. Load the applicable references before object work.
  - **How Kiro loads it** (documented, unmeasured):
    - at startup Kiro reads only each skill's name and description;
    - it loads the full text when a request matches the description, or when the skill is invoked as `/appian`;
    - so core §1 invokes it explicitly (kiro.dev/docs/skills).
  - **Never as a workspace skill.** Appian's README says to add the skill in Kiro as a workspace skill in `.kiro/skills/`, from the public repository. Don't:
    - a workspace skill overrides a same-named user-level one;
    - the public repository lags the server, as the next bullet shows.

    The session-start report flags a workspace `.kiro/skills/appian`.
  - **It versions with the server.** The bundled copy carries a `.bundle-manifest`:
    - its first line, `version=<commit>`, equals the bundle's `BUILD-INFO.txt` `composer_commit` and the plugin's `composerCommit` from `getDevMcpVersionInfo` (all three matched for build `20260930-110421`);
    - each further line is a sha256 and a file path.

    The skill documents the server it ships with. On 2026-10-05, the public repository's HEAD `6e87fb6` (2026-09-23) differed from the `20260930-110421` bundle in 9 of 66 files.
    - **A parameter the server renamed.** The bundle's copy documents `errorAlertGroupUuid`, which replaced `errorAlertGroupName` on `createProcessModel` in build `20260911-210447`. The public copy still documented the old name.
    - **A parameter the public copy never documented.** The bundle's copy also documents `expressionFilePath`, which the server has taken since at least 26.6.90 (§1).

    Take the skill from the bundle that matches the registered server, not from the public repository.
  - **Pinned version.** Manifest `version=eb82064a6746afde1639d2c9f2c731edab5e2229`, from the bundle of build `20260930-110421` (DevMCP 26.6.105). On the verified machine it was installed for Claude Code on 2026-10-05 and was byte-identical to the bundle's `skills/appian`. A Kiro machine installs the same bundle copy under `~/.kiro/skills/appian`. The pin is the manifest line, wherever it is installed.
  - **How to install or update it.** Run the bundle's `bin/install-skills.sh --skills-client kiro`. Read from the installer:
    - it writes `~/.kiro/skills/appian`;
    - without the flag it also writes into `~/.claude` and `~/.codex` when they exist.

    The update procedure (`maintenance/dev-mcp-update.md`, Phase 1 step 7) runs it with every server update.
    - **When it replaces the installed copy:** only when every file matches that copy's own manifest. It then replaces the copy wholesale.
    - **When it stages instead:** when the installed copy has no manifest, or has local edits, it does not overwrite. It stages the new copy at `~/.kiro/skills/appian.incoming`, under the skills directory, where it could register as a second `appian` skill (unmeasured). For a copy without a manifest, move the old folder outside `~/.kiro/skills/` first, so the installer writes a clean copy.
    - **Never edit the installed copy.** Corrections belong in the supplemental (`reference/mcp-capability-boundaries.md`), so the copy always matches its manifest and updates apply wholesale.
  - **How to check for an update.** Compare the installed manifest's `version=` with `getDevMcpVersionInfo`'s `plugin.composerCommit`. The preflight does this (core §2 step 4).
- **appian-supplemental.** Installed at `~/.kiro/skills/appian-supplemental/SKILL.md` from this repo's `skills/appian-supplemental/`.
  - It corrects the pack where the pack is measured wrong, and carries the portable method.
  - It meets Kiro's skill format: its `name` matches its folder, and its description is under 1024 characters.
  - Core §1 invokes it as `/appian-supplemental`.
  - Grow it only through the promotion gate in core §9.
- **Frontend design guidance.** Under Claude Code a frontend-design plugin skill was loaded before any interface layout or styling edit. It is a Claude Code plugin with no Kiro equivalent in this port.
  - Layout grounding is now the docs-search gate (core §5) plus the vendor pack's layout references that the supplemental names.
  - Installing a frontend design skill or Power is a candidate (`maintenance/kiro-port.md` C3), not a requirement.
- **Project skill.** A workspace skill, `.kiro/skills/<prefix>-standards/SKILL.md` inside the build folder.
  - It carries only what is specific to that build: palette, naming prefix, layout applications.
  - Environment-general facts discovered while building it are written to the supplemental as candidates, never to the project skill.

## 6. Local working files

- **`.work/`** holds byte-exact copies of deployed SAIL (`<Object>.sail`) and the harness generators that derive throwaway verification interfaces from them. Every `update*` call over the Dev MCP is a full replacement of the object's expression (and `updateProcessModel.nodes` and a node's `data` section are full replacements too, as measured before 26.6.90; the source since then describes `nodes` as a sync matched by id, unmeasured — `mcp-capability-boundaries.md` §4), so the local copy is the thing edited and the environment is the thing pushed to, then read back.
- **`prompts/`** holds the build prompts as numbered files (`prompts/NNN-<slug>.md`, see `GETTING_STARTED.md` §4); `prompts/model/` holds every word a model inside the application is given, as files, with `prompts/model/_generated/` for the SAIL mirrors and a checksum lock file (see §7 and `patterns.md`). The template ships the directory empty.
- **`mockups/` and `agent/`** ship empty and are described in `patterns.md`; **`fixtures/`** is an optional per-build directory for hand-authored verification fixtures and their re-date script. External-system scripts a human runs (warehouse DDL, procedures, verification queries) live in a folder named for that system, and are statically checked before hand-off (tokenised with comments and strings stripped, parentheses balanced, forbidden tokens absent, expected counts of bodies and checks) with unresolved values left as deliberately invalid markers so nothing deploys silently.
- **Reading spreadsheets without extra packages:** an `.xlsx` is a zip; `unzip` plus the standard library's `xml.etree` over `xl/worksheets/sheet1.xml` and `xl/sharedStrings.xml` reads it without `openpyxl`. Generators stay standard-library, deterministic, and md5-stable across runs, take an explicit `--as-of` date so a diff isolates the edit from date drift, and put their assertions at the bottom.

## 7. Source-edit pattern: Python string replacement with asserts

Edits to large deployed sources (a 300 KB wizard, `BUILD_PLAN.md`, `TODO.md`) are made by a short Python script rather than by hand, and the script **asserts the anchor is unique before replacing it**:

```python
import pathlib
p = pathlib.Path(".work/Some_interface.sail")
s = p.read_text()
old = "  local!removedCsv: \";\","          # an exact, unique anchor
new = "  local!removedCsv: \";13;30;\","
assert s.count(old) == 1, s.count(old)     # 0 means the source moved; 2 means the anchor is ambiguous
s = s.replace(old, new, 1)
p.write_text(s)
```

Rules that make this safe:

- One anchor, one assert, one replacement; a failed assert is the signal that the source changed since the anchor was chosen, which is exactly when a blind edit would land in the wrong place.
- Whole-file read and write; no regex without an anchored, counted match.
- Anything derived from the source is computed from it, never listed by hand (a harness's hidden unused-locals block is computed from the declared locals that appear exactly once; comments are stripped before counting so prose naming a variable is not counted as a reference).
- Generated mirrors of a source-of-record file carry a checksum lock (`sha256` of the source, written beside the mirror) and a `--check` mode that fails when the mirror is stale, so drift between a repo file and a deployed rule is detectable rather than silent.
- After the edit, push the object over the Dev MCP and verify by readback and render, not by the edit having applied locally.
- **Fingerprint every round trip.** After every save, flip, and restore, read the deployed source back and compare it to the local intended copy with `md5` (a readback may differ only by a trailing newline); `diff` a restored source against its pre-change file and count changed code lines versus comment-only hunks; a refactor is proven by feeding a real past run's stored input through the old and new rule and comparing the digests character for character. Note that a probe saved to an object counts as a version — record which versions were probes.

## 8. Document pipeline

- **Generated documents are built with the standard library only and are byte-stable.** The document generators use no third-party packages (no `openpyxl`, no `reportlab`), no `rand()` and no `today()`, so the same input produces the same bytes on every run (checked by `md5`), which is what makes a demo identical at every rehearsal and a multi-run agent-consistency test meaningful.
- **Generated documents are kept pure ASCII so they survive the Dev MCP's string-typed upload.** `uploadDocument` round-trips content through UTF-8 and doubles every byte above `0x7F` (a 32-byte probe stored as 64), so a CSV is written with `encoding="ascii"`, and a PDF is hand-built with uncompressed content streams and WinAnsi text, encoded as latin-1 through an escape function for parentheses and backslashes — such a PDF uploaded intact. A spreadsheet is a ZIP (1,889 of one file's 4,699 bytes were non-ASCII, including control bytes) and cannot be uploaded at all; it is dropped into the folder by hand and confirmed intact by reading `document(id, "size")` against the local file before anything is wired to it.
- **Word templates and their payloads are one contract** (supplemental §8): regenerate templates outside Appian, upload as a new version of the existing document, prove generation by existence and size, and treat literal `${…}` survivals, empty loop tables, and pagination as browser-only checks.
- **An animated GIF was encoded by hand** (no image library on the machine), decoded back frame by frame before it went anywhere, and served at `size: "FIT"`, because any other size resamples it to one flattened frame.

## 9. Non-ASCII and escaping in source

- **The Dev MCP transport is not uniform about non-ASCII.** `uploadDocument` doubles high bytes (§8); an expression payload carrying a raw `❄` (U+2744) round-tripped the transport intact (`len` 1, code 10052), so the doubling is specific to document upload. Interface and rule sources in both builds carry raw UTF-8 characters (middle dots, em dashes, glyph markers), and the HTML mockups are raw UTF-8 with a `charset` meta tag; no source file in either build uses `\uXXXX` escapes.
- **SAIL has no backslash escapes.** A pass that wrote `\"`-style escapes into a SAIL literal shipped a defect; the house style for attribute-heavy emitters is `local!q: char(34)` concatenated in, because SAIL's doubled-quote form is miscountable by eye.
- **Values that reach XML are escaped by one dedicated rule** (`& < > " '`, ampersand first), and the escaping is proven arithmetically — every `&` in the output counted against the entities it opens — not by inspection.

## 10. Browser checks and personas

- **Persona checks split by kind** (core §4). The session checks content, field state, visibility, navigation, record-view actions, and behaviour on published pages through sail as the persona (§12), from sessions the operator logged in. The design account's own reads prove nothing about a persona [S32].
- **What stays a browser check owned by a human**, written into `TODO.md` as a checklist with steps, personas, and expected strings:
  - geometry and paint;
  - document access as a persona, since sail cannot follow a download link [S9];
  - plain URL links;
  - anything on an interface not placed on a page;
  - any persona without a local account.
- A browser driven by the session cannot stand in for a persona either: it lands on the site's SSO, and a session never types credentials.
- Screenshots supplied by the human settle the geometric questions; a build does not ask for them to be closed by fixing card heights or pinning widths.

## 11. Evidence from human-run external consoles

When a human must run something in an external console (a warehouse worksheet, an admin tool) and paste evidence back, deliver **one statement that returns one grid** with `check_name | result | detail` and `PASS`/`FAIL` per row. Multi-statement blocks whose results must be clicked through or exported one at a time are not evidence: the console shows one result at a time and exports only the visible one. Setup scripts may run many statements; their verification is a separate one-grid statement. Where intermediate states are needed, use the console's scripting block form so the whole check runs as one statement and an exception handler appends a FAIL row rather than stopping the output.

## 12. The sail CLI: persona sessions from the terminal

**Verified against sail 26.6.105.**

- The binary: `~/appian-dev-mcp-server-20260930-110421/bin/sail-darwin-arm64`, sha256 `3fb5ba2ebbb2552935d1521bac0fa458d83dd95692af4d00a1e193197afcd3e4`, linked as `~/.local/bin/sail`.
- It shipped in the DevMCP 26.6.105 bundle installed per §1, and `sail --version` reports `sail version 26.6.105`, the bundle's own version, as 26.6.90 did for its bundle [S1]. The intermediate build `20260911-210447` carried sail 26.6.95.
- The preflight (core §2) runs `sail --version` beside `getDevMcpVersionInfo` every session. The update procedure (`maintenance/dev-mcp-update.md`) re-links and re-verifies sail along with the server, because they ship in one bundle.
- Everything below was read from `--help`, read from the bundle's setup scripts, or measured in the evaluation recorded in `examples/persona-verification-walkthrough.md`. Nothing is taken from the binary's symbols, which misreported the surface [S3].
- **Re-verified for 26.6.105 on 2026-10-05.**
  - **Help.** The root help and every subcommand's `--help` were captured and diffed against 26.6.90's. Everything is byte-identical except four additions: page groups in `pages` and `load`, a date-range value in `interact`, and record actions without a start form in `navigate`. They are folded in below. 26.6.95's help was identical to 26.6.90's.
  - **Setup script.** `setup-mac.sh` is byte-identical to 26.6.90's.
  - **Read-only measurements, as `alex.analyst` via sail:**
    - `pages` and `load` worked; a `load` took 0.49–0.63 s.
    - `show` with every proxy variable pointed at a dead port succeeded in 0.06 s while `pages` failed with a proxy error, so `show` still sends no request [S6].
    - An unknown `navigate` target under `--json` exited 1 with 0 bytes on stdout and the error on stderr [S23].
  - **Not re-measured,** because each needs a write: the submit's pre-form snapshot [S13], `load --fresh`'s destination [S13], the batch rules [S14, S20], and the import-and-logout session sharing [S31]. They stand as measured on 26.6.90.

### What it is and how it is installed

- **What it is.** A single Go binary: a command-line client for Appian's SAIL interfaces.
  - It logs in as an account and exchanges the same SAIL UI JSON a browser would. Requests go to the site's REST endpoints (for example `/suite/rest/a/sites/latest/<site>/nav`), and the stored UI is the server's component tree.
  - It has no browser engine and renders nothing. That is why it sees component state and style values but no computed layout [S8].
  - Every command that leaves a UI on screen prints a listing ("On screen there are N actions you can take and M read-only values") and stores the full UI beside it.
- **Where it ships.** The Dev MCP bundle's `bin/` holds three binaries (`sail-darwin-arm64`, `sail-linux-amd64`, `sail-windows-amd64.exe`) and one setup script per platform [S1].
- **What `setup-mac.sh` does** (read from the script):
  - clears the Gatekeeper quarantine flag a downloaded binary carries;
  - links `sail` into `/usr/local/bin`, or into `~/.local/bin` when that is not writable, warning that the fallback may not be on `PATH`;
  - refuses to replace a `sail` that is not its own link;
  - repoints an existing link that points at a sail binary, so re-running it from a newer bundle moves `sail` to that bundle;
  - finishes by running `sail --help` to prove the binary executes.

  On the verified machine it took the `~/.local/bin` fallback [S1]. The macOS binary is arm64 only.
- **`setup-windows.bat`** states in its own header that it has not been run on Windows. It copies rather than links, and edits the user `PATH`.

### Commands and output

- **Command surface, from `--help`** [S2]:

  | Command | What it does |
  |---|---|
  | `pages <site>` | Lists the pages the account can see, in tab order, marking the default and the loaded page. Each page is printed with the path that loads it, in parentheses. From 26.6.105, a page group is listed as a heading with its pages indented under it. |
  | `load <site> [page]` | Fetches a page by URL stub, tab label, or (from 26.6.105) the `g.<group>.p.<page>` path that `pages` prints for a page inside a group. A URL stub is unique only within its group, and a label works unless two groups use it. A group itself cannot be loaded. `--fresh` deliberately discards entered values; otherwise a load over a page with interactions is refused [S24]. |
  | `show <site>` | Re-prints the stored page; no request is sent [S6]. |
  | `navigate <site> <target>` (alias `nav`) | Follows a record link, tab, related action, or process launch. From 26.6.105 the help also covers a record action whose process model has no start form: following it starts the process and lands on the form the process chains into, and the report says so. That is a launch, not reversible by `back`. |
  | `interact <site> <ref> [<value>] …` | Sets fields and presses buttons; `--confirm` for targets with a browser confirmation dialog. |
  | `back <site>` (aliases `close`, `dismiss`) | Discards the current UI and restores the one it came from, closing a related-action form without submitting. |
  | `login <host> [site]` | Stores a session; takes `--from-devmcp` and `--user`. |
  | `logout` | Revokes the session on the server and deletes local state. |
  | `completion`, `help` | Shell completion and help. |

  Global flags are `--data-dir`, `--json`, and `-v`/`--version`. There is no identity command.
- **Reading the listing.** Each line is a ref, quoted exactly as it must be passed, followed by its kind:

  | Kind | Meaning |
  |---|---|
  | `<display>` | Text on the page. The root help says this includes a chart's plotted values. |
  | `<navigate>` | A link, with what following it does: "opens a record view", "opens a related action form", "launches a process (not reversible)". |
  | `<click>` | A button or link to press. |
  | `<index>` | A choice field, followed by its `choices:` line. |
  | `<text>`, `<date>`, `<search>` | Text, date, and picker or search fields. |
  | `<grid>` | A grid, with `handle:` lines for sort columns, search, refresh, and pages. |
  | `<url>` | A plain hyperlink no sail command can follow. |

  Also on the listing:
  - Field state is bracketed: `[REQUIRED]`, `[INVALID]`, `[DISABLED]`, `[READONLY]`.
  - A `confirm:` line marks a target the browser would confirm first.
  - Refs beginning `⌗` are ones sail synthesised for unnamed or repeated components. The help says they hold across reloads; they renumber when a re-render removes a sibling [S22].
  - An ambiguous target is listed as unaddressable ("this name leads to more than one destination") [S9].
- **The listing is a summary; the YAML is the page.** Each load, navigate, or interact overwrites two files per site in the data directory: `<site>-ui.json` (the full tree) and `<site>-ui-concise.yaml` (the same content, compacted). For one dashboard page they were 572,942 and 154,694 bytes [S5]. Grid rows past the second, tag values, milestone details, and a changed sort order are only in these files [S7]. Read the YAML whenever the question is about values.

### Driving components

- **Value formats, from `interact --help`:**
  - Buttons and links take no value. Text, paragraph, and number fields take the literal text.
  - Dropdowns, radios, and checkboxes take the **1-based index** of the choice: "1,3" for multi-select, "" for none. A dropdown empties by selecting its placeholder.
  - Dates take `YYYY-MM-DD` or `M/D/YYYY`; anything else is refused before sending [S21].
  - A record-list date-range filter takes two dates separated by `..` (`"2026-02-01..2026-07-01"`). Either side may be left out for an open end, and `""` clears the filter. This is new in 26.6.105's help and has not been exercised.
  - File uploads take a local path.
  - Grids, charts, tabs, and hierarchies take a `handle:` line. Pickers and record-grid searches take a handle plus the search text.
- **Batching.** Several pairs in one command go out as one request, resolved before sending: an unresolvable ref fails the whole command and nothing is sent [S20]. A target that takes no value may only end the batch; mid-batch, the error names the next token as a component with no value [S14].
- **Addressing, as measured** [S3, S14]:
  - `interact` resolves a label case-insensitively and by any unambiguous beginning. It also resolves a full component id, but not an id prefix.
  - `navigate` resolved a shortened target only with its `⤴` marker, despite its help saying the marker is optional. The full label resolved without it.
- **`--json` for agents.**
  - `pages` returns `default`, `loaded`, `pages` (each with `default`, `label`, `loaded`, `path`, `stub`; `path` is new in 26.6.105), `site`, and `status`.
  - `interact` returns `status`, `changed`, `changedFields`, `options`, `validations`, `movedNothing`, `conciseUiPath`, `site`, and `ui` [S12].
  - Errors do not come back as JSON. They go to stderr as plain text, with stdout empty and a non-zero exit [S19, S23], so check the exit code before parsing.
  - A validation-blocked submit returns `status: "ok"` and exit 0 [S12].

### Sessions and login

- **Sessions and storage.**
  - The data directory defaults to `$SAIL_HOME`, then `~/.sail`. `--data-dir` sets it per command and isolates sessions completely [S26].
  - The directory is created `0700`. `session.json` is `0600` and holds the host, the session cookies, the CSRF token, a timestamp, and the username typed at login, plus `"source": "devmcp"` for an import [S25, S30]. Its keys are `cookies`, `csrfToken`, `hostname`, `timestamp`, and `username` (read on 2026-10-05 from five persona sessions). The host's key is `hostname`, not `host`.
  - `session.json` is a bearer credential: a copy authenticated from another directory [S27].
  - `logout` invalidates the session on the server and deletes `session.json` and every page file, leaving the directory [S28].
- **Login.**
  - `SAIL_USERNAME` and `SAIL_PASSWORD` in the environment, then `sail login <host>`, store a session for later commands.
  - The account must be a local Appian account; on a site that also has SSO, that is a test account rather than an SSO identity. A login with neither the variables nor `--from-devmcp` is refused, naming the variables [S29].
  - `--from-devmcp` imports the session the Dev MCP captured with its browser for the same host; `--user` picks one when several identities are cached. It checks the session against the site first and names the authenticated user once [S29, S30].
  - The imported session is the Dev MCP's own server session, not a copy of it (core §6) [S31].
- **Speed, measured on one site:** `load` 0.72–1.83 s, `navigate` 0.36–1.41 s, a submit 0.54 s, `show` 0.20 s [S5, S6, S10, S11, S13].
