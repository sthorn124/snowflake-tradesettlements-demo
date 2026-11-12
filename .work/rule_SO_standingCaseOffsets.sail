/*
 * SO_standingCaseOffsets — where each standing case sits relative to now.
 *
 * THE ONE HOME OF THE OFFSETS. SO_redateStandingCases reads this table through
 * SO_standingCaseRedate and writes nothing that is not listed here. The values
 * are those of fixtures/p4-verify-redate.py (superseded 2026-11-12), in MINUTES
 * instead of hours so every stamp is whole-minute arithmetic.
 *
 * cutoffMin     minutes from the clock to the case's cutoff. Negative = past
 *               cutoff on purpose (case 39, permanently).
 * resolvedMin   minutes from the clock to resolvedOn. Only the resolved cases
 *               carry one (41, 42, 50); null leaves resolvedOn untouched.
 * afterTriageMin  an event's minutes relative to its case's TRIAGE time, so the
 *               audit trail cannot drift from the assessment it describes:
 *               -15 the feed opens the case, 0 the agent's own write, a
 *               positive value a person acting afterwards.
 *
 * THE HEADROOM RULE (learned by rendering): a case whose stored assessment says
 * the remediation FITS needs cutoff >= broker confirmation lag + about 3 hours,
 * or the live rail and the assessment disagree within the hour. A case whose
 * assessment says it does NOT fit is safe at any offset below the lag.
 * Lags: 36=10.24 38=5.19 39=3.0 40=7.29 43=6.32 44=2.87 45=0.5 47=2.73 49=4.98.
 *
 * Changing the standing cases means changing this table and nothing else.
 */
a!map(
  /* triage is 30 minutes before the clock, or 60 minutes before the cutoff,
     whichever is earlier: the agent's run must precede the cutoff it reasons about */
  triageMin: -30,
  triageBeforeCutoffMin: 60,
  /* the feed opens the case 15 minutes before triage (createdOn) */
  createdBeforeTriageMin: 15,
  cases: {
    a!map(caseId: 36, cutoffMin: 210,  resolvedMin: null), /* lag 10.24: does NOT fit; inside window */
    a!map(caseId: 37, cutoffMin: 120,  resolvedMin: null), /* New, unscored; inside window */
    a!map(caseId: 38, cutoffMin: 510,  resolvedMin: null), /* lag 5.19 + headroom */
    a!map(caseId: 39, cutoffMin: -300, resolvedMin: null), /* PAST CUTOFF, permanently */
    a!map(caseId: 40, cutoffMin: 660,  resolvedMin: null), /* lag 7.29 + headroom */
    a!map(caseId: 41, cutoffMin: 870,  resolvedMin: -15),
    a!map(caseId: 42, cutoffMin: 990,  resolvedMin: -15),
    a!map(caseId: 43, cutoffMin: 540,  resolvedMin: null), /* lag 6.32 + headroom */
    a!map(caseId: 44, cutoffMin: 180,  resolvedMin: null), /* lag 2.87: too tight on purpose */
    a!map(caseId: 45, cutoffMin: 150,  resolvedMin: null), /* lag 0.5: fits easily inside the window */
    a!map(caseId: 46, cutoffMin: 1290, resolvedMin: null),
    a!map(caseId: 47, cutoffMin: 690,  resolvedMin: null),
    a!map(caseId: 48, cutoffMin: 630,  resolvedMin: null),
    a!map(caseId: 49, cutoffMin: 480,  resolvedMin: null), /* lag 4.98 + headroom */
    a!map(caseId: 50, cutoffMin: 780,  resolvedMin: -15),
    a!map(caseId: 51, cutoffMin: 195,  resolvedMin: null),
    a!map(caseId: 52, cutoffMin: 2850, resolvedMin: null)
  },
  /* SO Case Comment: the stored assessment is stamped AT TRIAGE, always */
  comments: {
    a!map(id: 41, caseId: 36), a!map(id: 42, caseId: 38), a!map(id: 43, caseId: 39),
    a!map(id: 44, caseId: 40), a!map(id: 45, caseId: 41), a!map(id: 46, caseId: 42),
    a!map(id: 47, caseId: 43), a!map(id: 48, caseId: 44), a!map(id: 49, caseId: 45),
    a!map(id: 50, caseId: 47), a!map(id: 51, caseId: 49), a!map(id: 52, caseId: 50)
  },
  /* SO Settlement Case Event History */
  events: {
    a!map(id: 111, caseId: 36, afterTriageMin: -15), a!map(id: 112, caseId: 36, afterTriageMin: 0),
    a!map(id: 113, caseId: 36, afterTriageMin: 10),
    a!map(id: 114, caseId: 38, afterTriageMin: -15), a!map(id: 115, caseId: 38, afterTriageMin: 0),
    a!map(id: 116, caseId: 38, afterTriageMin: 10),
    a!map(id: 117, caseId: 39, afterTriageMin: -15), a!map(id: 118, caseId: 39, afterTriageMin: 0),
    a!map(id: 119, caseId: 40, afterTriageMin: -15), a!map(id: 120, caseId: 40, afterTriageMin: 0),
    a!map(id: 121, caseId: 41, afterTriageMin: -15), a!map(id: 122, caseId: 41, afterTriageMin: 15),
    a!map(id: 123, caseId: 42, afterTriageMin: -15), a!map(id: 124, caseId: 42, afterTriageMin: 15)
  }
)
