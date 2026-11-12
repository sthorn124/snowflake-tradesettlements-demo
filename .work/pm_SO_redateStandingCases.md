# SO_redateStandingCases: outline

Built on NY on 2026-11-12 through the Dev MCP as `scott.thorn@appian.com` (Phase 11). Published version 5.0. UUID `0000f0b2-31f0-8000-2c8b-7f0000014e7a`. Constant `cons!SO_PM_REDATE_STANDING_CASES`.

Started synchronously by `SO_prepareRun`, or by a build session through `testProcessModel`. No parameters. Every node runs as the initiator. Security: the same role map as `SO_simulateRun` (initiator `SO Demo Admins`).

Variables: `clock` (Date and Time), `missing` (Text), `message` (Text), and three error pairs: `errCases`, `errComments`, `errEvents` (each with a `…Msg`).

| Order | Node (id) | Reads | Writes |
|---|---|---|---|
| 1 | Start (1) | | |
| 2 | Script "Set the clock and check the ids" (3) | `rule!SO_standingCaseRedate(clock: null)`: now rounded down to the hour in UTC; and the ids in `SO_standingCaseOffsets` that are not readable on the site | `pv!clock`, `pv!missing` |
| 3 | XOR "Every listed id on the site?" (4) | `clock` present and `missing` empty | Routes: yes to 6, otherwise to 5 |
| 4 | Script "Stop: ids differ" (5) | `missing` | `pv!message` = "STOPPED: nothing was re-dated. …" naming the rows. Then End |
| 5 | Write Records "Re-date the cases" (6) | `rule!SO_standingCaseRedate(clock: pv!clock).caseRecords` | 17 SO Settlement Case rows by `caseID`: `cutoffTs`, `createdOn`, `modifiedOn`, and `resolvedOn` on 41, 42 and 50 only. Saves `errCases` |
| 6 | XOR "Cases written?" (7) | `errCases` | Routes: written to 8, failed to 13 |
| 7 | Write Records "Re-date the comments" (8) | `.commentRecords` | 12 SO Case Comment rows by `id`: `createdOn`. Saves `errComments` |
| 8 | XOR "Comments written?" (9) | `errComments` | Routes: written to 10, failed to 13 |
| 9 | Write Records "Re-date the events" (10) | `.eventRecords` | 14 Event History rows by `id`: `timestamp`. Saves `errEvents` |
| 10 | Script "Report the result" (13) | the three error flags | `pv!message`: "OK standing cases re-dated: 17 cases, 12 comments, 14 events. Clock … UTC." or "FAILED: …" naming the table that stopped it |
| 11 | End (2) | | |

Notes
- The offsets are in `SO_standingCaseOffsets`, in minutes. The stamps and the record values are computed by `SO_standingCaseRedate`. The model holds no offset.
- Every write names its ids. Nothing is selected by query. Each record carries its primary key and only the time fields, so no other field of a row changes.
- Every Write Records node has `PauseOnError` false and `CaptureEvents` false. No audit event is written.
- One Write Records node per record type. A single node for all three was tried and refused: "The input "Records" can only include related record types with the same data source as the base record type. Received: SO Case Comment".
- Measured 2026-11-12: after a run, all 43 rows equalled what `fixtures/p4-verify-redate.py` produces for the same UTC hour; three rows broken on purpose (one per table) were restored; a wrong parent in the offsets table stopped the run at node 5 with nothing written.
- Run time: 6.8 seconds standalone, 8.2 seconds inside `SO_prepareRun`.
