# Closeout — 2026-11-13 — The console holds its own press and shows "Preparing" from it; no time beside the demo trade ids on the watchlist

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/004-console-press-and-batch-tag.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. One round. No Prepare was run, by the prompt.

**Scope and identity.** Every Appian call went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`, confirmed by assertion (`loggedInUser()` equal to that name validated clean; the same check with another name failed). Direct member of `SO Supervisors`, `SO Demo Admins` and `SO Users`, so every read below is full-scope. No sail, by the prompt. The runtime server's tools were present and never loaded or called. Three helper agents made read-only `testInterface` renders of the console under the same account.

## Preflight

- **Plan:** populated. **Dev MCP:** design surface present; `listRecordTypes` returned the application's 12 record types and User.
- **Versions:** plugin and server 26.9.5, build `20261026-140102`. The pins describe 26.6.105; sail here is 26.9.5; the App Market has 26.9.15. The update procedure was not run; its plan item is open. Bundle paths for NY: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` and `https://ny.appiancloud.com/suite/plugins/servlet/stateless/dev-mcp-bundle`.
- **Skills:** `appian-supplemental` Version 2026-11-10.4, installed copy byte-identical to the repo copy. The pack's manifest, `274ce627`, matches the plugin. Docs-search was consulted for both questions the prompt names.
- **Groups, by readback (direct members):** unchanged from 2026-11-12. `SO Users` holds `SO Administrators`, `SO Analysts`, `SO Supervisors` and two users; `SO Analysts` holds `alex.analyst`; `SO Supervisors` 11 users; `SO Demo Admins` 9 users.
- **Personas:** every sail session on the machine is expired. None was needed.
- **Ritual:** Prepare had run today (Scott, 15:25 UTC), so the re-date was not run.
- **Git:** the local folder was one commit behind `origin/main` (the prompt's second revision) and was fast-forwarded first.

## What changed on NY

| Object | Version | Change |
|---|---|---|
| `SO_demoAdminConsole` | 14 → 18 | From a press that started a run, the card shows the Running line and the button is disabled, from a value the press itself sets on the page. Version 15 is the change; 16 and 17 were one-line probes; 18 is the version 15 source restored |
| `SO_demoRunState` | 4 → 5 | A new output, `whenRunning`: the Running state's line, tone and `isRunning`. The page shows it from its own press. No line changed |
| `SO_analystWatchlist` | 24 → 25 | The time beside the demo trade ids is gone from the Trade column of both queues |

**Not changed on NY:** `SO_prepareRun`, `SO_prepareRunSteps`, `SO_supervisorCommand`, every record type, group and group membership. **No data written.**

## Part 1: the console after the press

### Why the line did not change

**Most likely cause: the page reads `SO_demoRunState` once, when it loads.** The rule is built from plain local variables, its queries and its `now()` among them. The Appian docs say, under Refresh always and under troubleshooting ("Nested rules need refreshAlways"): "If your variable's value comes from an expression rule that contains its own `a!localVariables()`, the inner variables won't re-evaluate when the outer variable refreshes—unless they use `refreshAlways: true`." Nothing those inner variables depend on changes while the page is open. So after the press the console's refresh-always variable did re-evaluate, and the rule handed back what it had read at page load. A new page load read the PREPARING record, which is what Scott saw after refreshing.

**What the docs rule out.**

- **The synchronous start.** With `isSynchronous` true, "`onSuccess` is not evaluated until the child process is complete, regardless of any activity chaining"; `onIncomplete` fires after 30 seconds. `SO_prepareRun` writes the run record before it completes. A start that had not completed would have shown a "Not prepared" block, and Scott saw none.
- **The order of saves and refreshes.** All saves in a `saveInto` are evaluated before any local variable is refreshed, and a `refreshAlways` variable is refreshed after each user interaction.

**What I could not confirm.** That this is what happened in Scott's browser, by measurement. A session renders a page once and cannot press. The cause fits everything he reported, and the docs describe this exact shape.

### The fix

- **The press sets the value.** The press already saved its answer on the page (`local!prepResult`). A new `local!startedHere` is true when that answer says a run started. From then the card reads `whenRunning` from the rule in place of what the page loaded with: the Running line, its neutral colour, and `isRunning` true.
- **The button** reads the same value. It stays disabled on the pressing page for as long as the page is open, and on any page loaded while the state is Running. It is enabled only on a refreshed page that reads a state other than Running.
- **A refusal or a failure** leaves `startedHere` false: the message shows in full and the button stays enabled.
- **One sentence, one home.** The Running wording stays in `SO_demoRunState`; the console does not carry a copy.

### Verified (as the design account)

**The page in the state NY is in.** Version 15 rendered twice at 15:49 and 15:50 UTC, and version 18 twice at 15:52: error null; "Ready to present. Loaded today at 10:25 AM by Scott Thorn." in `#17715B`; button enabled; nothing under the button. The verdict line, "Loaded now", the eight Details rows, the header and the caption match the version 14 render of 15:45.

**The other states' lines**, through `testRule` on rule version 5:

| Read | Returned |
|---|---|
| now | READY, "Ready to present. Loaded today at 10:25 AM by Scott Thorn." |
| `asOf` 16:31 UTC | "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." |
| `asOf` 18:31 UTC | "Not ready. The hero case passed its cutoff at 1:30 PM. Prepare the demo again." |
| `asOf` tomorrow 14:00 UTC | "Loaded before today. Prepare the demo again for fresh dates." |
| another run name, 90 seconds after the load | RUNNING, "Preparing the demo. About two minutes. Refresh this page to check.", `isRunning` true |
| another run name, now | "The last run did not finish. Prepare the demo again." |

"No demo loaded." and the story line cannot be reached on today's data; their lines are untouched in the source.

**Both outcomes of a press, on the real page.** The console's default for the press's answer was changed by one line, rendered, and restored:

| Probe | Status line | Button | Under the button |
|---|---|---|---|
| A: the press started a run | "Preparing the demo. About two minutes. Refresh this page to check.", `#454F5C` | `disabled` true | nothing |
| B: the press was refused | "Ready to present. …", `#17715B` | enabled | "Not prepared" in `#B3261E`, the time, and the message in full |

The probes were live for about a minute, from just after 15:50:44 UTC to before 15:52:01. The restore was read back twice, byte-identical to the saved source both times.

**The page's logic as a truth table**, through `validateExpression`: eight cases held, and the control with one wrong expectation failed.

## Part 2: the time beside the demo trade ids

The Trade cell of "Needs your action" and of "Escalated, with supervisor" each had a second item showing the row's batch scoring time. Both are removed, with the row key that fed them.

**Pass: no trade id on the page has a time beside it, and apart from that the page renders as before.**

- Version 24 at 10:45:41 Eastern against version 25 at 10:50:04, leaf by leaf: 3,815 leaves before, 3,799 after.
- 16 removed: the two "  10:25" items, on TRD9DEMO01 and TRD9DEMO02. None added.
- 8 changed, all the clock: "last read", six countdowns, "2.1h to cutoff" to "2.0h".
- All ten Trade cells now hold the trade id only.
- The band still reads "10:25 today · 15 trades on your desk".

## Decisions

- **The rule gained an output, though the prompt names only the console.** The alternative was a second copy of the ruled Running sentence inside the console.
- **The rule's own variables were not made refresh-always.** That would have made an open page re-read the state on each interaction. The ruling is no self-refresh, and the prompt asks for a fix that does not depend on a re-read.
- **The previous run's failure is hidden once this press starts a run.** Otherwise the pressing page would read "Preparing the demo" above an old "Not prepared".
- **The hidden branches were rendered on the live console by probe,** as core §4 prescribes, and restored. The probe messages said what they were.
- **The console's stale comment and description were corrected** in the same edit, as their `TODO.md` item's trigger said.

## Not verified

- **The press itself.** The checklist below. In particular, that the page turns to "Preparing" when the press's answer is saved: a session never sees a page re-evaluate.
- **The cause, by measurement.**
- **What each persona sees, and geometry.** No layout changed.

## Operator's browser checklist (Scott)

1. Press Prepare the demo. Without refreshing, the line reads "Preparing the demo. About two minutes. Refresh this page to check." and the button is disabled.
2. Refresh after 30 seconds: the same line, and the button is still disabled.
3. Refresh after two minutes: "Ready to present. Loaded today at <time> by Scott Thorn.", and the button is enabled.
4. The watchlist: no time beside TRD9DEMO01 or the other demo trades.

## Found, not fixed

- **A console page left open shows what it loaded with.** Its Ready line will not turn amber at the two-hour margin until the page is refreshed. Same cause as Part 1. In `TODO.md`.
- **The watchlist's countdowns may freeze between page loads,** for the same reason: `SO_cutoffDisplay` computes from `now()` inside its own local variables. Not measured. In `TODO.md` as a one-minute browser check: watch a countdown across two 30-second refreshes without reloading.

## State of NY

Ready, from Scott's Prepare of 15:25 UTC (10:25 AM Eastern), run record 6. Read at 15:52 UTC: "Ready to present. Loaded today at 10:25 AM by Scott Thorn." The hero case is 156; its cutoff is 18:30:37 UTC (1:30 PM Eastern). Ready ends at 16:30 UTC, 11:30 AM Eastern. No Prepare was run by this session.

## Promotion candidates

One found; none promoted; one listed in `BUILD_LOG.md` with its trigger: a rule's local variables are evaluated once per page, so a page value that must change after the page's own action is saved by that action and never waited for from a re-read of a rule. Documented by Appian, seen once in a browser by the operator, not measured by a session.

Promotion checkpoint: current through this session's entry. The header checkpoint line at the top of `BUILD_LOG.md` is still stale; its Blocking item stays open.

## BUILD_PLAN.md changes

Phase 11: a follow-up block for `prompts/004` with two items done (the console's press, the watchlist's Trade column) and one open (Scott's four-step browser check).

## Files

- `.work/SO_demoAdminConsole.sail`: the console, the version 15 source that version 18 holds.
- `.work/gen/rule_SO_demoRunState.sailt`, `.work/rule_SO_demoRunState.sail`: the rule, version 5.
- `.work/SO_analystWatchlist.sail`: version 25.
- `.kiro/steering/project.md`: a page reads the rule once; the button's rule.
- `BUILD_PLAN.md`, `BUILD_LOG.md`, `TODO.md`, this file.

**TODO changes:** closed one: the console's "other three amber" comment and "six states" description, corrected in this edit. Updated one: the Phase 11 browser checks (step 1 failed in Scott's check and is re-checked by `prompts/004`). Added three: the browser checks owed for `prompts/004`; an open console page showing what it loaded with; whether the watchlist's countdowns move on its 30-second refresh.
