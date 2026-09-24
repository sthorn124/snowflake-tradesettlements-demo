/*
 * SO_statusDisplay — the ONE place a stored case status becomes a screen label.
 *
 * CLAUDE.md's display-vocabulary rule: STORED VALUES ARE UNCHANGED. Rules,
 * processes and the agent read the seven canon statuses; only the analyst sees
 * these labels. Never let a label returned here reach a stored field, a rule
 * comparison, or the agent's context.
 *
 * Label provenance — four are EVIDENCED by mockups/analyst_watchlist.html:
 *   New                        -> "New"
 *   Pending Analyst            -> "Awaiting review"
 *   In Remediation             -> "In remediation"
 *   Escalated                  -> "Escalated"
 * Three were not evidenced by any mockup — a watchlist shows open work, so it
 * evidenced no resolved label — and were proposed rather than invented silently.
 * RATIFIED by Scott 2026-09-03 and now canon alongside the four above:
 *   Agent Triage                -> "In triage"
 *   Resolved - Straight Through -> "Resolved · straight through"
 *   Resolved - Analyst          -> "Resolved · analyst"
 *
 * Returns a map so colour lives with the label and no consumer re-derives it.
 * isOpen is the single definition of "open work" for every KPI on every screen.
 */
a!localVariables(
  local!s: a!defaultValue(ri!status, ""),
  a!match(
    value: local!s,
    equals: "New",
      then: a!map(label: "New", color: "#6E7885", isOpen: true, isResolved: false),
    equals: "Agent Triage",
      then: a!map(label: "In triage", color: "#3E7396", isOpen: true, isResolved: false),
    equals: "Pending Analyst",
      then: a!map(label: "Awaiting review", color: "#454F5C", isOpen: true, isResolved: false),
    equals: "In Remediation",
      then: a!map(label: "In remediation", color: "#96590A", isOpen: true, isResolved: false),
    equals: "Escalated",
      then: a!map(label: "Escalated", color: "#B3261E", isOpen: true, isResolved: false),
    equals: "Resolved - Straight Through",
      then: a!map(label: "Resolved · straight through", color: "#17715B", isOpen: false, isResolved: true),
    equals: "Resolved - Analyst",
      then: a!map(label: "Resolved · analyst", color: "#17715B", isOpen: false, isResolved: true),
    /* An unrecognised status is shown verbatim rather than hidden — a status the
       screen cannot name is a defect the analyst should be able to report. */
    default: a!map(label: a!defaultValue(local!s, "Unknown"), color: "#6E7885", isOpen: true, isResolved: false)
  )
)
