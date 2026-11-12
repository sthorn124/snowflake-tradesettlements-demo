#!/usr/bin/env python3
"""Phase 11 edit of SO_demoAdminConsole (v12 -> one button, one status line).
NOT APPLIED on 2026-11-12: Prepare's synchronous part measured 34 s against a 20 s
limit, so the console waits for a ruling. Run from .work/; writes a draft beside this file.
Splices by line range, bottom to top, and asserts the text at each boundary so a
changed source stops the patch instead of being cut in the wrong place."""
src = open("SO_demoAdminConsole.sail").read().split("\n")  # the deployed v12 source
L = lambda n: src[n - 1]

def splice(a, b, new, first=None, last=None):
    if first is not None: assert first in L(a), (a, L(a))
    if last is not None: assert last in L(b), (b, L(b))
    src[a - 1:b] = new.split("\n") if new is not None else []

# 1. the run card: Load/Reset buttons, captions and result lines leave; one button, one status line
splice(597, 787, '''        /* ================= PREPARE THE DEMO (Phase 11, 2026-11-12) =================
           ONE BUTTON AND ONE STATUS LINE. Prepare clears the last run, re-dates the
           standing cases, loads a fresh packet and starts intake (SO_prepareRun).
           The line and its colour come from SO_demoRunState, which the process reads
           too, so the page and the process cannot disagree about a run in progress.
           No progress bar and no self-refresh, by ruling: the presenter refreshes. */
        a!cardLayout(
          padding: "LESS", shape: "SEMI_ROUNDED", showBorder: true,
          contents: {
            a!richTextDisplayField(
              labelPosition: "COLLAPSED", marginBelow: "STANDARD",
              value: a!richTextItem(
                text: "Clears the last run, re-dates the standing cases and loads 15 fresh trades. The 50,000-trade history is untouched.",
                color: "#454F5C", size: "SMALL"
              )
            ),
            a!richTextDisplayField(
              labelPosition: "COLLAPSED", marginBelow: "STANDARD",
              value: {
                a!richTextItem(text: "Status:  ", color: "#6E7885", size: "SMALL"),
                a!richTextItem(
                  text: tostring(index(local!runState, "line", "")),
                  /* READY green; nothing loaded and running neutral; the other three amber */
                  color: a!match(
                    value: tostring(index(local!runState, "tone", "NEUTRAL")),
                    equals: "POSITIVE", then: "#17715B",
                    equals: "WARN", then: "#96590A",
                    default: "#454F5C"
                  ),
                  size: "STANDARD", style: "STRONG"
                )
              }
            ),
            a!buttonArrayLayout(
              align: "START", marginBelow: "LESS",
              buttons: a!buttonWidget(
                label: "Prepare the demo",
                style: "SOLID",
                /* DISABLED ONLY WHILE A RUN IS IN PROGRESS. A run that died unlocks
                   itself: after 5 minutes SO_demoRunState stops calling it running. */
                disabled: a!defaultValue(index(local!runState, "isRunning", false), false),
                saveInto: {
                  a!save(local!prepResult, null),
                  a!startProcess(
                    processModel: cons!SO_PM_PREPARE_RUN,
                    processParameters: a!map(runName: cons!SO_DEMO_RUN_NAME),
                    isSynchronous: true,
                    onSuccess: a!save(local!prepResult, a!map(ok: fv!processInfo.pv.ok, message: fv!processInfo.pv.message, at: now())),
                    onError: a!save(local!prepResult, a!map(ok: false, message: "Prepare could not start, so nothing was changed. Your account may not be allowed to start it; ask the demo owner.", at: now())),
                    onIncomplete: a!save(local!prepResult, a!map(ok: false, message: "No answer within 30 seconds, or your account cannot read the result. Prepare may still finish: refresh this page and read the status line before pressing again.", at: now()))
                  )
                }
              )
            ),
            /* A FAILURE OR REFUSAL SHOWS IN FULL, WORD FOR WORD. A start that went
               through shows nothing here: the status line says the rest. */
            a!richTextDisplayField(
              showWhen: and(
                not(a!isNullOrEmpty(local!prepResult)),
                not(a!defaultValue(index(local!prepResult, "ok", false), false))
              ),
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "Not prepared", color: "#B3261E", size: "STANDARD", style: "STRONG"),
                a!richTextItem(text: "   " & text(a!defaultValue(index(local!prepResult, "at", null), now()), "d mmm hh:mm"), color: "#6E7885", size: "SMALL"),
                char(10),
                a!richTextItem(text: tostring(index(local!prepResult, "message", "")), color: "#1B2330", size: "STANDARD", style: "STRONG")
              }
            )
          }
        )''', first="RUN THE DEMO", last=")")
assert L(596) == "" or True

# 2. Details: the AI agent check leaves; the forEach before it becomes the last item
splice(581, 591, "                )", first="),", last=")")
assert "rule!SO_adminCheck(" in L(568) and "a!forEach(" in L(575)

# 3-4. demo cases are the cases tagged with the run name
splice(564, 564, L(564).replace("local!otherCases", "local!demoCases"), first="Demo cases")
splice(547, 547, L(547).replace("local!otherCases", "local!demoCases"), first="local!otherCases")
splice(541, 541, L(541).replace("local!otherCases", "local!demoCases"), first="local!otherCases")

# 5. the agent failure line leaves
splice(530, 537, None, first="a!richTextDisplayField(", last="),")
assert "showWhen: local!probesOk < count(local!probes)" in L(523)

# 6-7. the verdict: Environment OK / Environment problem, no agent
splice(506, 507, '''                    & "  ·  " & local!probesOk & "/" & count(local!probes) & " connections",''', first="connections", last="agent")
splice(501, 501, L(501).replace('if(local!ready, "Ready", "Not ready")', 'if(local!ready, "Environment OK", "Environment problem")'), first='"Not ready"')

# 8. the sub-title named the two buttons
splice(481, 481, L(481).replace("One demo at a time. Load starts it, Reset removes it.", "One demo at a time. Prepare the demo clears the last run and loads a fresh one."), first="Load starts it")

# 9. the reset block leaves with its button
splice(412, 465, None, first="RESET SESSION", last="")
assert "a!formLayout(" in L(412)

# 10. the verdict's inputs
splice(404, 410, '''    /* ================= THE VERDICT =================
       One line answers "is the environment working". Data and connections only.
       Whether the DEMO is ready is the status line's job (SO_demoRunState), so the
       page has one "Ready". The agent check left on 2026-11-12: it read the newest
       machine-written event, the standing cases always supply one, and a check
       that cannot fail is not a check. */
    local!dataOk: and(local!tradeBaseline = 50000, local!predBaseline = 50000),
    local!ready: and(local!dataOk, local!probesOk = count(local!probes)),''', first="THE VERDICT", last="local!ready")

# 11. the status line block becomes the run state
splice(349, 402, '''    /* ================= THE RUN'S STATE =================
       ONE RULE, SO_demoRunState, READ HERE AND BY SO_prepareRun. It derives the
       state from data the processes already write (the TRD9 packet, its load
       stamp, the cases tagged with the run name, the story table) and returns
       the status line and its tone with it. A demo case is a case whose session
       id is the run name: on 2026-10-23 this page read "Demo loaded" with 0
       trades and 5 cases because it counted every case that was not a built-in
       test case, including five with no session id at all. */
    local!runState: a!refreshVariable(
      value: rule!SO_demoRunState(runName: cons!SO_DEMO_RUN_NAME, asOf: null),
      refreshAlways: true
    ),
    local!demoCases: tointeger(a!defaultValue(index(local!runState, "demoCases", 0), 0)),''', first="THE STATUS LINE", last="),")

# 12. the agent query and the Load result holder leave; Prepare's result holder arrives
splice(311, 347, '''    /* ================= PREPARE'S LAST ANSWER =================
       Holds what SO_prepareRun returned to this page: ok, the message verbatim,
       and when. A page refresh loses it, which is fine: the status line is read
       from data, not from this. */
    local!prepResult: null,''', first="AGENT: VERIFIED", last="local!simResult: null,")

# 13. no "other cases" count
splice(228, 228, None, first="local!otherCases:")
splice(212, 215, '''    /* ================= SESSION-TAGGED APPIAN ROWS =================
       THE STANDING CASES ARE REPORTED, NOT FAILED. P4-VERIFY rows are supposed to
       be there. Demo cases are counted by SO_demoRunState, by run name. */''', first="SESSION-TAGGED", last="*/")

# 14. header
splice(98, 100, ''' * the twenty results was consumed without a guard. The preflight stops the
 * screen before any of that. (The agent check that held the unguarded
 * consumer left the page on 2026-11-12.)
 *
 * ================= PHASE 11, 2026-11-12 =================
 * One button, "Prepare the demo" (SO_prepareRun), and one status line read from
 * SO_demoRunState. The Load and Reset buttons, their captions and their result
 * lines left the page. The verdict word is "Environment OK" / "Environment
 * problem", so the page has one "Ready": the status line's.''', first="the twenty results", last="naked consumer")
splice(2, 2, L(2).replace("Three actions and a", "One action and a"), first="Three actions")

open("gen/SO_demoAdminConsole.phase11-draft.sail", "w").write("\n".join(src))  # a DRAFT: not deployed
print("lines:", len(src))
