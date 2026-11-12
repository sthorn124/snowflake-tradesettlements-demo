# CLAUDE.md

Settlement Operations demo (Appian + Snowflake). This file makes the repo usable from Claude Code.

The operating rules live in `.kiro/steering/` and are loaded by the lines below. They are the only copy of the rules. Do not paste rule text into this file. To change a rule, edit the steering file: the `core-*` files are template-owned, and `project.md` belongs to this build.

@.kiro/steering/core-00-preamble.md
@.kiro/steering/core-01-grounding-preflight.md
@.kiro/steering/core-02-observation-verification.md
@.kiro/steering/core-03-docs-search.md
@.kiro/steering/core-04-identity.md
@.kiro/steering/core-05-records-closeout.md
@.kiro/steering/core-06-regression-writes.md
@.kiro/steering/project.md

## Reading these rules in Claude Code

The rules were written for the Kiro IDE. In a Claude Code session:

- "The Kiro session" means this session.
- Dev MCP tools appear as `mcp__appian__<tool>`. The steering files write them in Kiro's forms (`project.md`, the section that applies core §6 to this build).
- The reference files do not load by themselves here. Read the one that applies before relying on it: `reference/toolchain.md`, `reference/mcp-capability-boundaries.md`, `reference/silent-failure-taxonomy.md`, `reference/patterns.md`, `reference/model-output-verification.md`.
- Skills are under `~/.claude/skills/` in Claude Code, not `~/.kiro/skills/`. Core §1 step 3 still applies: load `appian-supplemental`, then Appian's `appian` skill, before any Appian object work. If `appian-supplemental` is not installed there, read the repo copy at `skills/appian-supplemental/SKILL.md` and say so. At session start, compare the installed copy's version line with the repo copy and report any difference (core §2 step 6).
- The on-request procedures are files to read when asked for: `.kiro/steering/dev-mcp-update.md` and `.kiro/steering/generate-project-instructions.md`. `.kiro/steering/kiro-first-session.md` applies to Kiro only.

## What Kiro enforces and Claude Code does not

Kiro's hooks and permission file do not run under Claude Code. Nothing holds the rules below except the session itself.

1. **Session start.** Run `python3 .kiro/scripts/preflight.py` and read its report before any other work. Under Claude Code this is the normal path, so do not log it as a hook failure. Its lines about `~/.kiro` (MCP config, permissions file, skills) describe the Kiro setup on this machine, not this session. Then run the steps of core §2 marked `[agent]` yourself.
2. **Plan gate.** No Dev MCP write while `BUILD_PLAN.md` is the template stub (core §2 step 1).
3. **Runtime server.** Never call an `appian_`-prefixed tool or `ping` (core §6 and the binding rule in `project.md`). No permission file blocks them here.
4. **Deletes.** Kiro denies the Dev MCP's delete and remove tools by default (core §6). Nothing denies them here. When a session needs one, stop, name the objects, and ask Scott. Proceed only on his yes for those objects. Never retry a refused delete another way.
5. **Close-out.** Run the full close-out of core §10 at the end of every session, and verify the push by `HEAD` equal to `origin/main`. No hook re-checks it.
6. **Credits.** Skip the `credits.py` step of core §10 step 1, and say in `Closeout.md` that the session ran in Claude Code. `CREDITS.md` is built from Kiro's own records.
