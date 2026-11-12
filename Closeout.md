# Closeout — 2026-11-12 — Ready ends two hours before the hero's cutoff and names who loaded the run; the watchlist's totals convert before adding; the documents no longer point at the hidden "Cleared this batch" card

**Session.** Ran in **Claude Code**, not Kiro, from `prompts/003-ready-margin-watchlist-totals.md`. The credits step of core §10 is skipped: `CREDITS.md` is built from Kiro's own records. Three rounds: the prompt's two parts, then two rulings (the hidden card, the two `nick.bethune` accounts).

**Scope and identity.** Every Appian call went through the Dev MCP (server `appian`) as `scott.thorn@appian.com`. The account was confirmed by assertion: `loggedInUser()` equal to that name validated clean, and the same check with another name failed. It is a direct member of `SO Supervisors`, `SO Demo Admins` and `SO Users`, so every read below is full-scope. No sail, by the prompt. The runtime server's tools were present in the session and were never loaded or called. Three helper agents made read-only `testInterface` calls under the same account and reported what they read.

## Preflight

- **Plan:** populated. **Dev MCP:** design surface present, 218 tools counted under `appian`; `listRecordTypes` returned the application's 12 record types and User.
- **Versions:** plugin and server 26.9.5, build `20261026-140102`. The pins describe 26.6.105 (build `20260930-110421`) and sail 26.6.105; sail here is 26.9.5. The App Market has 26.9.15. The update procedure was not run; the plan item for it is open. Bundle paths for NY: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads`, and the link the version tool prints, `https://ny.appiancloud.com/suite/plugins/servlet/stateless/dev-mcp-bundle`.
- **Skills:** `appian-supplemental` Version 2026-11-10.4, the installed copy byte-identical to the repo copy. The pack's manifest, `274ce627`, matches the plugin's `composerCommit`. Pack references read: `expression-rules.md`, `query-record-type-patterns.md`, `interface-generation-checklist.md`.
- **Groups, by readback (direct members):** `SO Users` holds `SO Administrators`, `SO Analysts`, `SO Supervisors` and two users. `SO Analysts` holds `alex.analyst` and no group. `SO Supervisors` 11 users. `SO Demo Admins` 9 users.
- **Personas:** every sail session on the machine is expired. None was needed.
- **Ritual:** Prepare had run today at 14:28 UTC, and this session ran it again at 17:25 UTC before rendering the two screens.
- **Git:** clean and level with `origin/main` at the start.

## What changed on NY

| Object | Version | Change |
|---|---|---|
| `SO_demoRunState` | 3 → 4 | Ready ends when the hero has under two hours to its cutoff. The two hours is `local!readyMarginHours`. The state that follows keeps its name, HERO_PAST_CUTOFF, and its line has two wordings. The Ready line ends "by <first and last name>". New outputs `heroPast` and `loadedBy` |
| `SO_analystWatchlist` | 23 → 24 | Each row carries `usd`, from `SO_fxToUsd`. Both money totals add `usd`. Both tiles that show a "USD eq." amount carry the conversion basis in their tooltip |

**Not changed on NY:** `SO_demoAdminConsole` (version 14), `SO_supervisorCommand` (version 11), `SO_prepareRun`, `SO_prepareRunSteps`, `SO_kpiCard`, `SO_fxToUsd`, every record type, every group and every group membership.

**Data written:** one Prepare (run record 5). It cleared the 14:28 run, re-dated the standing cases and loaded a fresh packet. Demo cases are now 153, 154 and 155.

## Rulings made this session (Scott, 2026-11-12)

1. **The hidden "Cleared this batch" card: "Edit the documents."** The card stays hidden. The documents were edited (next section).
2. **The two `nick.bethune` accounts: "don't worry about nick bethune users".** `nick.bethune` is in `SO Demo Admins` only and `nick.bethune@appian.com` in `SO Supervisors` and `SO Users` only. No membership was changed. `project.md` now says a group readback finds these two and leaves them alone.

## What changed in the documents

After the first ruling.

| File | Line | Change |
|---|---|---|
| `demo-script-15min-client-awareness.md` | 92 | "Scroll to **Cleared this batch** (collapsed) and point at its summary line. Then Tab C." is now "Then Tab C." |
| `video-script-5min.md` | 49 | The screen direction ends at the escalated row; it no longer goes on to the card |
| `video-script-5min.md` | 51 | The spoken line ends at "The rules decide what it's allowed to do on its own." The sentence "And cleared this batch is everything that never needed a person." is gone |
| `talk-track-10min-internal.md` | 102 | The "On screen" cell quoted "Cleared by Snowflake scoring", text on the hidden card. It now quotes the band: "12 cleared by Snowflake" |

**Two of these four go beyond the ruling's two lines.** The sentence on video line 51 was the narration over the shot that line 49 dropped. The talk track's quote named text that is not on the page. Say so if either should go back.

No document mentions the card now (`grep` across the four documents and `GETTING_STARTED.md`). The claude.ai Project's copies of the three documents are four lines behind the repo.

## Part 1: the Ready line

**How it works.** The rule already knew the hero case's cutoff. It now compares the time left with the margin: two hours or more is Ready; less is not. Past the cutoff the old line is used; before it, the new one. For the name, the rule reads the newest `SO Demo Run` row with status LOADED for the run name. If the packet's load stamp falls between that row's press and its close, the row belongs to the run now loaded, and the rule looks up the account's first and last name in the user directory. Otherwise the line ends at the time, as before.

**Reproduced first.** At 17:22 UTC version 3 read "Ready to present. Loaded today at 9:28 AM." with the hero's cutoff 11 minutes ahead.

**Pass conditions and results** (the prompt's; as the design account).

| Pass condition | Result |
|---|---|
| 121 minutes before the hero's cutoff: Ready, with the name of the account that started the run | `asOf` 15:33:00 UTC on the 14:28 run: READY, "Ready to present. Loaded today at 9:28 AM by Scott Thorn." Run record 4 names `scott.thorn@appian.com` |
| 119 minutes before: the new line | `asOf` 15:35:01 UTC: "Not ready. The hero case has under two hours to cutoff. Prepare the demo again.", amber tone |
| After the cutoff: the existing line | `asOf` 17:35:00 UTC: "Not ready. The hero case passed its cutoff at 12:34 PM. Prepare the demo again." |
| The console renders the Ready line and the new line with no error, the new line in amber with the button enabled | New line, 17:24:54 UTC: error null, colour `#96590A`, button `disabled` false, no "Ready to present" on the page. Ready line, 17:28:22 UTC: error null, "Ready to present. Loaded today at 12:25 PM by Scott Thorn.", colour `#17715B`, button `disabled` false |
| A Prepare started from the new state ends in Ready | Started at 17:25:25 UTC with the state reading HERO_PAST_CUTOFF, 8 minutes 35 seconds before the cutoff. Answered in 4.72 seconds. Running at 29 and 73 seconds after the load. Run record 5 closed as LOADED 33.6 seconds after the press. Ready at 107 seconds |

**Also measured.** On the run now loaded, `asOf` 18:31:00 UTC (2 h 0.17 s before the cutoff) is Ready and 18:31:01 is the new line. On the real clock the same run read Ready at 18:08 UTC and the new line at 18:47 UTC. A run name with no run record returns an empty `loadedBy` and no error.

**The three demo documents and the status line.** Read. Each quotes only "Ready to present" from it: `demo-script-15min-client-awareness.md` lines 30, 31 and 168; `talk-track-10min-internal.md` line 11; `video-script-5min.md` line 9. Part 1 changed none of them.

## Part 2: the watchlist's totals

**The saved copy.** It was version 21. NY held version 23. The deployed source was saved over the copy and committed before any edit. What differed:

- **Version 22** (2026-10-23 00:42 UTC, `scott.thorn@appian.com`): `todecimal()` around `cutoffSortKey`.
- **Version 23** (2026-10-23 12:32 UTC, same account): parameters reordered throughout, as a Designer save does, and the "Cleared this batch" card's `showWhen` changed from `local!hasBatch` to the text `"false"`.
- **No save:** `a!cardGroupLayout` now reads back as `a!cardGroupLayout_26r6` on every stored version.

**The "Cleared this batch" card is not on the page.** The source hides it and the render does not contain its header. Two documents told the presenter to scroll to it; by the first ruling above they no longer do. The watchlist was not changed for this.

**Reproduced first.** Both screens rendered in one message; both stamped 12:28:24 Eastern.

| Screen | Open items | Value at risk | Inside critical window |
|---|---|---|---|
| Watchlist, version 23 | 16 | 662.5M USD eq. | 7 · 354.6M USD eq. |
| Supervisor | 16 | 698.4M USD eq. | 7 · 393.7M USD eq. |

**Cause, confirmed in the deployed source.** The watchlist's `local!varTotal` and `local!inWindowValue` added each row's amount as stored. The supervisor screen adds each row's `SO_fxToUsd` value. The two screens use the same open statuses and the same critical-window test, which is why the counts agreed and the amounts did not.

**After the fix.** Both screens rendered in one message; both stamped 12:32:48 Eastern; error null on both.

| Screen | Open items | Value at risk | Inside critical window |
|---|---|---|---|
| Watchlist, version 24 | 16 | 698.4M USD eq. | 7 · 393.7M USD eq. |
| Supervisor, version 11 | 16 | 698.4M USD eq. | 7 · 393.7M USD eq. |

**Pass conditions and results.**

| Pass condition | Result |
|---|---|
| Same account, same moment: the watchlist's two amounts equal the supervisor screen's when both count the same open items | Equal: 698.4M and 393.7M on both, 16 open items and 7 inside the window on both |
| Apart from those amounts and the tooltip, the watchlist renders as before: same queues, counts, rows, order | The version 23 and version 24 renders compared leaf by leaf: 3,815 leaves each, none added or removed, 13 changed. Those are the two amounts, the two tooltips, the "last read" clock, six countdowns four minutes shorter (one changing colour as it passed two hours), and "2.4h to cutoff" becoming "2.3h" |
| `SO_supervisorCommand` is not edited | Version 11, saved 2026-09-25, byte-identical to the saved copy. Its two renders differ only in clock-driven values (20 of 5,422 leaves) |

**The tooltip.** Value at risk: "Live from Snowflake — computed in Snowflake over the trade and prediction data, not copied here.  Cross-currency total: nothing in the source data carries an FX rate. Converted at indicative static rates (SO_fxToUsd) for aggregation only — not a market feed, not a rate of record." It names no currencies. The "Inside critical window" tile carries the second part, because its amount is converted too.

**Per-row amounts** are unchanged and in their own currency: the row cells are among the leaves that did not change.

## Decisions

- **The state keeps its name.** HERO_PAST_CUTOFF now starts two hours before the cutoff; `heroPast` says which side.
- **The margin is one number; the words "under two hours" are the ruled sentence.** A different margin needs a different sentence. The rule's header says so.
- **The name comes from the row that matches the load,** not from the newest row. A later Prepare that failed, or a run loaded without Prepare, would otherwise put the wrong name on the line.
- **The name is read with a query on the User record type, not `user()`.** A username the directory does not hold then gives no name. With `user()` it would fail the rule, and the console and Prepare with it.
- **Both watchlist tiles carry the conversion basis.** The prompt names one. The project rule covers every converted figure.
- **One Prepare only.** A second presenter uses NY, so the session started the one Prepare the pass condition needs and no other, including after Ready ended.
- **The documents were edited to the page as it is,** including one spoken sentence and one quoted label that the ruling did not name.

## Not verified

- **What each persona sees,** by ruling. `alex.analyst` is scoped to one desk, so her totals will not equal the house figures.
- **Anything a person has to look at:** whether the row of tiles is level, the tooltip on hover, the colour of the line.
- **Three ways the Ready line ends at the time:** a run loaded without Prepare, a run record with no account, an account missing from the directory. Read from the source. Only "no LOADED record" was measured.
- **A story out of place inside the two-hour margin.** The order of the tests is read from the source and did not change.
- **The re-date inside this Prepare.** The run record closed as LOADED. The stamps were not compared.
- **The video script's timing** with one sentence fewer. Not read aloud.

## Operator's browser checklist (Scott)

1. The console after a Prepare: the Ready line ends with your name.
2. Your own account, Supervisor tab then Watchlist tab: the two Value at risk numbers match.
3. As `alex.analyst`, the watchlist: the Value at risk tile reads "USD eq.", its tooltip gives the conversion note, and the row of tiles is still even.
4. The console, about 65 minutes after a Prepare: the line reads "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." in amber. NY is in this state now, until 3:31 PM Eastern.

## Rulings needed

1. **The supervisor screen's tooltip** still says "the book runs EUR, GBP, JPY and CHF", and its critical-window tile has no conversion note. Rule whether to bring it level with the watchlist.

## State of NY

Loaded by the Prepare of 17:25 UTC (12:25 PM Eastern), run record 5, started by `scott.thorn@appian.com`. The hero case is 153; its cutoff is 20:31:00 UTC (3:31 PM Eastern).

- **At the first close-out, 17:37 UTC:** Ready, "Ready to present. Loaded today at 12:25 PM by Scott Thorn." The close-out said Ready would end at 18:31 UTC, 1:31 PM Eastern.
- **Now, read at 18:47 UTC:** "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." Ready ended when it was said to.
- **From 3:31 PM Eastern:** "Not ready. The hero case passed its cutoff at 3:31 PM. Prepare the demo again."

No Prepare was started after Ready ended. The next presenter presses Prepare, as the line says.

## Promotion candidates

Three found; none promoted; three listed in `BUILD_LOG.md` with their triggers.

- Two renders of one interface differ only in component ids, save tokens and clock-driven values, so a before/after render can be compared leaf by leaf by a script. Measured on two interfaces.
- `testInterface` did not honour `maxResponseSizeBytes`. One observation.
- `testRule` returns an empty Text as `null`. One call, three fields.

Promotion checkpoint: current through this session's last entry. The header checkpoint line at the top of `BUILD_LOG.md` is still stale; its Blocking item stays open.

## BUILD_PLAN.md changes

Phase 11: the Ready line's copy updated, the second hero wording added, and a follow-up block for `prompts/003` with six items, all closed: the margin, the name, the totals, the saved copy, the hidden-card ruling, the `nick.bethune` ruling.

## Files

- `.work/gen/rule_SO_demoRunState.sailt`, `.work/rule_SO_demoRunState.sail`: the rule, version 4. `.work/gen/expand.py` gained the User record type.
- `.work/SO_analystWatchlist.sail`: version 24, the file the save wrote back.
- `.work/gen/render_leafdiff.py`: new. Compares two saved `testInterface` renders leaf by leaf.
- `demo-script-15min-client-awareness.md`, `video-script-5min.md`, `talk-track-10min-internal.md`: four lines, for the hidden card.
- `.kiro/steering/project.md`: the status-line paragraph, the cross-currency rule, the `.work/gen` line, and the standing decision on the two `nick.bethune` accounts.
- `BUILD_PLAN.md`, `BUILD_LOG.md` (three entries), `TODO.md`, this file.

**TODO changes:** closed three: "Value at risk differs between the two screens", "Ready holds until the hero's cutoff itself, with no margin", and the hidden "Cleared this batch" card (found and ruled this session). Struck one with its ruling: the two `nick.bethune` accounts (found and ruled this session). Updated four: the `SO Demo Run` pruning item, the console-comment item, the story-out-of-place item, and the Phase 11 browser checks. Added seven that are open: the supervisor screen's tooltip; the watchlist's Value sort across currencies; the state name HERO_PAST_CUTOFF; the three unexercised no-name paths; the browser checks owed for `prompts/003`; the watchlist still describing three queues; the Project's copies of the documents being behind the repo.
