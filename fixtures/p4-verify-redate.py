#!/usr/bin/env python3
"""
P4-VERIFY fixture re-date — RUN AT THE START OF EVERY SESSION THAT RENDERS A
PHASE 4 SCREEN. Fixture cutoffs are absolute timestamps and decay daily; a
session that renders without re-dating shows a book that is entirely past
cutoff and an "Inside critical window" KPI of zero.

IDEMPOTENT BY CONSTRUCTION. Each case is pinned to an OFFSET FROM NOW, not
shifted by a delta, so running it twice, or ten times, produces the same demo
shape. Offsets are the fixture's design, not its current state.

Triage times are re-dated too. The stored assessments state "roughly R hours
remaining to cutoff" where R = offset + 0.5, so if triage drifted while cutoff
did not, every assessment would start lying about its own arithmetic — the 3a
defect, rebuilt automatically. Keeping both on one clock is what stops that.

Contrast, deliberately: the Phase 5 packet inserts cutoffs RELATIVE TO NOW at
insert time, so a simulated feed never needs this. This script exists only for
the hand-authored verification fixtures.

THREE TABLES MOVE TOGETHER, and the third was missed once already: cases,
SO Case Comment (the stored assessments), and SO Settlement Case Event History
(the activity timeline). Re-dating only the first leaves the audit trail
claiming the agent ran six days before the case existed — and a screen that
shows both reads as broken.

WRITES THREE CSVs — and until 2026-09-09 it did not. The docstring said three
while main() printed one, so the comment and event tables were being re-dated by
hand each session against a script that looked complete. That is the harness-
goes-stale failure in miniature: the artefact kept claiming a coverage it had
stopped having, and nothing failed when it lapsed. If a table is named up here it
has a table below and a file on disk.

EVERY STAMP IS DERIVED FROM ONE CLOCK — `now`, rounded down to the hour — and
every row is an OFFSET from it. Nothing is written as an absolute time anywhere
in this file, which is what makes a second run a no-op rather than a drift.
"""
from datetime import datetime, timedelta, timezone

# case -> (hours from now to cutoff, hours from now to triage)
# Negative cutoff = deliberately past, so the past-cutoff branch always has a home.
#
# THE HEADROOM RULE, and it was learned by rendering rather than by reasoning.
# The rail recomputes "does the remediation fit the window" from the LIVE clock,
# while the stored assessment states the arithmetic as it stood AT TRIAGE. Pick
# an offset that only just clears the lag and the two agree at re-date time and
# then silently diverge: within the hour the rail says "does not fit" while the
# assessment beside it says it fits. A demo runs for an hour or two, so:
#
#   a case whose assessment says the remediation FITS needs
#   cutoff offset >= broker confirmation lag + ~3h of headroom;
#   a case whose assessment says it does NOT fit is safe at any offset below the
#   lag, because time only makes that verdict more true.
#
# Lags, for reference: 36=10.24 38=5.19 39=3.0 40=7.29 43=6.32 44=2.87 45=0.5
#                      47=2.73 49=4.98 (41=8.15 42=8.76 50=2.87 are resolved).
OFFSETS = {
    36: (3.5,  -0.5),  # lag 10.24 — deliberately does NOT fit; inside window
    37: (2.0,  -0.5),  # New, unscored; inside window
    38: (8.5,  -0.5),  # lag 5.19 + headroom
    39: (-5.0, -0.5),  # PAST CUTOFF, permanently
    40: (11.0, -0.5),  # lag 7.29 + headroom
    41: (14.5, -0.5), 42: (16.5, -0.5),
    43: (9.0,  -0.5),  # lag 6.32 + headroom
    44: (3.0,  -0.5),  # lag 2.87 — too tight on purpose; inside window
    45: (2.5,  -0.5),  # lag 0.5 — fits easily even inside the window
    46: (21.5, -0.5), 47: (11.5, -0.5),
    48: (10.5, -0.5),
    49: (8.0,  -0.5),  # lag 4.98 + headroom
    50: (13.0, -0.5), 51: (3.25, -0.5), 52: (47.5, -0.5),
}
# Cases whose lane is "resolved": resolvedOn sits between triage and now.
RESOLVED = {41: -0.25, 42: -0.25, 50: -0.25}

# SO Case Comment: comment id -> case. THE STORED ASSESSMENT IS STAMPED AT
# TRIAGE, always — it is the agent's run, so it shares the run's clock exactly.
COMMENTS = {41: 36, 42: 38, 43: 39, 44: 40, 45: 41, 46: 42,
            47: 43, 48: 44, 49: 45, 50: 47, 51: 49, 52: 50}

# SO Settlement Case Event History: event id -> (case, hours RELATIVE TO TRIAGE).
# Offsets are relative to triage rather than to now so the audit trail cannot
# drift away from the assessment it describes: -0.25 is the feed opening the
# case a quarter-hour before the agent picks it up, 0 is the agent's own write,
# and a positive offset is a person acting afterwards.
EVENTS = {
    111: (36, -0.25), 112: (36, 0.0), 113: (36, 1 / 6),
    114: (38, -0.25), 115: (38, 0.0), 116: (38, 1 / 6),
    117: (39, -0.25), 118: (39, 0.0),
    119: (40, -0.25), 120: (40, 0.0),
    121: (41, -0.25), 122: (41, 0.25),
    123: (42, -0.25), 124: (42, 0.25),
}

def stamp(base, hours):
    return (base + timedelta(hours=hours)).strftime("%Y-%m-%d %H:%M:%S")


def triage_offset(cutoff_off, default=-0.5):
    """TRIAGE MUST PRECEDE CUTOFF. On a deliberately past-cutoff case the
    default (now - 30min) would put the agent's run AFTER the cutoff it was
    reasoning about — the assessment would describe a window that had already
    closed before it ran. Pull triage back to an hour before the cutoff
    whenever the default would land after it."""
    return min(default, cutoff_off - 1.0)

def main():
    now = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
    triage = {c: triage_offset(cut, td) for c, (cut, td) in OFFSETS.items()}

    with open("p4-verify-cases.csv", "w") as fh:
        fh.write("caseID,cutoffTs,createdOn,modifiedOn,resolvedOn\n")
        for case, (cut, _) in sorted(OFFSETS.items()):
            resolved = stamp(now, RESOLVED[case]) if case in RESOLVED else ""
            fh.write(f"{case},{stamp(now, cut)},{stamp(now, triage[case] - 0.25)},"
                     f"{stamp(now, triage[case])},{resolved}\n")

    with open("p4-verify-comments.csv", "w") as fh:
        fh.write("id,createdOn\n")
        for cid, case in sorted(COMMENTS.items()):
            fh.write(f"{cid},{stamp(now, triage[case])}\n")

    with open("p4-verify-events.csv", "w") as fh:
        fh.write("id,timestamp\n")
        for eid, (case, rel) in sorted(EVENTS.items()):
            fh.write(f"{eid},{stamp(now, triage[case] + rel)}\n")

    print("wrote p4-verify-cases.csv, p4-verify-comments.csv, p4-verify-events.csv")
    print("Feed each to updateRecordData on SO Settlement Case, SO Case Comment,")
    print("and SO Settlement Case Event History respectively. ALL THREE, ALWAYS.")

if __name__ == "__main__":
    main()
