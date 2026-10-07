"""Stop hook: has the close-out actually been handed off? (core §10 steps 6-7)

Silent unless a close-out is in progress: Closeout.md has uncommitted changes, or HEAD
is a "closeout:" commit that the local upstream ref does not have yet. Then it checks git
itself instead of trusting the session's report: HEAD equals its upstream after a fetch,
and nothing is left to commit.

If the close-out has not landed, it prints Kiro's documented block decision,
{"decision": "block", "reason": ...}, with exit 0, so the reason comes back to the agent
as a new message and the turn continues (kiro.dev/docs/hooks/types). After two
consecutive blocks it stops blocking and warns instead, so a push that cannot succeed
does not loop. It never pushes, commits, or force-anything; that stays with the session.
"""

import json
import subprocess
import sys

from method_lib import ROOT, STATE

COUNTER = STATE / "closeout-blocks"
MAX_BLOCKS = 2


def git(*args, timeout=20):
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def blocks_so_far(facts):
    """Consecutive blocks for these same facts; a different problem starts again at 0."""
    try:
        state = json.loads(COUNTER.read_text())
        return state["count"] if state.get("facts") == facts else 0
    except Exception:
        return 0


def set_blocks(n, facts=""):
    STATE.mkdir(parents=True, exist_ok=True)
    COUNTER.write_text(json.dumps({"count": n, "facts": facts}))


def main():
    sys.stdin.read()  # the Stop payload carries nothing this check needs
    if git("rev-parse", "--is-inside-work-tree")[0] != 0:
        return 0
    closeout_dirty = bool(git("status", "--porcelain", "--", "Closeout.md")[1])
    head_subject = git("log", "-1", "--format=%s")[1]
    head = git("rev-parse", "HEAD")[1]
    upstream_rc, upstream, _ = git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
    tracked = git("rev-parse", "@{u}")[1] if upstream_rc == 0 else None
    # A successful push moves the local upstream ref, so a closeout commit equal to it has
    # landed as far as this clone knows. Ordinary edits after a landed close-out stay silent.
    unpushed_closeout = head_subject.startswith("closeout:") and head != tracked
    if not closeout_dirty and not unpushed_closeout:
        set_blocks(0)
        return 0

    problems = []
    if closeout_dirty:
        problems.append("Closeout.md has uncommitted changes")
    if upstream_rc != 0:
        problems.append("the branch has no upstream to push to")
    else:
        fetch_rc, _, fetch_err = git("fetch", "--quiet", timeout=30)
        if fetch_rc != 0:
            problems.append(f"git fetch failed: {fetch_err[:200]}")
        remote = git("rev-parse", "@{u}")[1]
        if head != remote:
            problems.append(f"HEAD {head[:7]} is not {upstream} ({remote[:7]})")
    if git("status", "--porcelain")[1]:
        problems.append("the working tree has uncommitted changes")

    if not problems:
        set_blocks(0)
        return 0

    facts = "; ".join(problems)
    count = blocks_so_far(facts) + 1
    set_blocks(count, facts)
    if count > MAX_BLOCKS:
        print(f"Close-out check: still not handed off after {MAX_BLOCKS} reminders ({facts}). "
              "Report it as a failed close-out with the git output (core §10 step 7).", file=sys.stderr)
        return 1
    print(json.dumps({
        "decision": "block",
        "reason": (f"Close-out check: the close-out has not been handed off: {facts}. Finish "
                   "core §10 steps 6-7 (commit, push, then verify HEAD equals origin/main and "
                   "nothing is left to commit), or report a failed close-out with the git output. "
                   "Never force-push."),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as error:
        print(f"Close-out check: internal error ({error!r}); push state not verified.", file=sys.stderr)
        sys.exit(1)
