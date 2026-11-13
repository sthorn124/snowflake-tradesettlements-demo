#!/usr/bin/env python3
"""SO_triageCase node 11 ("Unpack agent output + derive routing"): its ten outputs.

Written 2026-11-13 (prompts/006, round 2). Two outputs changed: pv!remediation and
pv!stDisposition now come from rule!SO_remediationForCase, so the process, not the
agent, decides the remediation text and the straight-through code a case stores.
The other eight are as they read back from NY on 2026-11-13.

Prints the `data` block for updateProcessModelNode.
"""
import json

CASE = "'recordType!{09405a10-06c7-4368-9d5e-41a148dffd15}SO Settlement Case"
F_REASON = CASE + ".fields.{61aca3bf-502f-41af-8996-e91de5d1b8ad}failReason'"
F_CUTOFF = CASE + ".fields.{8fad5b1f-c63c-44e6-a4de-5b87bf59f0ad}cutoffTs'"
F_LAG = CASE + ".relationships.{1507a3f2-0feb-4df3-80f8-7b1a28e192c7}trade.fields.{1fc597a6-609f-4609-b2a8-7bdcfe018122}brokerConfirmationLagHrs'"


def by_id(field):
    return f"a!queryRecordByIdentifier(recordType: {CASE}', identifier: pv!caseId, fields: {{{field}}})[{field}]"


OUTPUTS = [
    ('=tostring(index(pv!agentOutputs, "assessment", ""))', "pv!assessment"),
    # changed 2026-11-13: was tostring(index(pv!agentOutputs, "remediation", ""))
    ('=tostring(index(rule!SO_remediationForCase(caseId: pv!caseId), "remediation", ""))', "pv!remediation"),
    ('=tostring(index(pv!agentOutputs, "urgency", ""))', "pv!urgency"),
    ('=todecimal(a!defaultValue(index(pv!agentOutputs, "confidence", 0), 0))', "pv!confidence"),
    ('=a!defaultValue(index(pv!agentOutputs, "escalate", false()), false())', "pv!escalate"),
    ("=" + by_id(F_REASON), "pv!failReason"),
    # changed 2026-11-13: was SO_remediationForReason(failReason) alone, read from the case
    ('=index(rule!SO_remediationForCase(caseId: pv!caseId), "stDisposition", null)', "pv!stDisposition"),
    (f"=a!localVariables(local!c: a!defaultValue({by_id(F_CUTOFF)}, now() - 1), local!c > now())", "pv!cutoffFuture"),
    (f"=todecimal(a!defaultValue({by_id(F_LAG)}, 0))", "pv!lagHrs"),
    (f'=a!localVariables(local!c: {by_id(F_CUTOFF)}, todecimal(a!defaultValue(index(rule!SO_cutoffDisplay(cutoffTs: local!c), "hoursRemaining", 0), 0)))', "pv!hoursRemaining"),
]

print(json.dumps({"customOutputs": [{"expression": e, "saveInto": s} for e, s in OUTPUTS]}, ensure_ascii=False))
