# CREDITS — Kiro credit usage for this build

One row per prompt turn, rebuilt by `.kiro/scripts/credits.py` from Kiro's own session records (`~/.kiro/sessions/`). The session-start hook rebuilds it at every session, and the close-out rebuilds it before writing `Closeout.md`; the close-out turn itself lands at the next session start. Nothing here is typed by hand.

- **Credits** and **Elapsed** are the figures Kiro records for the turn, the same ones its usage view shows.
- **Time** is the local time of the machine that rebuilt the file. **Prompt** is the first line of the message that started the turn, shortened.
- **Month to date** is the running sum of Credits for the calendar month of the row, this build only. The operator's monthly cap is per person, across every build they run.
- Rows are written only once `BUILD_PLAN.md` is populated. `python3 .kiro/scripts/credits.py --print` shows the table for any repo without writing it.

| Date | Time | Session | Prompt | Credits | Elapsed | Month to date |
|---|---|---|---|---|---|---|
