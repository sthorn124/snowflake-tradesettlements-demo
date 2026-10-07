---
inclusion: always
---

# Operating core — §7 Log, §8 TODO, §9 Promotion, §10 Close-out

## 7. The BUILD_LOG contract

- **Append-only session log** of what has actually been built in the environment: object names and UUIDs, versions, the decisions behind them and why, what was verified and how (with the account scope of every readback), what was not verified, and findings. Append after every build step. Corrections are new entries that name what they correct; superseded candidates in the staging section carry a bracketed in-place marker (`[RESOLVED …]`, `[REVERSED …]`, `[TRIAL REASSIGNED …]`) so a reader of that section alone never chases a dead trigger.
- **The readback is the record.** Object versions, states, and security are written from readback at close-out, never from memory; a close-out has recorded the wrong version by remembering it.
- **The tail provides continuity and is always consulted before acting** (§1). The log is the environment's state of record between sessions; `BUILD_PLAN.md` is the intent.
- **It is the staging area for promotion candidates** (§9): it carries the "Promotion candidates (staging)" section, and every entry that touches promotion ends with a promotion checkpoint.
- **Entry shape:** date and title; scope line (identity and groups every readback ran under, including the account behind each sail data directory); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and why, with the browser checklist); promotion checkpoint.
- **Structural deltas are logged like data deltas.** When a built layout departs from its mockup, say so in the log and fix the mockup in the next mockup pass, or the mockup and the build drift and neither is trustworthy.

## 8. The TODO.md contract

- **Open items by class.** The sections a build carries are: Blocking; Before demo; Browser checks owed (each with a human owner and the exact steps, personas, and expected strings); Client validation questions; Deferred (each with its trigger); Done (✅ with the date). Phase-specific sections may sit above these while a phase is live.
- **Sessions add discovered items unprompted as they surface** — deferred work, client questions, browser checks a session cannot perform, edge cases observed but not fixed — and any response that touched `TODO.md` ends with a `TODO changes:` line stating what was added, moved, or closed.
- **Every item carries an owner and a firing condition.** Parked work names the defined moment that fires it ("trigger: the next session that opens this object", "before another presenter runs it"); nothing is parked on "later".
- **Superseded items are struck through with a pointer to the standing decision**, not deleted, when the reasoning is worth keeping; completed items move to Done with the date. Retired mechanisms keep their numbering so references elsewhere still resolve.
- **A browser check a session cannot do is written as a checklist the human can run**, not as an open question.

## 9. The promotion loop

`BUILD_LOG findings → promotion candidates with named triggers → gate evaluation at close-out → promotion into the operating core, project.md, or skill files`, with a checkpoint that makes it self-enforcing.

1. **Capture.** A surprising observation is recorded in the build log as a candidate the session it is found — stated as the trap and the working form, marked STAGED with the gate it is held at (usually gate 1, one observation) and a **named trigger**: the defined moment that will confirm or discard it ("the next process model with a datetime parameter", "the first traversal verified in a row-secured app", "any session where a scoped read returns empty against data known to exist").
2. **Gate.** An entry is promoted only when all five hold: **measured**, not suspected (reproduction, a control, or a deliberate re-test — two observations in one direction are not reproduction); **survives the noun test** (stateable with zero project nouns); **earns its context cost** (contradicts the docs or the pack, or cost real time); **rule-shaped** (trap and working form, instance-dependent facts tagged "re-verify per instance"); **contradictions named** (which docs page or pack file it supersedes).
3. **Home.** Portable platform and Dev MCP facts go to appian-supplemental; project facts to the build's `.kiro/steering/project.md`; styling to the project skill; prompt-design and method observations that fail the noun test go to the project's agent eval log or `project.md`. One home per fact; the project file keeps at most an application pointer to a promoted entry.
4. **Close-out line.** Every close-out includes "Promotion candidates: N found; promoted / listed / none", so the session that discovers a finding classifies it while it is in context.
5. **Checkpoint.** The build log carries "Promotion checkpoint: current through `<entry>`". A session that touches promotion refuses to call itself complete if the checkpoint lags the log tail by more than one session.
6. **Trigger firing.** When a trigger fires, the candidate is ruled — promoted, discarded with the gate it failed, or re-staged with a new trigger — and the ruling is written into the staging section with a bracketed marker on the old entry. A candidate closed on insufficient evidence is reopened, and the reversal is recorded rather than the history rewritten.

## 10. The close-out routine

The final actions of every session, in this order:

1. **Write `Closeout.md`** — a full, dynamic write-out of everything that happened in the run, rewritten from scratch every session in one write: no fixed template, no growth, never patched, never appended to. Its first line is the session-date header `# Closeout — <YYYY-MM-DD> — <one-line title>`, so the Project can tell from the first line whether the file it fetched describes the session it expects; everything below the header follows the session. The file and the close-out printed in the session are the same document; if the session ran through several rounds, the close-out is written from the current state of the work, not accreted round by round. Its content follows the session — typically scope and identity, what changed by object, how it works, verified and not verified, the browser checklist, rulings needed, promotion candidates, TODO changes, `BUILD_PLAN.md` changes, the session's credits and elapsed time (the `credits.py` summary line), and **additions the prompt did not ask for**: anything built or changed beyond what the prompt named, each with a one-line reason, so the operator can keep it or cut it. Unprompted work is reported there, never left for the next session to discover.
   - **Credits and elapsed time come from Kiro's own records, never from the operator.** Run `python3 .kiro/scripts/credits.py` before writing the file: it rebuilds `CREDITS.md` from Kiro's session store (one row per prompt turn, with the month-to-date total) and prints the session's credits, elapsed time, and turn count so far. Quote that line in `Closeout.md`. The close-out turn itself is recorded at the next session start, when the hook runs the script again. If the script reports that Kiro's session store was not found, say so in `Closeout.md` and carry on.
2. **Update `BUILD_PLAN.md`** — mark items completed this session (`- [ ]` becomes `- ✅ <date>`) and add newly discovered tasks to the right phase. A close-out that built something but did not touch the plan is incomplete. The plan stays a high-level checklist; detailed specs live in the build prompts.
3. **Append the BUILD_LOG entry** (§7), ending with the promotion checkpoint.
4. **Evaluate promotion candidates** (§9) and write the promotion line. If a promotion changed the installed user-level skill (`~/.kiro/skills/appian-supplemental/SKILL.md`), copy it into the repo's `skills/appian-supplemental/SKILL.md` so the machine and the repo agree and the template pull request can be raised from the build repo.
5. **Update `TODO.md`** (§8) and print the `TODO changes:` line.
6. **Commit and push:** `git add -A`, `git commit -m "closeout: <date> — <one-line summary>"`, `git push origin main`.
7. **Verify the push landed.** `git fetch origin`, then confirm `git rev-parse HEAD` equals `git rev-parse origin/main` and `git status` reports nothing to commit. A push exit code is operation status, not evidence (§4): the next conversation reads `Closeout.md` from GitHub, so a close-out whose commit is not on `origin/main` has not been handed off. On a mismatch or a rejected push, report it as a failed close-out with the git output; never force-push to make it agree.

**The Stop hook re-checks steps 6–7.** `.kiro/hooks/closeout.json` runs when a turn ends. While a close-out is in progress (`Closeout.md` uncommitted, or a `closeout:` commit the upstream does not have), it reads git itself and, if the close-out has not landed, sends the facts back as a new message so the turn continues; after two such reminders it warns instead. It never pushes. Its reminder is a fact to act on, not an instruction to force anything. (Measured 2026-10-06, M3: the block-and-reinject and the warn at the third stop both fire live. The hook fires when the agent finishes responding; a user message that follows the stop skips it, so the guard accumulates only across unattended stops. M9 records whether Kiro asks before the commit.)
