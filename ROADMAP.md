# ROADMAP.md — Colony Sim: Skeleton → v1.0

Current state: **v0.1-skeleton** (milestones 1–7 done: world, pawn pathfinding, jobs, hauling, needs, multi-pawn priorities, basic content).

Rules: one phase at a time, in order. Each phase has a **Definition of Done (DoD)** — do not start the next phase until DoD passes. Git tag at the end of every phase. Every new system from Phase 1 onward MUST include its save data.

---

## Phase 1 — Persistence (v0.2)
The foundation everything else depends on. Do this before any new content.

- [ ] Save system: serialize world grid, tiles, pawns (position, needs, inventory, priorities), items, jobs, stockpiles, game clock
- [ ] Load system: fully restore a session mid-job without desync
- [ ] Autosave every N in-game minutes + manual save/load from a menu
- [ ] Save file versioning (a `version` field so old saves can migrate later)

**DoD:** Save mid-chop with a pawn carrying wood → quit → load → everything resumes correctly.
**Tag:** `v0.2-persistence`

---

## Phase 2 — Construction (v0.3)
Shift from "player does things" to "player orders things" — the core colony-sim feel.

- [ ] Blueprint placement: ghost tile that needs resources, not instant build
- [ ] Haul-to-blueprint job: pawn delivers required wood to the site
- [ ] Build job: pawn constructs over time (progress bar), then blueprint becomes real
- [ ] Buildings: wall, door (pawns path through, blocks enemies later), bed
- [ ] Deconstruct order (refund partial resources)

**DoD:** Order a 5-wall room with a door and a bed; pawns haul + build it with zero player micromanagement.
**Tag:** `v0.3-construction`

---

## Phase 3 — Survival Loop (v0.4)
Make failure possible. Colony must be sustainable — or collapse.

- [ ] Day/night cycle on the game clock
- [ ] Rest need: drains while working, pawn seeks bed at night, sleep restores; exhausted pawns work slower
- [ ] Food chain: farm plot → plant job → growth ticks → harvest job → food item → eat job
- [ ] Starvation: hunger at zero = health drain = death
- [ ] Pawn death handled cleanly (jobs released, corpse item, no crashes)

**DoD:** A 3-pawn colony can run 5 in-game days hands-off without dying; cutting off food kills it.
**Tag:** `v0.4-survival`

---

## Phase 4 — Threat & Combat (v0.5)
Tension. Without threat, it's a screensaver.

- [ ] Health/combat stats on pawns (HP, melee damage, attack speed)
- [ ] Enemy entity: spawns at map edge, pathfinds toward colony, attacks pawns/doors
- [ ] Draft mode: player takes direct control of a pawn (move/attack orders), like RimWorld drafting
- [ ] Raid event: timed or wealth-scaled enemy spawn
- [ ] Walls/doors actually defend (enemies must path through or break doors)
- [ ] Injured state: low-HP pawns move/work slower, rest to recover

**DoD:** Survive a 3-enemy raid using walls, a door choke point, and 2 drafted pawns.
**Tag:** `v0.5-threat`

---

## Phase 5 — UI & Game Feel (v0.6)
Make it playable by someone who isn't you.

- [ ] Pawn panel: needs bars, current job, health, work priority row
- [ ] Work priority grid screen (pawns × job types)
- [ ] Resource counters (wood, food) always visible
- [ ] Speed controls: pause / 1x / 3x, spacebar = pause
- [ ] Placement previews, invalid-placement feedback, selection highlights
- [ ] Notifications feed: "Pawn is starving", "Raid incoming"
- [ ] Main menu: new game / load / quit

**DoD:** A friend can play 20 minutes without asking you how anything works.
**Tag:** `v0.6-playable`

---

## Phase 6 — External Playtest (v0.7)
- [ ] Export a Windows build, send to 3–5 friends
- [ ] Watch at least 2 people play live; say nothing, take notes
- [ ] Fix the top confusion points and top crashes ONLY (no new features)
- [ ] Repeat once

**DoD:** New player reaches day 3 and survives one raid without help.
**Tag:** `v0.7-playtested`

---

## Phase 7 — Content Depth (v0.8)
Now — and only now — widen the game. Pick a scope you can finish in weeks, not months.

- [ ] Second resource chain (e.g. stone → mining job → stone walls/furniture)
- [ ] Cooking: raw food → stove → meals (better hunger restore)
- [ ] Mood system: simple happiness from food quality, sleep, deaths; low mood = work slowdown or tantrum
- [ ] 2–3 more events (animal attack, resource windfall, cold snap)
- [ ] Pawn variety: names, portraits, 1–2 traits affecting stats
- [ ] Basic tech/unlock progression OR map biome variety (choose ONE)

**DoD:** Two consecutive playthroughs feel meaningfully different.
**Tag:** `v0.8-content`

---

## Phase 8 — Art & Audio Pass (v0.9)
Placeholder era ends here.

- [ ] Final tileset + sprites (16x16, consistent palette — pick one from lospec.com)
- [ ] Pawn animations: idle, walk, work (2–4 frames each is enough)
- [ ] SFX: chop, build, eat, combat hits, UI clicks (freesound.org / jsfxr)
- [ ] 1–2 music loops (calm + raid)
- [ ] Screen polish: title screen, day/night tinting, minimal particles (wood chips, blood)

**DoD:** A screenshot looks like a real indie game, not a prototype.
**Tag:** `v0.9-polish`

---

## Phase 9 — Release (v1.0)
- [ ] Difficulty balancing pass (easy/normal at minimum)
- [ ] Settings menu: volume, resolution/fullscreen, keybinds
- [ ] Crash-proofing: play 3 full sessions, fix every error in the log
- [ ] Export templates: Windows (+ Linux is nearly free in Godot)
- [ ] itch.io page: 5 screenshots, a 30–60s GIF/trailer, short description
- [ ] Launch on itch.io (free or pay-what-you-want for a first game)
- [ ] Post-launch: fix critical bugs for 2 weeks, then DECIDE — grow this game or bank the experience and start the next one

**DoD:** A stranger downloads it, plays it, and it doesn't crash.
**Tag:** `v1.0`

---

## Scope guardrails (read when tempted)
- No multiplayer. No mod support. No infinite maps. No z-levels. Not in 1.0.
- If a feature isn't required by a DoD, it goes in `IDEAS.md`, not the code.
- RimWorld had ~5 years of updates after its first public build. Your 1.0 is *their* alpha — that's correct.
