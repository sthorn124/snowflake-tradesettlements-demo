# Two small fixes from Scott's browser check (2026-11-13)

Read the deployed source of an object before changing it. No sail this session.

## Part 1: The console shows "Preparing" straight after the press

**What Scott saw.** He pressed Prepare the demo on `SO_demoAdminConsole`. The status line and the button did not change until he refreshed the page. After the refresh the line read "Preparing the demo…" and everything else checked out. The ruled behaviour is that the line and the disabled button show straight after the press.

1. Find out why before changing anything. The button starts `SO_prepareRun` synchronously and `local!runState` is set to refresh always, so on paper the line should have changed. Check the docs for what a synchronous start waits for, and for when a refresh-always variable re-evaluates after a save. State the most likely cause and what you could not confirm.
2. Fix it so the result does not depend on that timing: the press itself sets a value on the page, and while that value is set and Prepare has not answered with a refusal or a failure, the page shows the Running line and disables the button. A refusal or a failure still shows in full and leaves the button enabled.
3. Nothing else on the console changes.

A session cannot press the button, so Scott verifies this part (checklist below). Verify what you can: the page renders with no error in the state NY is in, and the other states' lines are unchanged.

## Part 2: Remove the time beside the demo trade ids on the watchlist

**What Scott saw.** On `SO_analystWatchlist`, demo trades show a time after the trade id ("TRD9DEMO01 10:25"). It is the scoring time of the loaded batch. It has no label and appears on those rows only, so it reads as a mistake.

1. Remove that time from the Trade column in both queues that show it.
2. The Latest scoring batch band keeps its time. Nothing else on the screen changes.

Pass: no trade id on the page has a time beside it, and apart from that the page renders as it did before the change.

## Operator's browser checklist (Scott)

1. Press Prepare the demo. Without refreshing, the line reads "Preparing the demo. About two minutes. Refresh this page to check." and the button is disabled.
2. Refresh after two minutes: "Ready to present. Loaded today at <time> by Scott Thorn."
3. The watchlist: no time beside TRD9DEMO01 or the other demo trades.

## Close-out

Core §10. Do not run a Prepare; Scott's check does that.
