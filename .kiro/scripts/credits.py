"""Kiro credit usage, read from Kiro's own session store (core §10 step 1).

Kiro writes one `usage_summary` record per prompt turn to
~/.kiro/sessions/<workspace-hash>/<session-id>/messages.jsonl, carrying the credits
and elapsed time its usage view shows. Verified 2026-10-07 on Kiro IDE 1.2.4: a turn
recorded there as 44.05 credits / 609 s was shown in the IDE as 44.04 / 10m08s.

This script rebuilds CREDITS.md from those records for every session opened on this
workspace, one row per prompt turn, so the file needs no figures from the operator.
The SessionStart hook runs it (which also picks up the previous session's close-out
turn), and the close-out runs it again so Closeout.md can quote the session so far.

    python3 .kiro/scripts/credits.py           # rebuild CREDITS.md when the build is planned; print the summary
    python3 .kiro/scripts/credits.py --print   # print the table and summary; write nothing

Rows are written only when BUILD_PLAN.md is populated (a real build), so maintenance
sessions on the template itself never land in the file a build is instantiated from.
Standard library only. Never raises into a hook: every failure is a printed line.
"""

import datetime
import json
import os
import pathlib
import re
import sys

from method_lib import ROOT, plan_status

HOME = pathlib.Path.home()
KIRO = pathlib.Path(os.environ.get("KIRO_HOME") or HOME / ".kiro")
CREDITS = ROOT / "CREDITS.md"
HEADER = """# CREDITS — Kiro credit usage for this build

One row per prompt turn, rebuilt by `.kiro/scripts/credits.py` from Kiro's own session records (`~/.kiro/sessions/`). The session-start hook rebuilds it at every session, and the close-out rebuilds it before writing `Closeout.md`; the close-out turn itself lands at the next session start. Nothing here is typed by hand.

- **Credits** and **Elapsed** are the figures Kiro records for the turn, the same ones its usage view shows.
- **Time** is the local time of the machine that rebuilt the file. **Prompt** is the first line of the message that started the turn, shortened.
- **Month to date** is the running sum of Credits for the calendar month of the row, this build only. The operator's monthly cap is per person, across every build they run.
- Rows are written only once `BUILD_PLAN.md` is populated. `python3 .kiro/scripts/credits.py --print` shows the table for any repo without writing it.

| Date | Time | Session | Prompt | Credits | Elapsed | Month to date |
|---|---|---|---|---|---|---|
"""


def _workspace_matches(session_json):
    try:
        meta = json.loads(session_json.read_text(encoding="utf-8"))
    except Exception:
        return None
    paths = meta.get("workspacePaths") or meta.get("rootPaths") or []
    root = str(ROOT.resolve())
    if any(str(pathlib.Path(p).resolve()) == root for p in paths):
        return meta
    return None


def sessions():
    """[(session_dir, meta)] for every Kiro session opened on this workspace."""
    found = []
    store = KIRO / "sessions"
    if not store.is_dir():
        return found
    for session_json in store.glob("*/sess_*/session.json"):
        meta = _workspace_matches(session_json)
        if meta:
            found.append((session_json.parent, meta))
    return found


def _text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                parts.append(block.get("text") or block.get("content") or "")
            elif isinstance(block, str):
                parts.append(block)
        return " ".join(p for p in parts if isinstance(p, str))
    if isinstance(content, dict):
        return content.get("text") or ""
    return ""


def _snippet(text, limit=70):
    line = next((l for l in text.strip().splitlines() if l.strip()), "")
    line = re.sub(r"\s+", " ", line).replace("|", "/").strip()
    return line[:limit] + ("…" if len(line) > limit else "")


def turns(session_dir, meta):
    """One record per usage_summary in the session, with the prompt that started the turn."""
    path = session_dir / "messages.jsonl"
    if not path.is_file():
        return []
    out = []
    last_prompt = ""
    title = (meta.get("title") or session_dir.name).strip()
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                record = json.loads(line)
            except Exception:
                continue
            payload = record.get("payload") or {}
            kind = payload.get("type")
            if kind == "user":
                last_prompt = _snippet(_text(payload.get("content")))
            elif kind == "usage_summary":
                credits = 0.0
                for summary in payload.get("promptTurnSummaries") or []:
                    try:
                        credits += float(summary.get("usage") or 0)
                    except (TypeError, ValueError):
                        pass
                elapsed_ms = payload.get("elapsedTime") or 0
                if credits <= 0 and payload.get("status") != "success":
                    continue  # a failed turn Kiro did not charge
                out.append({
                    "ts": record.get("timestamp") or "",
                    "session": session_dir.name,
                    "title": title,
                    "prompt": last_prompt,
                    "credits": credits,
                    "elapsed_ms": int(elapsed_ms) if isinstance(elapsed_ms, (int, float)) else 0,
                })
    return out


def all_turns():
    rows = []
    for session_dir, meta in sessions():
        rows.extend(turns(session_dir, meta))
    rows.sort(key=lambda r: r["ts"])
    return rows


def _local(ts):
    try:
        when = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone()
        return when.strftime("%Y-%m-%d"), when.strftime("%H:%M")
    except Exception:
        return ts[:10], ts[11:16]


def _elapsed(ms):
    seconds = max(0, ms // 1000)
    return f"{seconds // 60}m{seconds % 60:02d}s"


def render(rows):
    lines = [HEADER.rstrip("\n")]
    running = {}
    for r in rows:
        date, time = _local(r["ts"])
        month = date[:7]
        running[month] = running.get(month, 0.0) + r["credits"]
        lines.append(f"| {date} | {time} | {r['title'].replace('|', '/')} | {r['prompt']} | "
                     f"{r['credits']:.2f} | {_elapsed(r['elapsed_ms'])} | {running[month]:.2f} |")
    return "\n".join(lines) + "\n"


def summary(rows):
    """One line: the current month's total and the latest session so far."""
    if not (KIRO / "sessions").is_dir():
        return f"Credits: Kiro's session store was not found at {KIRO / 'sessions'}; CREDITS.md was not rebuilt."
    if not rows:
        return "Credits: no Kiro turns recorded for this workspace yet."
    latest = rows[-1]
    month = _local(latest["ts"])[0][:7]
    month_rows = [r for r in rows if _local(r["ts"])[0][:7] == month]
    session_rows = [r for r in rows if r["session"] == latest["session"]]
    month_total = sum(r["credits"] for r in month_rows)
    session_total = sum(r["credits"] for r in session_rows)
    session_elapsed = sum(r["elapsed_ms"] for r in session_rows)
    return (f"Credits: {month_total:.2f} used in {month} over {len(month_rows)} turn(s) in "
            f"{len({r['session'] for r in month_rows})} session(s) on this workspace; "
            f"latest session {latest['title']!r}: {session_total:.2f} credits, {_elapsed(session_elapsed)}, "
            f"{len(session_rows)} turn(s), the current turn not yet included.")


def sync(write=True):
    """Rebuild CREDITS.md when the build is planned; return the summary line."""
    rows = all_turns()
    populated, _ = plan_status()
    if write and rows and populated:
        CREDITS.write_text(render(rows), encoding="utf-8")
        note = f" CREDITS.md rebuilt with {len(rows)} row(s)."
    elif write and rows:
        note = " CREDITS.md not written: BUILD_PLAN.md is still the stub (rows are written once the build is planned)."
    else:
        note = ""
    return summary(rows) + note


def main(argv):
    if "--print" in argv:
        rows = all_turns()
        print(render(rows))
        print(summary(rows))
        return 0
    print(sync(write=True))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as error:  # never break a hook
        print(f"Credits: script error ({error!r}); CREDITS.md not rebuilt. Run it by hand: python3 .kiro/scripts/credits.py")
        sys.exit(0)
