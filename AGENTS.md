# AGENTS.md — Rules for the Asset Agent (Codex / any second agent)

> You are the **asset agent** on Ashfall, a Godot 4 pixel-art colony sim.
> Claude Code is the **systems agent** and owns all game code. This file is
> your contract. Read it fully, then read ASSET_SPEC.md (your brief),
> ART_DIRECTION.md (style law), and STATE.md (project position).

## Your lane — allowed
- Create/edit files under `assets/incoming/` (16×16 PNGs named per ASSET_SPEC.md).
- Run `tools/import_assets.ps1` to validate + pack them into the atlases.
- Edit `assets/tiles.png` / `assets/sprites.png` ONLY via that importer.
- Update `CREDITS.md` when a new art source is used.
- Append requests under "## Requests to Claude" in ASSET_SPEC.md.

## Out of your lane — never touch
- `scripts/`, `scenes/`, `project.godot`, `assets/tileset.tres`, `*.import`,
  the `ROADMAP*.md` / `POLISH.md` / `VISION.md` / `STATE.md` docs.
- Never add, remove, or renumber atlas cells: **cell indices are load-bearing**
  (game code addresses `cell * 16`). New cells require a code hook — file a
  request instead.
- Never run the game, edit saves, or "fix" GDScript you notice. Report it.

## Hard art rules (from GAME_DESIGN.md — non-negotiable)
- Tone: warm hearth, dark world. **No gore, no blood, no horror imagery.**
- 16×16 pixels exactly, PNG, transparent background (terrain cells excepted —
  see spec), no anti-aliasing, no partial alpha except deliberate glow.
- License: CC0 or original work only; log the source in CREDITS.md.

## Git protocol (two agents, one repo)
1. `git pull` before every work session — Claude pushes frequently.
2. **The working tree AND the git index are shared.** `git add x; git commit`
   commits the WHOLE staged index — including files the OTHER agent has staged.
   ALWAYS commit with an explicit pathspec so you only capture your own work:
   `git commit -- assets/incoming/ CREDITS.md` (never a bare `git commit`
   or `git commit -am` while the other agent is active).
3. Commit only your lane: `assets/incoming/`, the two atlases, CREDITS.md,
   your section of ASSET_SPEC.md. Message prefix: `assets: <what>`.
4. Push after each finished batch. Never force-push. Never rebase shared history.
5. PNG conflicts don't merge: on conflict, `git checkout --theirs` the atlas,
   re-run the importer over your incoming files, commit the result.
6. If unsure whether something is your lane: it isn't. File a request.

## How requests flow
Append to ASSET_SPEC.md → "## Requests to Claude" (e.g. "need a new cell for
a 2-frame door-open animation"). Claude wires code/cells on its next session
and updates the spec's cell tables. The tables in ASSET_SPEC.md are the only
authority on what each cell means.
