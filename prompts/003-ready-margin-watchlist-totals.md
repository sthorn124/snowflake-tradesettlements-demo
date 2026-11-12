# Phase 11 follow-up: Ready margin, and the watchlist's totals

Two small changes, ruled by Scott on 2026-11-12. Read the deployed source of an object before changing it. No sail this session: every check runs through the Dev MCP as the design account, and says so.

## Part 1: Ready ends two hours before the hero's cutoff

**Why.** Ready now holds until the hero case's cutoff, about three hours after a load. The hero needs 1.15 hours of confirmation lag to fit its window, so about 1h55m after a load its screen stops agreeing with its own assessment while the console still says Ready.

**Change, in `SO_demoRunState` only.**

1. Ready ends when the hero case has under two hours to its cutoff. The two hours is one named value in the rule.
2. The state that follows Ready is the existing one. Its line now has two wordings:
   - before the cutoff: "Not ready. The hero case has under two hours to cutoff. Prepare the demo again."
   - at or after the cutoff: the existing line, "Not ready. The hero case passed its cutoff at <time>. Prepare the demo again."
3. Amber, button enabled, as now. A story out of place is still reported first. Nothing else in the rule moves, and the console is not edited.

**Pass conditions, on a real run with the clock set through `testRule`:**

- 121 minutes before the hero's cutoff: "Ready to present. Loaded today at <time>."
- 119 minutes before: the new line.
- After the cutoff: the existing "passed its cutoff" line.
- The console renders the new line in amber with the button enabled, and no error.
- A Prepare started from the new state ends in Ready.

## Part 2: The watchlist's totals are converted before they are added

**Why.** After a Prepare on 2026-11-12 the supervisor screen read 698.4M "Value at risk" and the watchlist 662.5M, as the same account at the same moment. The critical-window amounts differed too, 393.7M against 354.6M. In the saved copy of `SO_analystWatchlist`, the two totals add each row's amount across currencies and label the result "USD eq." The supervisor screen converts each row through `SO_fxToUsd` first. The project rule is that every cross-currency total goes through `SO_fxToUsd`.

1. The saved copy of `SO_analystWatchlist` is from 2026-09-24, and NY was changed by hand after that. Read the deployed source, save it over `.work/SO_analystWatchlist.sail`, and note what differed.
2. Reproduce first. Render both screens at the same moment. Record each screen's Value at risk, its critical-window amount and its count of open items. Confirm the cause in the deployed source, or report the real one.
3. Fix `SO_analystWatchlist`: every total that adds amounts across currencies converts each row through `SO_fxToUsd` before adding. The tile keeps "USD eq." and carries the conversion basis in its tooltip, as the project rule requires. The tooltip names no list of currencies.
4. Amounts shown per row stay in their own currency. Nothing else on the screen changes.

**Pass conditions:**

- As the same account at the same moment, the watchlist's two amounts equal the supervisor screen's when both count the same open items. If the counts differ, report both counts and why, and show the watchlist's total as the sum of its converted rows.
- Apart from those amounts and the tooltip, the watchlist renders as it did before the change: the same queues, counts, rows and order.
- `SO_supervisorCommand` is not edited.

## Not verified, by ruling

What each persona sees, and anything a person has to look at. Those are Scott's, below.

## Operator's browser checklist (Scott)

1. Your own account, Supervisor tab then Watchlist tab: the two Value at risk numbers match.
2. As `alex.analyst`, the watchlist: the Value at risk tile reads "USD eq.", its tooltip gives the conversion note, and the row of tiles is still even.
3. The console, about 65 minutes after a Prepare: the line reads "Not ready. The hero case has under two hours to cutoff. Prepare the demo again." in amber.

## Close-out

Core §10. Leave NY in the Ready state from the last Prepare, and say when Ready will end.
