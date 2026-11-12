# Closeout — 2026-11-11 — plan from 2026-11-11; `CLAUDE.md` loader; build returns to Claude Code

**Scope.** Maintenance only, run from the claude.ai Project with push access to this repo. No Dev MCP call. No Appian object and no Snowflake object was read or changed. The last build session on record remains 2026-09-24.

**Rulings recorded (Scott, in the planning chat, 2026-11-11).**
- Build sessions run in Claude Code. The Kiro files stay in place and remain the one copy of the rules.
- Order: Phase 10 (sync, no build), then Phase 11 (demo setup experience), then the next phase is chosen.
- Phases 7, 8 and 9 are on hold. The life sciences replication and the generic template are dropped.
- Phase 11 console design: one Prepare button; one status line with four states; the button disabled for the whole run; a stuck run unlocks itself; no progress bar; no self-refreshing page. Prepare re-dates the standing cases and does not generate them.

**What changed, by file.**
- `BUILD_PLAN.md`: a "Plan from 2026-11-11" section (order, build tool, holds, dropped and parked items, candidates after Phase 11); Phases 7, 8 and 9 marked on hold in their headings; new blocks for Phase 10 (sync), Phase 11 (demo setup experience) and Phase 12 (Databricks, approach proposed and not ruled).
- `CLAUDE.md`: added. It holds no rule text. It imports the eight always-loaded steering files (`core-00` to `core-06` and `project.md`) and lists what Kiro enforces that Claude Code does not.
- `TODO.md`: the two Kiro-era Before demo items closed as superseded; one item added (confirm `CLAUDE.md` loads the rules).
- `BUILD_LOG.md`: the 2026-11-11 entry.
- Scott's local commit `1e21f5f` (fixtures re-dated 2026-10-23, made by a Claude Code session while the repo had no `CLAUDE.md`) was rebased and pushed by Scott on 2026-11-11.

**How the build runs now.** A Claude Code session opened on this folder loads `CLAUDE.md`, which pulls in the rules from `.kiro/steering/`. Kiro's hooks and permission file do not run under Claude Code, so the session holds six things itself: it runs `python3 .kiro/scripts/preflight.py` at the start, honours the plan gate, never calls the runtime server, asks Scott before any Dev MCP delete, runs the full close-out with push verification, and skips the credits step. `CLAUDE.md` lists them.

**The next session.** Phase 10's read-only audit of NY. Its first check is that the rules loaded: the session should be able to state core §10's steps without reading a file. The prompt comes from the planning chat.

**Verified.**
- Every `@` import in `CLAUDE.md` and every file it names exists in the repo.
- `plan_status()` in `.kiro/scripts/method_lib.py` returns populated after the plan edits.
- Scott's local folder and `origin/main` were level at `1e21f5f` before this commit, read on his machine (`git status` clean).
- Push verified by `HEAD` equal to `origin/main`.

**Not verified.**
- `CLAUDE.md` has not been loaded by a Claude Code session. Whether the imports resolve on Scott's machine is the next session's first check.
- NY has not been read by a recorded session since 2026-09-24. The 2026-10-22 and 2026-10-23 changes (a watchlist sort fix, the hand re-date, the "Cleared this batch" card hidden in Designer, the blank cases) are known from the planning chats only.
- The Databricks facts in Phase 12 are as Scott reported them. No session has read NY or Databricks for them.
- Whether `appian-supplemental` and Appian's `appian` skill are installed under `~/.claude/skills/` on Scott's machine.

**Rulings needed.**
- The repo as the master copy of the demo documents, with the Project's copies overwritten from it and the replication guide removed from the Project.
- Whether this build stays in its own repo for now.
- Phase 11, two proposals from the planning chat: Ready also requires each story to sit in its scripted queue; the Ready line names who loaded the demo.
- Phase 12: the duplicate-record-type approach and the three platform modes.
- The phase that follows Phase 11.

**Promotion candidates.** None found.

**TODO changes:** closed as superseded: the first Kiro session, and pasting the Kiro version of the Project instructions. Added under Before demo: confirm `CLAUDE.md` loads the rules in Claude Code. Unchanged: make the repository private.

**BUILD_PLAN.md changes:** the plan section and Phases 10, 11 and 12 added; Phases 7, 8 and 9 marked on hold; one Phase 10 item ticked (the `CLAUDE.md` loader and the local and GitHub copies brought level).

**Credits.** Not applicable. This close-out was written from the claude.ai Project, not from a Kiro or Claude Code session.
