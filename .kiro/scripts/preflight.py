"""SessionStart hook: the machine-side half of the session preflight (core §2).

A SessionStart hook cannot block the session and cannot call MCP tools; on exit 0 its
stdout is added to the agent's context (kiro.dev/docs/hooks/types). So this script runs
every check that needs only the filesystem, git, and sail, prints a short report, and
ends with the steps the agent must run itself through the Dev MCP. It always exits 0,
even on its own errors, so the report (or the error) reaches the session.

It never prints a credential: sail's session.json and the MCP config's env values are
read for named fields only.
"""

import json
import os
import pathlib
import re
import subprocess
import sys

from method_lib import ROOT, build_param, open_measurements, plan_status

HOME = pathlib.Path.home()
KIRO = pathlib.Path(os.environ.get("KIRO_HOME") or HOME / ".kiro")  # KIRO_HOME: kiro.dev/docs/configuration
lines = []


def out(text=""):
    lines.append(text)


def run(cmd, timeout=20):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout + r.stderr).strip()
    except FileNotFoundError:
        return 127, f"{cmd[0]}: not found"
    except subprocess.TimeoutExpired:
        return 124, f"timed out after {timeout}s"


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except Exception as error:
        return {"__error__": repr(error)}


def pin(pattern, path="reference/toolchain.md"):
    try:
        m = re.search(pattern, (ROOT / path).read_text(encoding="utf-8"))
        return m.group(1) if m else None
    except Exception:
        return None


def section_port():
    open_ids = open_measurements()
    if open_ids:
        out(f"PORT UNMEASURED: {len(open_ids)} first-session measurement(s) open ({', '.join(open_ids)}). "
            "Run them before any build work: say #kiro-first-session (maintenance/kiro-port.md).")
    else:
        out("Port: every first-session measurement in maintenance/kiro-port.md is ticked.")


def section_plan():
    populated, reason = plan_status()
    if populated:
        out("Step 1 plan: populated.")
    else:
        out(f"Step 1 plan: NOT PLANNED: {reason}. Report it and stop build work; the PreToolUse plan "
            "gate refuses every Dev MCP write until the plan is real (core §2 step 1).")


def server_entries():
    """{scope: {name: entry}} for the workspace and user MCP configs."""
    scopes = {}
    for scope, path in (("workspace", ROOT / ".kiro" / "settings" / "mcp.json"),
                        ("user", KIRO / "settings" / "mcp.json")):
        data = read_json(path)
        if data is None:
            continue
        if "__error__" in data:
            out(f"Step 5 registration: {path} is not valid JSON ({data['__error__']}).")
            continue
        scopes[scope] = data.get("mcpServers", {}) or {}
    return scopes


def bundle_dir(entry):
    args = entry.get("args") or []
    if "--directory" in args and args.index("--directory") + 1 < len(args):
        return pathlib.Path(os.path.expanduser(args[args.index("--directory") + 1]))
    return None


def section_registration_and_versions():
    scopes = server_entries()
    if not scopes:
        out("Step 5 registration: no MCP config found at .kiro/settings/mcp.json or "
            "~/.kiro/settings/mcp.json. The operator writes ~/.kiro/settings/mcp.json from "
            "kiro-setup/mcp.json (GETTING_STARTED.md §1); a session cannot.")
        return None
    for scope, servers in scopes.items():
        out(f"Step 5 registration: {scope} config defines: {', '.join(sorted(servers)) or '(none)'}.")
    # Kiro: a same-named server at a higher level replaces the lower one whole
    # (workspace over user; kiro.dev/docs/mcp/configuration).
    effective = None
    for scope in ("workspace", "user"):
        if "appian" in scopes.get(scope, {}):
            effective = (scope, scopes[scope]["appian"])
            break
    if not effective:
        out("Step 5 registration: NO server named `appian` is configured. The Dev MCP is not registered.")
        return None
    scope, entry = effective
    runs_devmcp = "lcp_mcp_server" in " ".join([str(entry.get("command", ""))] + [str(a) for a in entry.get("args") or []])
    if runs_devmcp:
        out(f"Step 5 registration: the effective `appian` entry ({scope}) runs lcp_mcp_server.")
    else:
        out(f"Step 5 registration: SHADOW: the effective `appian` entry ({scope}) does not run "
            "lcp_mcp_server, so it is not the Dev MCP (core §6, reference/toolchain.md §2).")
    if "appian" in scopes.get("workspace", {}) and "appian" in scopes.get("user", {}):
        out("Step 5 registration: `appian` is defined in BOTH configs; the workspace entry replaces the user entry.")
    for key in ("timeout", "requestTimeout"):
        if key in entry:
            out(f"Step 5 registration: `appian` sets {key}={entry[key]} (Kiro honours requestTimeout in mcp.json; measured M7).")

    directory = bundle_dir(entry)
    info = {}
    if directory and (directory / "BUILD-INFO.txt").is_file():
        for line in (directory / "BUILD-INFO.txt").read_text().splitlines():
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                info[k.strip()] = v.strip()
        stamp_pin = pin(r"build stamp `(\d{8}-\d{6})`")
        stamp = info.get("build_timestamp")
        verdict = "matches" if stamp == stamp_pin else f"DIFFERS from the toolchain §1 pin {stamp_pin}"
        out(f"Step 4 versions: registered bundle {directory} is build {stamp}, which {verdict}.")
    else:
        out(f"Step 4 versions: cannot read BUILD-INFO.txt for the registered bundle ({directory}).")
    return info


def section_sail_and_skill(info):
    sail_pin = pin(r"\*\*Verified against sail ([\d.]+)\.\*\*")
    rc, text = run(["sail", "--version"], timeout=10)
    if rc == 0:
        version = text.split()[-1] if text else "?"
        verdict = "matches" if version == sail_pin else f"DIFFERS from the toolchain §12 pin {sail_pin}"
        out(f"Step 4 versions: sail {version}, which {verdict}.")
    else:
        out(f"Step 4 versions: sail does not run ({text}). Route persona checks to the browser "
            "checklist until it is installed (GETTING_STARTED.md §1).")

    manifest = KIRO / "skills" / "appian" / ".bundle-manifest"
    if manifest.is_file():
        version = next((l.split("=", 1)[1].strip() for l in manifest.read_text().splitlines()
                        if l.startswith("version=")), None)
        bundle_commit = info.get("composer_commit") if info else None
        verdict = ("matches the registered bundle's composer_commit" if version and version == bundle_commit
                   else f"DIFFERS from the registered bundle's composer_commit {bundle_commit}")
        out(f"Step 4 versions: Appian skill manifest version={version}, which {verdict}. "
            "AGENT: also compare it with getDevMcpVersionInfo's plugin.composerCommit.")
    else:
        out("Step 4 versions: ~/.kiro/skills/appian has no .bundle-manifest (not installed from the "
            "bundle). Report it as drift (reference/toolchain.md §5).")
    if (ROOT / ".kiro" / "skills" / "appian").exists():
        out("Step 4 versions: WARNING: a workspace .kiro/skills/appian exists; it overrides the "
            "user-level bundle copy (workspace skills win). Remove it unless the operator chose it.")
    if (KIRO / "skills" / "appian.incoming").exists():
        out("Step 4 versions: WARNING: ~/.kiro/skills/appian.incoming exists (an installer staging folder).")


def section_permissions():
    path = KIRO / "settings" / "permissions.yaml"
    template = ROOT / "kiro-setup" / "permissions.yaml"
    if not path.is_file():
        out("Step 5 permissions: ~/.kiro/settings/permissions.yaml is MISSING, so nothing denies the "
            "runtime server or the Dev MCP's deletes. The operator installs it from kiro-setup/permissions.yaml.")
        return
    installed = path.read_text(encoding="utf-8")
    wanted = re.findall(r'"((?:appian|appian-runtime)/[^"]+)"', template.read_text(encoding="utf-8")) if template.is_file() else []
    missing = [w for w in wanted if f'"{w}"' not in installed and f"'{w}'" not in installed and w not in installed]
    if missing:
        out(f"Step 5 permissions: ~/.kiro/settings/permissions.yaml lacks {len(missing)} of the template's "
            f"{len(wanted)} deny entries (first: {missing[0]}). The operator updates it.")
    else:
        out(f"Step 5 permissions: ~/.kiro/settings/permissions.yaml carries all {len(wanted)} deny entries "
            "of kiro-setup/permissions.yaml (text check; whether Kiro enforces them is M2).")


def section_supplemental():
    repo = ROOT / "skills" / "appian-supplemental" / "SKILL.md"
    installed = KIRO / "skills" / "appian-supplemental" / "SKILL.md"
    if not installed.is_file():
        out("Step 6 supplemental: NOT INSTALLED at ~/.kiro/skills/appian-supplemental/SKILL.md.")
    elif repo.read_bytes() == installed.read_bytes():
        out("Step 6 supplemental: repo and installed copies are byte-identical.")
    else:
        newer = "installed" if installed.stat().st_mtime > repo.stat().st_mtime else "repo"
        out(f"Step 6 supplemental: repo and installed copies DIFFER; the {newer} copy is newer. "
            "Ask the operator which way to sync; never overwrite either silently.")


def section_personas():
    stub = build_param("Persona site stub")
    dirs = sorted(HOME.glob(".sail-*"))
    default = HOME / ".sail"
    if (default / "session.json").is_file():
        dirs.insert(0, default)
    if not dirs:
        out("Step 9 personas: no sail data directories on this machine.")
        return
    if not stub:
        out("Step 9 personas: build parameter `Persona site stub` is unset; liveness skipped.")
    for d in dirs:
        session = d / "session.json"
        if not session.is_file():
            out(f"Step 9 personas: {d}: no session.")
            continue
        try:
            data = json.loads(session.read_text())
            user, host, source = data.get("username"), data.get("hostname"), data.get("source")
        except Exception as error:
            out(f"Step 9 personas: {d}: session.json unreadable ({error!r}).")
            continue
        label = f"{d}: {user} @ {host}"
        if source == "devmcp":
            label += " (a designer import, not a persona)"
        if d == default:
            label += " (the default directory, which should stay empty)"
        if stub:
            rc, text = run(["sail", "--data-dir", str(d), "pages", stub], timeout=25)
            state = "live" if rc == 0 else ("expired" if re.search(r"401|auth|session", text, re.I) else f"error: {text[:160]}")
            label += f": {state}"
        out(f"Step 9 personas: {label}")
    out("Step 9 personas: a username is only what was typed at login; confirm the account by observation (core §6).")


def section_grounding():
    log = ROOT / "BUILD_LOG.md"
    if log.is_file():
        text = log.read_text(encoding="utf-8")
        checkpoint = next((l for l in text.splitlines() if "Promotion checkpoint" in l), None)
        entries = list(re.finditer(r"^## (?=\d{4}-\d{2}-\d{2})", text, re.M))
        out("Grounding (core §1 step 4): BUILD_LOG tail:")
        if entries:
            tail = text[entries[-1].start():].splitlines()
            out("\n".join(tail[:60]) + ("\n[... entry truncated at 60 lines; read the rest in BUILD_LOG.md]" if len(tail) > 60 else ""))
        else:
            out("(no dated entries yet)")
        if checkpoint:
            out(f"Checkpoint line: {checkpoint.strip()[:200]}")
    todo = ROOT / "TODO.md"
    if todo.is_file():
        counts = []
        for m in re.finditer(r"^## (.+?)$(.*?)(?=^## |\Z)", todo.read_text(encoding="utf-8"), re.M | re.S):
            n = len(re.findall(r"^- ", m.group(2), re.M))
            if n and m.group(1).strip() != "Done":
                counts.append(f"{m.group(1).strip()}: {n}")
        out("TODO open items: " + (", ".join(counts) if counts else "none"))
    rc, branch = run(["git", "-C", str(ROOT), "symbolic-ref", "--short", "-q", "HEAD"])
    rc_head, _ = run(["git", "-C", str(ROOT), "rev-parse", "-q", "--verify", "HEAD"])
    rc2, dirty = run(["git", "-C", str(ROOT), "status", "--porcelain"])
    rc3, ahead = run(["git", "-C", str(ROOT), "rev-list", "--left-right", "--count", "HEAD...@{u}"])
    branch = branch.splitlines()[0] if rc == 0 and branch else "(detached or unknown)"
    if rc_head != 0:
        branch += ", no commits yet"
    sync = ahead.replace("\t", " ahead / ") + " behind" if rc3 == 0 else "no upstream"
    out(f"Git: branch {branch}; {len(dirty.splitlines()) if rc2 == 0 and dirty else 0} uncommitted path(s); "
        f"upstream (no fetch): {sync}.")


def section_credits():
    """Rebuild CREDITS.md from Kiro's session store and print the tally (core §10 step 1)."""
    try:
        import credits
    except Exception as error:
        out(f"Credits: credits.py failed to import ({error!r}); run python3 .kiro/scripts/credits.py by hand.")
        return
    out(credits.sync(write=True))

def section_agent_steps():
    app = build_param("Application UUID") or "UNSET"
    account = build_param("Design account") or "UNSET"
    groups = build_param("Security groups") or "UNSET"
    ritual = build_param("Per-session ritual") or "UNSET"
    out("AGENT STEPS NOW (core §2), in order, before any other work:")
    out("  2. Confirm the tools from server `appian` include the design families, then listRecordTypes "
        f"scoped to Application UUID {app}.")
    out("  3. If either fails, STOP and report (no workarounds, no runtime tools).")
    out("  4. getDevMcpVersionInfo against the toolchain §1 pin; surface its recommendations.")
    out(f"  7. Per-session ritual: {ritual}.")
    out(f"  8. State the executing identity and group scope; Design account {account}; "
        f"group readback for {groups}.")
    out("A build parameter shown UNSET is reported as unset and its check skipped (core §13).")


def main():
    out("SESSION PREFLIGHT REPORT (SessionStart hook, machine-side checks; core §2). Read it before acting.")
    for step in (section_port, section_plan):
        step()
    info = section_registration_and_versions()
    for step in (lambda: section_sail_and_skill(info), section_permissions, section_supplemental,
                 section_personas, section_grounding, section_credits, section_agent_steps):
        try:
            step()
        except Exception as error:
            out(f"PREFLIGHT CHECK ERROR in {getattr(step, '__name__', 'step')}: {error!r}; run that check by hand.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        out(f"PREFLIGHT SCRIPT ERROR: {error!r}. Run every core §2 step by hand and record that the hook failed.")
    print("\n".join(lines))
    sys.exit(0)
