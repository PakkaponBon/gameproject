# CLAUDE.md — Ashfall: Fantasy Colony Sim (Godot 4)

> Read this at the start of every session. Check ROADMAP.md for the current phase before writing any code.

## Project overview
**Working title:** Ashfall *(placeholder — rename anytime)*
2D pixel-art **dark-origin fantasy colony sim**: the player's home city was destroyed, survivors rebuild a village, arm it (swords → bows → rare magic), and resolve 5 surrounding factions by alliance or conquest until they rule the realm. RimWorld-style autonomous jobs + a faction/world-map arc.

**Tone rule:** warm hearth, dark world. Combat and death exist; gore does not. The origin tragedy is told, never shown.

## Tech stack
- **Engine:** Godot 4.x (standard build, NOT .NET/Mono)
- **Language:** GDScript only, static typing everywhere. Never suggest C# or C++.
- **Pathfinding:** built-in `AStarGrid2D` only
- **Version control:** Git; commit per working item, tag per phase

## How to run / test
- I run with F5 in the Godot editor; you cannot run or see the game.
- After changes: tell me exactly what to test and what I should see.
- I paste errors from Godot's Output/Debugger panel.

## Architecture rules
- **Tile grid world**, `Vector2i` logic coords, pixels only for rendering. Tile = 16x16.
- **Fixed sim tick** (10/sec) decoupled from framerate; no game logic in `_process`.
- **Job system is the core:** autoload `JobManager`, reservation-based, villagers pull nearest reachable job.
- **Autoloads only:** `JobManager`, `WorldGrid`, `GameClock`, `SaveManager`, `EventBus`, `FactionManager` (Phase 6+). Everything else scene-local.
- **Signals over polling** via `EventBus`.
- **Data over code:** crops, weapons, relics, traits, factions, events are ALL resources/dictionaries — adding one must never require a new script.
- **Every new system ships with save/load.** No exceptions after Phase 1.
- Combat model stays light: HP/damage/armor numbers. No hit locations, no organ sim.
- World map is UI + data + events — never a second simulated tilemap.

## Code style
- snake_case vars/functions, PascalCase classes/scenes, SCREAMING_SNAKE constants
- Files over ~200 lines: propose a split
- Comment the *why*, not the *what*

## Assets
- Placeholder-first: colored squares / Kenney CC0 until Phase 10
- From Phase 10: ART_DIRECTION.md is binding (palette, sizes, animation budget)

## Related docs (project root)
| File | Purpose |
|---|---|
| ROADMAP.md | 11 phases to v1.0, checklists, DoD gates — source of truth for *what to build now* |
| GAME_DESIGN.md | What the game IS — loops, weapon tiers, factions, tone. Consult before designing features |
| VISION.md | The FULL game (post-1.0): acts, endings, update ladder v1.1→v2.0. Never code from it directly — slice into mini-roadmaps |
| ART_DIRECTION.md | Palette, sprite specs, animation caps |
| IDEAS.md | Scope parking lot — cool-but-not-now goes here, never into code |
| PROMPTS.md / WORKFLOW.md | Bo's manuals — how he drives you |

## Working rules for Claude Code
1. One phase at a time; one checklist item at a time. No early scaffolding.
2. Simplest working version first; refactor when the phase demands it.
3. Item done → summarize changes, files touched, in-editor test script, commit message, and check it off in ROADMAP.md.
4. Requests outside the current phase → append to IDEAS.md and say so; don't build.
5. No third-party addons without asking.
6. Godot 4 API uncertainty → say so, don't guess (Godot 3 answers are a known failure mode).
7. Tone check: content violating "no gore / tragedy told not shown" → flag against GAME_DESIGN.md.
8. Balance changes are data changes: if tuning requires code edits, the data model is wrong — flag it.
