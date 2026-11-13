/*
 * SO_triageLane — which lane SO_triageCase takes for a triaged case, written once.
 *
 * Returns "ESCALATE", "STRAIGHT_THROUGH" or "ANALYST".
 *
 *   ESCALATE          the window is breached (process-layer policy, ruled
 *                     2026-09-22), or the fail reason is counterparty_default
 *                     (reason override: never released, whatever it scored), or
 *                     the agent set its escalate flag.
 *   STRAIGHT_THROUGH  not escalated, and the score is at or above
 *                     cons!SO_CONFIDENCE_THRESHOLD, and the fail reason has a
 *                     straight-through disposition, and the cutoff is still in
 *                     the future.
 *   ANALYST           everything else.
 *
 * Escalate is tested first, so a case that also clears the gate is escalated.
 *
 * TWO GATEWAYS IN SO_triageCase READ THIS RULE, which is why it is a rule:
 *   node 12 "Route" picks the lane;
 *   node 4 "Triage write ok?" sends an analyst-lane case straight to its lane,
 *   past node 5, so the lane writes ONE "Agent Triage Complete" entry (node 43)
 *   and not two.
 * Both pass the same six process variables, so they cannot disagree. Until
 * 2026-11-13 these conditions were written inline on node 12.
 *
 * Every input is read through a default, so a null takes the cautious side:
 * no breach, no agent escalation, a score of 0, no disposition, a cutoff that
 * is not in the future. With nothing passed the answer is "ANALYST".
 */
if(
  or(
    a!defaultValue(ri!windowBreached, false),
    a!defaultValue(ri!failReason, "") = "counterparty_default",
    a!defaultValue(ri!agentEscalate, false)
  ),
  "ESCALATE",
  if(
    and(
      todecimal(a!defaultValue(ri!confidence, 0)) >= cons!SO_CONFIDENCE_THRESHOLD,
      not(a!isNullOrEmpty(ri!stDisposition)),
      a!defaultValue(ri!cutoffFuture, false)
    ),
    "STRAIGHT_THROUGH",
    "ANALYST"
  )
)
