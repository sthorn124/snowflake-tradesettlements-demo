#!/usr/bin/env python3
"""The three SO_triageCase event texts that state the agent's score (nodes 5, 23, 33).

Written 2026-11-13 (prompts/006, Part 3): every lane states the score as
"auto-release score N, releases at G", rounded as SO_autoReleaseDisplay rounds it.

One source for two outputs, so the text a session tests is the text the node holds:
  node<N>.json            the `data` block for updateProcessModelNode (pv! references)
  zz_eventText.sail       a throwaway rule body with the same three expressions on ri!

Usage: triage_event_text.py <output directory>
"""
import json
import sys

EH = "'recordType!{eede988b-5576-4daa-a49c-fa962d90b16b}SO Settlement Case Event History"
F = {
    "timestamp": "{2997cf09-138c-489d-a6ff-221de2e77243}timestamp",
    "user": "{c4acbfe1-23ab-4f68-9874-464b794d360b}user",
    "eventTypeId": "{4b704e07-732c-4152-9906-ee8107cb8c1b}eventTypeId",
    "automationTypeId": "{523e83ec-1a63-42a5-a5c0-e9bb3f76d085}automationTypeId",
    "comment": "{6862ba51-9181-470c-8798-9bfd1cabc8bb}comment",
    "recordId": "{6c3a39d8-6dc6-425d-ab58-1d72fb487426}recordId",
}

# The score and the gate on the screen's 0-100 scale, as SO_autoReleaseDisplay and node 43 compute them.
SCORE = "tointeger(round(100 * a!defaultValue(pv!confidence, 0), 0))"
GATE = "tointeger(round(100 * todecimal(cons!SO_CONFIDENCE_THRESHOLD), 0))"

COMMENT = {
    # Agent Triage Complete (type 2), escalate and straight-through lanes
    5: (
        'a!localVariables(local!fr: a!defaultValue(pv!failReason, ""), '
        'local!label: if(a!isNullOrEmpty(local!fr), "unknown reason", lower(a!defaultValue(index(rule!SO_failReasonDisplay(failReason: local!fr, short: false), "label", local!fr), local!fr))), '
        f'local!score: {SCORE}, local!gate: {GATE}, '
        'left("Agent assessed " & local!label & "; proposed " & a!defaultValue(pv!remediation, "none") & " at auto-release score " & local!score & ", releases at " & local!gate, 4000))'
    ),
    # Escalated (type 7)
    23: (
        'a!localVariables(local!fr: a!defaultValue(pv!failReason, ""), '
        'local!label: lower(a!defaultValue(index(rule!SO_failReasonDisplay(failReason: local!fr, short: false), "label", "unknown reason"), "unknown reason")), '
        'local!lag: a!defaultValue(pv!lagHrs, 0), local!rem: a!defaultValue(pv!hoursRemaining, 0), '
        f'local!score: {SCORE}, local!gate: {GATE}, '
        'local!fs: index(split(a!defaultValue(pv!assessment, ""), ". "), 1, ""), '
        'left(if(a!defaultValue(pv!windowBreached, false()), '
        '"Escalated by policy: " & local!label & " — broker confirmation lag " & text(local!lag, "0.0") & "h against " & '
        'if(local!rem < 0, "a cutoff already " & text(abs(local!rem), "0.0") & "h past", text(local!rem, "0.0") & "h remaining") & '
        '", so the remediation cannot complete inside the window. Auto-release score " & local!score & ", releases at " & local!gate & "; the breached window decides this case whatever the score.", '
        'if(local!fr = "counterparty_default", '
        '"Escalated by policy: " & local!label & " requires a human credit decision; straight-through not permitted for this reason.", '
        '"Escalated by agent: " & local!label & " — " & if(right(local!fs, 1) = ".", local!fs, local!fs & "."))), 4000))'
    ),
    # Straight-Through Resolution (type 3)
    33: (
        f'a!localVariables(local!score: {SCORE}, local!gate: {GATE}, '
        'left("Straight-through: " & a!defaultValue(pv!remediation, "none") & " | auto-release score " & local!score & ", releases at " & local!gate & '
        '" | disposition " & a!defaultValue(pv!stDisposition, "none") & " | resolved before cutoff without analyst review", 4000))'
    ),
}
EVENT_TYPE = {5: 2, 23: 7, 33: 3}


def records(node):
    fields = [
        (F["timestamp"], "now()"),
        (F["user"], "null"),
        (F["eventTypeId"], str(EVENT_TYPE[node])),
        (F["automationTypeId"], 'a!automationId("AI_AGENT")'),
        (F["comment"], COMMENT[node]),
        (F["recordId"], "pv!caseId"),
    ]
    body = ",".join(f"{EH}.fields.{name}': {value}" for name, value in fields)
    return "{" + EH + "'(" + body + ")}"


def data(node):
    return {
        "inputs": [
            {"name": "Records", "expression": records(node)},
            {"name": "PauseOnError", "value": False},
            {"name": "CaptureEvents", "value": False},
        ],
        "outputs": [{"name": "RecordsUpdated"}, {"name": "ErrorOccurred"}, {"name": "Error"}],
    }


def main(out):
    for node in COMMENT:
        with open(f"{out}/node{node}.json", "w") as fh:
            json.dump(data(node), fh, ensure_ascii=False)
    rule = "a!map(\n" + ",\n".join(
        f"  node{node}: " + COMMENT[node].replace("pv!", "ri!") for node in COMMENT
    ) + "\n)\n"
    with open(f"{out}/zz_eventText.sail", "w") as fh:
        fh.write("/* THROWAWAY (prompts/006): the three SO_triageCase event texts on rule inputs. */\n" + rule)
    print("wrote", ", ".join(f"node{n}.json" for n in COMMENT), "and zz_eventText.sail")


if __name__ == "__main__":
    main(sys.argv[1])
