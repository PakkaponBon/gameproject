# CLAUDE.md — Colony Sim (Godot 4)

## Project overview
A 2D pixel-art colony simulation game in the style of RimWorld, built solo as a first indie project. Core loop: pawns (colonists) autonomously pull jobs from a task queue — chop trees, haul resources, eat when hungry — while the player places buildings and zones.

## Tech stack
- **Engine:** Godot 4.x (standard build, NOT .NET/Mono)
- **Language:** GDScript only. Never suggest C# or C++.
- **Rendering:** 2D, pixel art. Project settings use `canvas_items` stretch mode and nearest-neighbor texture filtering.
- **Pathfinding:** Godot's built-in `AStarGrid2D`. Do not write custom A* unless AStarGrid2D provably cannot do the job.
- **Version control:** Git. Commit after each working milestone.

## How to run / test
- I run the game manually by pressing F5 in the Godot editor. You cannot run or see the game.
- After making changes, tell me exactly what to test and what I should see on screen.
- If something breaks, I will paste errors from Godot's Output/Debugger panel.

## Architecture rules
- **World is a tile grid.** All positions are grid coordinates (Vector2i). Convert to pixel coordinates only for rendering.
- **Fixed simulation tick.** Game logic runs on a tick timer (start with 10 ticks/sec), decoupled from the render framerate. Never put game logic in `_process` — use the tick.
- **Job system is the core.** Global `JobManager` (autoload singleton) holds a list of available jobs. Pawns request the nearest reachable job, reserve it (no two pawns take the same job), execute it, then request again.
- **Scenes:** one scene per entity type (Pawn, Tree, Stockpile). Keep the main World scene thin — it composes, it doesn't contain logic.
- **Autoload singletons** for global state only: `JobManager`, `WorldGrid`, `GameClock`. Everything else is scene-local.
- **Signals over polling.** Entities emit signals (e.g. `job_completed`, `hunger_critical`); managers listen.

## Code style
- GDScript with static typing everywhere: `var hp: int = 10`, typed function signatures.
- snake_case for variables/functions, PascalCase for classes/scenes, SCREAMING_SNAKE for constants.
- Small files. If a script passes ~200 lines, propose splitting it.
- Comment the *why*, not the *what*. No obvious comments.

## Assets
- Placeholder-first. Use ColorRect / colored 16x16 squares or Kenney.nl CC0 packs.
- Do not spend effort on art, juice, or polish until the simulation works.
- Tile size: 16x16 pixels.

## Milestones (build in order, one at a time)
1. **World:** TileMapLayer with grass/dirt, camera WASD pan + scroll zoom, left-click places walls
2. **Pawn:** one pawn, click-to-move using AStarGrid2D, walls block pathing
3. **Jobs v0:** trees on the map; pawn auto-finds nearest tree, chops it (timed), wood item drops
4. **Hauling:** stockpile zone the player can paint; pawn carries wood to stockpile
5. **Needs:** hunger stat that drains; pawn seeks food when low, dies at zero
6. **Multiple pawns:** 3+ pawns sharing the job queue with reservations, work priorities per pawn
7. **Content:** more job types, mood, a raid event — only after 1–6 are solid

## Working rules for Claude Code
- Work on ONE milestone at a time. Do not scaffold future milestones early.
- Prefer the simplest working version first; refactor when a milestone demands it.
- When a milestone is done: summarize what changed, list files touched, tell me what to test in-editor, and suggest a git commit message.
- Never add third-party addons/plugins without asking me first.
- If Godot 4 API details are uncertain (APIs changed a lot from Godot 3), say so instead of guessing — Godot 3 answers are a common failure mode.
