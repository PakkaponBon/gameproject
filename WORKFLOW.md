# WORKFLOW.md — How to run this project with Claude Code

Read this yourself; Claude Code doesn't need it but can.

## File layout (project root, next to project.godot)
```
ashfall/
├── project.godot
├── CLAUDE.md          ← Claude Code auto-reads this every session
├── ROADMAP.md         ← what to build now (source of truth)
├── GAME_DESIGN.md     ← what the game IS
├── ART_DIRECTION.md   ← art rules (binding from Phase 10)
├── IDEAS.md           ← scope parking lot
├── WORKFLOW.md        ← this file
├── scenes/
├── scripts/
└── assets/
```

## Who owns which file
| File | Updated by | When |
|---|---|---|
| CLAUDE.md | You (rarely) | Stack/rule changes only |
| ROADMAP.md | Claude Code (checkboxes), you (scope changes) | Every finished item |
| GAME_DESIGN.md | You | Design decisions change |
| ART_DIRECTION.md | You | Art decisions change |
| IDEAS.md | Claude Code appends, you triage | Whenever scope creep appears |

## The session loop (repeat until v1.0)
1. **Open Claude Code in the project folder**
2. **Start:** `Read CLAUDE.md and ROADMAP.md. What's the next unchecked item? Propose a plan before coding.`
3. **Approve or adjust the plan**, then let it build ONE item
4. **Test in Godot (F5)** following its test script
   - Works → `Works. Check it off in ROADMAP.md and give me the commit message.` → commit in git
   - Broken → paste the exact error from Godot's Output panel, or describe what you see vs expected
5. **End of phase:** `Phase DoD: <paste DoD>. Verify each item against the code and tell me what to test to prove it.` → test → `git tag v0.X-name`
6. New session? Go to step 2 — the .md files are the memory, so context is never lost.

## Prompts that work well
- Start feature: `Next item in ROADMAP.md Phase N. Plan first, then build.`
- Bug: `Bug: <what happened>. Expected: <what should happen>. Error: <paste>. Find root cause before patching.`
- Review: `Review scripts/jobs/ against the architecture rules in CLAUDE.md. List violations, don't fix yet.`
- Refactor: `JobManager is over 200 lines. Propose a split per CLAUDE.md code style.`
- Scope creep (yours): `Add to IDEAS.md: <idea>. Then continue current item.`

## Git habits (minimum viable)
```
git init                          # once
git add -A && git commit -m "..."  # every working item
git tag v0.X-phasename             # every finished phase
```
If a session goes sideways: `git checkout .` erases uncommitted damage. This is why you commit per item, not per day.

## Rules for YOU (the scope demon is you, not Claude)
1. Never start a phase before the previous DoD passes
2. Never skip Phase 1 (saves) or Phase 8 (playtest)
3. New feature idea mid-phase → IDEAS.md, not code
4. If stuck on one bug for 2+ sessions: `Stop patching. List 3 hypotheses for the root cause and how to test each.`
5. Ship at v1.0 even if imperfect. Shipped-and-modest beats perfect-and-dead.
