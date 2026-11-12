#!/usr/bin/env python3
"""What fixtures/p4-verify-redate.py produces for a given UTC hour, as one '~'-joined
string in the line format of SO_standingCaseRedate's `expected` output.
Uses the script's own tables and functions, so the comparison is against the script
and not against a second copy of its offsets.  Usage: redate_expected.py "2026-11-12 06"
"""
import importlib.util, sys, os
from datetime import datetime, timezone
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("redate", os.path.join(here, "..", "..", "fixtures", "p4-verify-redate.py"))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
now = datetime.strptime(sys.argv[1], "%Y-%m-%d %H").replace(tzinfo=timezone.utc)
triage = {c: m.triage_offset(cut, td) for c, (cut, td) in m.OFFSETS.items()}
lines = []
for case, (cut, _) in sorted(m.OFFSETS.items()):
    resolved = m.stamp(now, m.RESOLVED[case]) if case in m.RESOLVED else ""
    lines.append(f"case {case} cutoff={m.stamp(now, cut)} created={m.stamp(now, triage[case] - 0.25)} modified={m.stamp(now, triage[case])} resolved={resolved}")
for cid, case in sorted(m.COMMENTS.items()):
    lines.append(f"comment {cid} created={m.stamp(now, triage[case])}")
for eid, (case, rel) in sorted(m.EVENTS.items()):
    lines.append(f"event {eid} at={m.stamp(now, triage[case] + rel)}")
print("~".join(lines))
