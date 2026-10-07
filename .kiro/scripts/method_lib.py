"""Shared checks for the method's Kiro hooks. Standard library only.

Kiro runs hook commands from the project root (kiro.dev/docs/hooks). Paths here are
resolved from this file's location instead, so a script also works when run by hand
from anywhere inside the repo.
"""

import datetime
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
STATE = ROOT / ".kiro" / "state"
STUB_MARKER = "<!-- STUB."


def plan_status():
    """(populated, reason) for BUILD_PLAN.md, by the structure core §2 step 1 names."""
    plan = ROOT / "BUILD_PLAN.md"
    if not plan.is_file():
        return False, "BUILD_PLAN.md is missing"
    text = plan.read_text(encoding="utf-8")
    if any(line.lstrip().startswith(STUB_MARKER) for line in text.splitlines()):
        return False, "BUILD_PLAN.md still carries the template stub marker line"
    section = re.search(r"^## Build Phases[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not section:
        return False, "BUILD_PLAN.md has no '## Build Phases' heading"
    if not re.search(r"^[ \t]*- (\[ \]|\[x\]|✅)", section.group(1), re.M):
        return False, "the Build Phases section of BUILD_PLAN.md holds no checklist item"
    return True, "BUILD_PLAN.md is populated"


def _strip_fences(text):
    return re.sub(r"^```.*?^```[ \t]*$", "", text, flags=re.M | re.S)


def build_param(name):
    """A Build parameter's value from .kiro/steering/project.md, or None when unset.

    The template's own block sits inside a code fence and is ignored; a build copies
    it out of the fence and fills it in (core §13).
    """
    path = ROOT / ".kiro" / "steering" / "project.md"
    if not path.is_file():
        return None
    for line in _strip_fences(path.read_text(encoding="utf-8")).splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and cells[0] == name:
            value = cells[1]
            if not value or value.startswith("<") or value.lower().startswith("unset"):
                return None
            return value
    return None


def open_measurements():
    """Ids of the unticked first-session measurements in maintenance/kiro-port.md."""
    path = ROOT / "maintenance" / "kiro-port.md"
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8")
    section = re.search(r"^## Required measurements.*?$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not section:
        return []
    return re.findall(r"^- \[ \] \*\*(M\d+)\b", section.group(1), re.M)


def log_event(hook, payload, decision):
    """Append one line per hook call to .kiro/state/hook-events.log (gitignored).

    It records the tool name exactly as Kiro passed it, which first-session
    measurement M8 reads. Never raises: logging must not change a gate's decision.
    """
    try:
        STATE.mkdir(parents=True, exist_ok=True)
        try:
            tool = json.loads(payload).get("tool_name")
        except Exception:
            tool = "<unparseable stdin>"
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(STATE / "hook-events.log", "a", encoding="utf-8") as f:
            f.write(f"{stamp}\t{hook}\t{tool!r}\t{decision}\n")
    except Exception:
        pass
