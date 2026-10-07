"""PreToolUse gate for Dev MCP tools (core §2 step 1).

While BUILD_PLAN.md is the template stub, only reads reach the Dev MCP. Exit 2 blocks
the tool call and Kiro returns stderr to the agent (kiro.dev/docs/hooks/types). The
docs disagree about what other non-zero codes do, so every failure here, including the
script's own, exits 2: the gate fails closed.

Tool-name form. Kiro's hook-facing tool_name was measured on 2026-10-06 (M8a) as
`mcp_appian_<tool>`, all lowercase (e.g. `mcp_appian_getdevmcpversioninfo`). Earlier
sessions saw `appian::<tool>` (deferred tools), and the permission layer uses
`appian/<tool>`; the form is not stable across sessions (maintenance/kiro-port.md M8
and the taxonomy). So NAME accepts every form seen or expected, and the read check is
case-insensitive because the mcp_appian_ form lowercases the tool name.
"""

import json
import re
import sys

from method_lib import log_event, plan_status

# Reads are get*/list*/validate* plus a few exact names. Compared case-insensitively:
# the mcp_appian_ form arrives lowercased (getdevmcpversioninfo, not getDevMcpVersionInfo).
READ_PREFIX = re.compile(r"^(get|list|validate)", re.I)
READ_EXACT = {"testrule", "testinterface", "getdevmcpversioninfo", "logout"}

# Every Dev MCP tool-name form seen or expected: mcp_appian_<tool> (measured 2026-10-06),
# appian/<tool>, appian::<tool>, @appian/<tool>. Scoped so it never matches the
# appian-runtime or appian-public-docs servers, whose names carry a hyphen after "appian"
# rather than the underscore/slash/colon this pattern requires.
NAME = re.compile(r"^(?:@?appian(?:/|::)|mcp_appian_)(.+)$")


def refuse(payload, message):
    log_event("plan-gate", payload, "blocked")
    print(message, file=sys.stderr)
    return 2


def main():
    payload = sys.stdin.read()
    name = json.loads(payload).get("tool_name") or ""
    match = NAME.match(name)
    if not match:
        return refuse(payload, f"Plan gate: unrecognised Dev MCP tool name {name!r}; refusing "
                               "until the name format is recorded (maintenance/kiro-port.md, M8).")
    tool = match.group(1)
    populated, reason = plan_status()
    if populated or tool.lower() in READ_EXACT or READ_PREFIX.match(tool):
        log_event("plan-gate", payload, "allowed")
        return 0
    return refuse(payload, f"Plan gate: {reason}. The build is not planned yet, so only reads "
                           "reach the Dev MCP (core §2 step 1). Phase 0 happens in the claude.ai "
                           "Project (GETTING_STARTED.md §3). Do not retry this call another way.")


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as error:  # fail closed
        print(f"Plan gate: internal error ({error!r}); refusing the call.", file=sys.stderr)
        sys.exit(2)
