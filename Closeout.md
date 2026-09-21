# Closeout — 2026-09-11 — Phase 5 Part B2: intake + console wiring

Everything is built, validated and read back, but nothing in B2 has run end to end yet. Your live pass is next; Part C follows once I've reviewed it.

## (a) What changed

**Created.** The three process models are in folder `5f7c8683-5e88-4782-b217-7978c6321f0e`; the rule and constants are in the app's rules folder.

| Object | Type | ID |
|---|---|---|
| `SO_intakePlan` | expression rule | `_a-0000f060-57b9-8000-9c4d-011c48011c48_565618` |
| `SO_intakeRun` | process model | `0000f060-f4bd-8000-2419-7f0000014e7a` |
| `SO_simulateRun` | process model | `0000f060-f4ba-8000-2418-7f0000014e7a` |
| `SO_resetRun` | process model | `0000f060-f4bf-8000-241a-7f0000014e7a` |
| `SO_PM_SIMULATE_RUN` | constant | `…565636` |
| `SO_PM_RESET_RUN` | constant | `…565642` |
| `SO_PM_INTAKE_RUN` | constant | `…565648` |
| `SO_PM_TRIAGE_CASE` | constant | `…565654` |
| `SO_PM_CREATE_TRIAGE_CASE` | constant | `…565673` |

**Modified**
- `SO_demoAdminConsole` (`_a-0000f057-1da8-8000-9c4b-011c48011c48_564828`), v4 → v5:
  - **Load the trade feed** is live.
  - **Delete this run's data** now cleans both Appian and Snowflake.
  - The manual Snowflake step is gone.
  - The example run name is now `1012-ACME`.
- **Files:**
  - appian-supplemental (both promotions);
  - CLAUDE.md (Demo Admin rules; criterion now points to `SO_intakePlan`);
  - TODO.md, the build plan, the build log (then `build-log.md`, now `BUILD_LOG.md`), and this file.

**Left alone**
- `SO_triageCase`, including its "Context resolved?" check.
- `SO_createTriageCase`.
- Both integrations and the connected system.
- The four persona screens, all groups, and Snowflake.
- Two throwaway probe rules were created and deleted.

**Your Task 0 grants, as read back**
- **`SO Snowflake SQL API`:** SO Demo Admins has viewer, granted directly on the object. Matches.
- **`SO_simulateFeed` and `SO_resetSession`:** SO Demo Admins has viewer, but inherited from the Rules folder `02e190ca-6878-4c1c-a355-11d377181211`. That folder grants viewer directly to SO Users and SO Demo Admins.
  - The effect is what you intended.
  - The mechanism is a folder grant, so it also reaches every other object in that folder that inherits security.
  - I reported it and changed nothing.
- **SO Integration Services** is removed from TODO as rejected: the PAT in the connected system already is the service credential.

## (b) How intake works

- **What starts it:**
  - After Load, `SO_simulateRun` starts `SO_intakeRun` in the background, but only if Snowflake's message begins `OK run=`.
  - A REFUSED message, a failed call, or a slow call that returns no message starts nothing.
- **Tier check:**
  - `SO_intakePlan` rebuilds the run's 15 trade IDs the same way Snowflake does.
  - It then asks SO Trade Predictions which of those are High or Critical.
  - There is no hard-coded ID list; the three stories qualify because of their tiers. Background trades sit below 0.5003, so they never come back.
- **Case creation:**
  - Each qualifying trade gets its story details by the last two digits of its ID:

    | Seq | Fail reason | Cutoff |
    |---|---|---|
    | 01 | `insufficient_securities` | +3h05m |
    | 02 | `funding_gap` | +2h30m |
    | 03 | `operational_error` | +9h |

  - `SO_intakeRun` loops over the qualifying trades, at most 15 times:
    1. It runs `SO_createTriageCase` and waits for it.
    2. It finds the new case.
    3. It starts `SO_triageCase` for that case without waiting.
  - The triage model's existing "Context resolved?" check then runs unchanged.
  - A High or Critical trade with no story row gets no case.
- **Idempotency, three layers:**
  1. **The plan** skips any trade that already has a case in this run, in any status. That covers resolved cases too.
  2. **`SO_createTriageCase`** keeps its own open-case check.
  3. **Triage** is only started on a case found in status New for that trade and run.

  Loading the same run name again reloads the same 15 Snowflake rows by exact ID and creates no new cases.

## (c) Reset order

**Order:** Appian first, then Snowflake, and Snowflake only if the Appian delete succeeded.

**Why:**
- Cases point at trades by trade ID, but trades never point at cases.
- If Snowflake went first and the Appian delete then failed, live cases would stay on the watchlist with empty trade, prediction, counterparty and instrument data. That is the same blind-read situation that once produced a forged escalation.

**What a failure leaves behind:**
- **Appian delete fails:** `SO_resetRun` stops and says Snowflake was not touched. Nothing is inconsistent.
- **Appian delete works, Snowflake call fails:** 15 packet rows are left with no cases.
  - They don't show on any screen and are excluded from the baseline checks.
  - Pressing Delete again removes them, since `RESET_SESSION` deletes by exact ID.

This is the same order as Phase 4's reset, which cleared Appian and left Snowflake as a later step. Both buttons also upper-case the run name, so the Appian session tag and the Snowflake IDs can never differ on casing.

## (d) Live-test script (console, as your own account)

Use a run name you haven't used today. The script uses `b2-test`, typed in lowercase on purpose.

1. **Baseline:** open the Demo Admin site and check panel 1.
   - Everything is green.
   - Note these readings (this morning at 11:54): demo-run trades 0, leftover 0, built-in 17, case comments 12, audit rows 14.
2. **Load:** in panel 2, type `b2-test` and press **Load the trade feed**. Within about 10 seconds you should see:
   - green **"Feed loaded for run B2-TEST"**;
   - the message verbatim: `OK run=… trades=15 predictions=15 high_or_critical=3`.
   - If you get "could not start" or "No answer within 30 seconds", stop there and send me the text.
3. **Wait:** give it about 2 minutes, then reload. Panel 1 should show:
   - demo-run trades 15;
   - leftover "3 cases from run B2-TEST". Red is expected while a run is live.
4. **Three cases, no background cases:**
   - In panel 3, type `b2-test`. It should read "Will delete 3 cases". Don't press Delete yet.
   - Signed in as `sam.supervisor`, who sees every desk, the run's cases are for trades `TRD9B2TEST01`, `02` and `03`, with nothing ending 04–15.
   - Three matches `high_or_critical=3` from step 2.
5. **Hero case:** open the case for `TRD9B2TEST01` (EQ_FLOW, `insufficient_securities`). Expect:
   - status **Awaiting review**;
   - **auto-release score 62, releases at 80**;
   - an AI assessment.

   0.62 was measured on 2026-09-02 and comes from the agent, so it can vary:
   - right status, different score → write the score down;
   - different status → send it to me.

   Note what cases 02 and 03 did (packet-spec expects Escalated and Resolved · straight through), but don't block on them.
6. **Refused path:**
   - In panel 2, type `1012-ACME-EXTRA` (15 characters) and press Load. Expect red **"Not loaded — refused"** and the message verbatim: `REFUSED: a run name is 1 to 13 letters, digits or dashes, e.g. 1012-ACME.`
   - Then type `p4-verify`. Load should be disabled, with the red built-in-test-data line.
7. **Optional, repeat load:**
   - Type `b2-test` again and press Load. Expect the OK message again.
   - Reload after a minute: B2-TEST should still have exactly 3 cases.
8. **Reset:**
   - Wait until all three cases show a triage result, so none is still New or In triage.
   - In panel 3, with `b2-test` typed, press **Delete this run's data**.
   - Expect green **"Cleaned up: B2-TEST"**.
   - Expect the result verbatim: `OK run=… trades_deleted=15 predictions_deleted=15`.
   - Expect "Appian was: 3 cases · N comments · M audit rows" and, in green, "Appian now: 0 cases · 0 comments · 0 audit rows".
9. **Both sides clean:** reload. Panel 1 should be back to the step 1 numbers.
   - Demo-run trades 0. This line reads the Snowflake trade table, so it is the Snowflake-side check.
   - Leftover 0, built-in 17, case comments 12, audit rows 14.
   - The watchlist shows no B2-TEST case.
10. **Send back:**
    - the step 2, 6 and 8 messages, verbatim;
    - the hero's status and score;
    - the step 9 numbers;
    - anything that didn't match.

## (e) What I stopped on and what's still open

1. **Identity — stopped, nothing changed.**
   - The integrations' SO Demo Admins viewer comes from the folder, as described in (a).
   - I only need a ruling if you don't want the folder-wide scope.
2. **Nothing in B2 has been executed.**
   - My one safe test was `SO_intakeRun` on a run name with no data (no writes, no integration calls). The session's permission checker blocked it, and I didn't retry or work around it.
   - `SO_simulateRun` and `SO_resetRun` were deliberately never run, because they call the integrations.
   - So every path is validated and read back, but your pass is the first real execution.
3. **Process-model security — not granted, since identity is closed.**
   - The three new models have the app default: viewer for SO Users, Supervisors and Analysts.
   - Someone only in SO Demo Admins can't start them. Your own account is fine.
   - This needs a ruling before another SC presents.
4. **Presenter scope.**
   - Intake and triage run as whoever presses Load, and predictions are secured by desk.
   - The presenter must be in SO Supervisors; otherwise intake quietly finds only their own desk's stories.
5. **Judgement calls — tell me if either is wrong.**
   - **Name format:** the console shows the run-name rule as guidance but doesn't block on it.
     - Part A said the console validates names.
     - B1 said the Snowflake procedures own the guard rules.
     - This test needs the REFUSED message to be reachable.
     - Only P4-VERIFY is blocked on the Appian side.
   - **Upper-casing:** I also added upper-casing of the run name on both buttons.
6. **Known edge cases, logged in TODO with triggers:**
   - **Delete during triage:** untested. Step 8 says to wait for triage to finish first.
   - **Double Load:** loading the same name twice within a minute could triage one case twice.
   - **Cascade:** I'm assuming the Delete Records node removes comments and audit rows along with each case. That is based on Phase 4's `a!deleteRecords` test, not this node. The counts in steps 8 and 9 will confirm or disprove it.
7. **Cosmetic, left alone because this pass was additive only:**
   - `SO_triageCase`'s description is out of date.
   - The error-alert group I sent (SO Administrators) reads back as null on all three new models, the same as on the existing ones.

**Promotion candidates:** 2 found, both from B1, and both promoted to appian-supplemental §4. B1's third candidate (`false` reading back as `null`) is folded into one of them. B2 found nothing new; NTZ-as-UTC and chart-type stay staged.

**TODO changes:**
- **Closed:**
  - the SMOKE retest;
  - the B2 identity decision;
  - SO Integration Services (rejected);
  - the caller contract;
  - run-name guidance;
  - removal of the manual Snowflake step.
- **Added**, as a new Part B2 section:
  - your live pass;
  - a ruling on process-model security;
  - the presenter-in-Supervisors requirement;
  - an optional ruling on the folder grant;
  - delete during triage;
  - double Load;
  - `SO_triageCase`'s stale description.

**Build plan:**
- B1 marked done.
- Intake and console wiring marked built, awaiting your live pass.
- Part C item added.
- Reset Demo item annotated.
