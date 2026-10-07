---
inclusion: manual
---

# Generate PROJECT_INSTRUCTIONS.md

When the operator says "generate PROJECT_INSTRUCTIONS.md": fill the block in `GETTING_STARTED.md` §2 from this build's own files and write `PROJECT_INSTRUCTIONS.md` at the repo root, holding the filled block in a fenced text block. Fill `[REPO URL]` from `git remote get-url origin`. Fill BUILD CONTEXT fields only from tracked files; leave any field the files cannot settle blank and list the blanks for the operator. Never write a real client name: write `[type the client name in the Project only]` in its place. When `BUILD_PLAN.md` is still the stub, generate the thin first version (`GETTING_STARTED.md` §1, step o).

#[[file:GETTING_STARTED.md]]
