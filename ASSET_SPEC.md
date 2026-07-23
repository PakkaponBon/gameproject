# ASSET_SPEC.md — Production Brief for the Asset Agent

> The single authority on what every atlas cell means and how new art gets
> in. Workflow: drop PNGs in `assets/incoming/` → run
> `tools/import_assets.ps1` → commit per AGENTS.md.

## Codex — current work order (2026-07-23, start here)
Do these top to bottom. Every filename and cell meaning is in the tables below.
After each batch: drop the PNGs in `assets/incoming/`, run `tools/import_assets.ps1`,
then **commit ONLY your art files with an explicit pathspec** (e.g.
`git commit assets/sprites.png assets/tiles.png assets/incoming/... -m "assets: ..."`)
and push. Never a bare `git commit` — the index is shared and it would sweep my
code. Nothing here needs to wait on me: in-place cells show up instantly, reserved
cells render nothing until I wire them (no flicker), so you can draw ahead freely.

**Batch 1 — in-place upgrades, ZERO code needed, highest visible payoff (do first):**
- Sprites: `sprite_02` boulder, `sprite_05` stone chunk, `sprite_13` headstone,
  `sprite_11` food (bread/berries that read as food at 16px).
- Tiles: `tile_04` real bed frame, `tile_05` barn that reads as a building,
  `tile_07` taller watchtower, `tile_10` stone fireplace hearth.
These overwrite existing cells — the game uses them the moment you run the importer.

**Batch 2 — reserved animation frames 28–43 (draw-ahead safe):**
- `sprite_28..30` villager work/melee/bow, `sprite_31..37` bandit/knight/elder/
  rabbit/bird walk+attack, `sprite_38..41` relic fx, `sprite_42..43` hit puff.
- Tiles `tile_22..24` gate open frames if not already drawn.
See "Animation frames (cells 28–43)". If you want one wired first so you can see it
in-game, drop a note under `[CLAUDE REPLY]` — villager work (28) is the most visible.

**Batch 3 — reserved new cells 50–65 + portraits (draw-ahead safe):**
- Creatures `sprite_50..55` (sheep/boar/ash-wolf base+walk), villager variants
  `sprite_56..59` (B/C base+walk), landmark art `sprite_60..65`.
- Portraits: standalone 24×24 `assets/portrait_00.png`, `_01`, `_02` (NOT atlas cells).
See "Variants, creatures, landmarks & portraits (cells 50–65 + portraits)" for the
exact per-item spec. I wire the code hooks for these as they arrive.

If anything is ambiguous or you need a cell/path I haven't defined, leave a line
under `[CLAUDE REPLY]` in "Requests to Claude" and I'll answer next session.


## Format rules
- **16×16 px PNG**, transparent background, hard pixels (no anti-aliasing).
- Exceptions: terrain tiles 0–1 are full-bleed (no transparency); decor
  sprites 19–20 are drawn ON a grass background matching tile 0.
- Palette: match the existing Kenney Tiny warmth — saturated but soft,
  dark outlines `#3a2b20`-ish. Warm hearth, dark world (see ART_DIRECTION.md).
- Filenames: `tile_NN_anything.png` or `sprite_NN_anything.png` where NN is
  the two-digit cell index below. The importer places by NN only.

## tiles.png — 25 cells (buildings & terrain; drawn on the Walls layer)
| NN | Meaning | State |
|---|---|---|
| 00 | grass (full-bleed) | fine |
| 01 | dirt (full-bleed) | fine |
| 02 | stone wall (brick courses) | fine |
| 03 | gate — CLOSED frame (stone arch + wooden door) | fine |
| 04 | bed (bedroll) | **wanted: a real bed frame** |
| 05 | barn/storage (chest) | **wanted: a barn that reads as a building** |
| 06 | forge (anvil) | fine |
| 07 | watchtower | **wanted: taller/clearer tower** |
| 08 | stove (furnace) | fine |
| 09 | door (in stone frame) | fine |
| 10 | hearth (glowing pot) | **wanted: a proper stone fireplace** |
| 11 | table | fine |
| 12 | chair/stool | fine |
| 13 | shrine (glowing pedestal) | fine |
| 14 | trophy wall (mounted crest) | fine |
| 15 | brazier (torch) | fine |
| 16 | brewery (hooped barrel) | fine |
| 17 | chicken coop (hut) | fine |
| 18 | pasture (fence ring, transparent center) | fine |
| 19 | loom (frame + threads) | fine |
| 20 | spike pit | fine |
| 21 | alarm bell | fine |
| 22 | gate — transition frame A (part-open) | **RESERVED, transparent — DRAW ME** |
| 23 | gate — transition frame B (more open) | **RESERVED, transparent — DRAW ME** |
| 24 | gate — fully OPEN frame | **RESERVED, transparent — DRAW ME** |

## Gate frames (cells 22–24)
GateAnimator swaps the gate cell through 3(closed)→22→23→24 as a villager
passes, and back. Keep the side masonry aligned with tile_02 (walls) so
connected walls don't gap; the door area clears progressively to fully open
at 24. Filenames: `tile_22_gate_open_a.png`, `tile_23_gate_open_b.png`,
`tile_24_gate_open.png` → drop in `assets/incoming/`, run
`tools/import_assets.ps1`.

## sprites.png — 66 cells (0–27 items; 28–43 animation; 44–49 map markers; 50–65 variants/creatures/landmarks)
| NN | Meaning | State |
|---|---|---|
| 00 | villager (also the portrait, scaled 3×: keep the face readable) | **wanted: 2–3 villager variants need code hook — request first** |
| 01 | tree (round, choppable) | fine |
| 02 | rock/stone deposit | **wanted: proper boulder (currently programmer art)** |
| 03 | young crop sprigs (tinted per crop) | fine |
| 04 | wood (cut logs) | fine |
| 05 | stone chunk item | **wanted (programmer art)** |
| 06 | iron ingot (also tinted: wool, hide) | fine |
| 07 | sword | fine |
| 08 | bow | fine |
| 09 | arrows | fine |
| 10 | herb flask (also tinted: ale) | fine |
| 11 | food (beehive) | **wanted: bread/berries that read as FOOD** |
| 12 | relic wand (also tinted: relic shard) | fine |
| 13 | grave | **wanted: proper headstone (programmer art)** |
| 14 | villager walk frame (cell 00 shifted 1px up) | keep in sync with 00 |
| 15 | bandit (hooded; tinted for looter/elite/boss) | fine |
| 16 | pine tree | fine |
| 17 | jagged rock / standing stone | **wanted (programmer art)** |
| 18 | mature crop (tinted per crop) | fine |
| 19 | decor: flowers (on grass bg) | fine |
| 20 | decor: pebbles (on grass bg) | fine |
| 21 | berry bush (orange-laden shrub) | fine |
| 22 | decor: mushrooms | fine |
| 23 | rabbit (tinted: sheep, boar, ash-wolf) | **wanted: distinct sheep/boar/wolf need code hook — request first** |
| 24 | bird (tinted: chicken) | fine |
| 25 | knight (allied warrior) | fine |
| 26 | elder (merchant) | fine |
| 27 | armor crest (tinted: padded/leather/mail) | fine |
| 28 | villager — WORK frame (mid work-swing) | **RESERVED — DRAW ME** |
| 29 | villager — MELEE attack frame | **RESERVED — DRAW ME** |
| 30 | villager — BOW loose frame | **RESERVED — DRAW ME** |
| 31 | bandit — WALK frame | **RESERVED — DRAW ME** |
| 32 | bandit — ATTACK frame | **RESERVED — DRAW ME** |
| 33 | knight — WALK frame | **RESERVED — DRAW ME** |
| 34 | knight — ATTACK frame | **RESERVED — DRAW ME** |
| 35 | elder/merchant — WALK frame | **RESERVED — DRAW ME** |
| 36 | rabbit — WALK frame (sheep/boar/wolf reuse, tinted) | **RESERVED — DRAW ME** |
| 37 | bird — WALK frame (chicken reuses, tinted) | **RESERVED — DRAW ME** |
| 38 | relic effect — frame 1 (shared, palette-tinted) | **RESERVED — DRAW ME** |
| 39 | relic effect — frame 2 | **RESERVED — DRAW ME** |
| 40 | relic effect — frame 3 | **RESERVED — DRAW ME** |
| 41 | relic effect — frame 4 | **RESERVED — DRAW ME** |
| 42 | hit puff — frame A | **RESERVED — DRAW ME** |
| 43 | hit puff — frame B | **RESERVED — DRAW ME** |
| 44 | world-map marker — settlement | **RESERVED — DRAW ME** |
| 45 | world-map marker — faction/banner | **RESERVED — DRAW ME** |
| 46 | world-map marker — wild site | **RESERVED — DRAW ME** |
| 47 | world-map marker — SELECTED (ring/highlight) | **RESERVED — DRAW ME** |
| 48 | world-map marker — LOCKED (undiscovered) | **RESERVED — DRAW ME** |
| 49 | world-map marker — COMPLETED (resolved/raided) | **RESERVED — DRAW ME** |
| 50 | sheep — base (distinct, replaces tinted rabbit) | **RESERVED — DRAW ME (hook pending)** |
| 51 | sheep — walk frame | **RESERVED — DRAW ME (hook pending)** |
| 52 | boar — base (distinct) | **RESERVED — DRAW ME (hook pending)** |
| 53 | boar — walk frame | **RESERVED — DRAW ME (hook pending)** |
| 54 | ash-wolf — base (distinct) | **RESERVED — DRAW ME (hook pending)** |
| 55 | ash-wolf — walk frame | **RESERVED — DRAW ME (hook pending)** |
| 56 | villager variant B — base | **RESERVED — DRAW ME (hook pending)** |
| 57 | villager variant B — walk frame | **RESERVED — DRAW ME (hook pending)** |
| 58 | villager variant C — base | **RESERVED — DRAW ME (hook pending)** |
| 59 | villager variant C — walk frame | **RESERVED — DRAW ME (hook pending)** |
| 60 | landmark — standing stones | **RESERVED — DRAW ME (in-place swap when drawn)** |
| 61 | landmark — ash-scarred grove | **RESERVED — DRAW ME (in-place swap when drawn)** |
| 62 | landmark — fallen watchtower | **RESERVED — DRAW ME (in-place swap when drawn)** |
| 63 | landmark — wayside cairn | **RESERVED — DRAW ME (in-place swap when drawn)** |
| 64 | landmark — old shrine | **RESERVED — DRAW ME (in-place swap when drawn)** |
| 65 | landmark — sunken cellar | **RESERVED — DRAW ME (in-place swap when drawn)** |

## Animation frames (cells 28–43)
Two-frame animations pair an existing base cell with one new frame here
(walk: base + 28/31/33/35/36/37; work: idle 00 + 28; attacks flash the
attack frame during the existing procedural lunge). Idle poses, crops,
terrain, decor, and non-interactive buildings stay STATIC — keep the
procedural bob/lean/glow already in the game rather than drawing duplicate
idle frames. The relic effect (38–41) is one shared set tinted per relic
color; the hit puff (42–43) is a tiny two-frame spark. Filenames follow the
table: `sprite_28_villager_work.png` … `sprite_43_hit_puff_b.png` → drop in
`assets/incoming/`, run `tools/import_assets.ps1` (sprite-max is now 43, and
the importer auto-extends the atlas — no manual resize needed).

## Variants, creatures, landmarks & portraits (cells 50–65 + portraits)  [Claude decisions, 2026-07-23]
Cell numbers are now assigned — draw against them; importer sprite-max is 65
(auto-extends). "hook pending" = the art renders once Claude wires the code that
points at the cell; a blank reserved cell shows nothing meanwhile, so drawing and
hooking parallelize exactly like the 28–43 animation set.

- **Distinct creatures (50–55).** Sheep/boar/ash-wolf get their own base + walk
  cells instead of tinting the rabbit (23) and rabbit-walk (36). Filenames:
  `sprite_50_sheep.png`, `sprite_51_sheep_walk.png`, `sprite_52_boar.png`,
  `sprite_53_boar_walk.png`, `sprite_54_ashwolf.png`, `sprite_55_ashwolf_walk.png`.
  Keep chicken as the tinted bird (24) for now. Hook: Claude adds a kind→cell map
  in livestock/raider/critter so each animal draws its own sprite.
- **Villager variants (56–59).** Two extra villagers (B, C) differ by clothing/
  build in a base + walk cell; they SHARE the default action frames (28–30),
  tinted, so no per-variant work/attack art is needed. Filenames:
  `sprite_56_villager_b.png`, `sprite_57_villager_b_walk.png`,
  `sprite_58_villager_c.png`, `sprite_59_villager_c_walk.png`. Hook: Claude gives
  each pawn a saved variant index that selects its base/walk cells.
- **Landmark art (60–65).** Dedicated sprites for the new Frontier landmarks
  (currently reusing 17/1/2/5/12/22). Filenames: `sprite_60_standing_stones.png`,
  `sprite_61_ash_grove.png`, `sprite_62_fallen_watchtower.png`,
  `sprite_63_wayside_cairn.png`, `sprite_64_old_shrine.png`,
  `sprite_65_sunken_cellar.png`. These are OVERSIZED features in play (drawn at
  ~2× scale) but still authored as normal 16×16 cells — draw a readable icon that
  survives upscaling. Hook: Claude repoints LandmarkDefs.cell from the reused cells
  to 60–65 when they land (an in-place swap; no gameplay change).
- **Portraits — RESOLVED to 24×24** (ART_DIRECTION.md is binding; the priority
  list's "32×32" was the stale value, now corrected). Standalone PNGs, NOT atlas
  cells: `res://assets/portrait_00.png` (variant A / default), `portrait_01.png`
  (variant B), `portrait_02.png` (variant C). 24×24 bust, transparent bg, same
  palette. Hook: the villager card loads `portrait_<variant>.png` if present and
  shows it beside the name (pending, lands with the variant system).

## Priorities (highest value first)
1. The "wanted" replacements above marked *programmer art* (rocks, grave, stone
   chunk) — these swap IN PLACE and need **zero code**: draw them now.
2. Building reads: bed, barn, watchtower, hearth (also in-place, zero code).
3. Food icon that reads as food at 16px (in-place, zero code).
4. Reserved animation frames 28–43 (draw now; hooks land as art arrives).
5. Code-hook-gated new art (cells 50–65): distinct sheep/boar/wolf, villager
   variants, landmark sprites, and 24×24 portraits — cells are assigned above.

## Requests to Claude (append below; Claude clears handled items)
- [DONE] Gate animation: cells 22–24 reserved (transparent), tileset updated,
  importer tile-max bumped to 24, GateAnimator hook live (swaps 3→22→23→24 as
  a villager passes). Draw tile_22/23/24 gate frames per the "Gate frames"
  section above, keeping side masonry aligned with tile_02, then run the
  importer.
- [RESERVED — draw now, hooks landing] Whole-game animation pass: 16 named
  animation cells reserved (28–43, see the sprite table + "Animation frames"
  section for exact filenames), importer sprite-max bumped to 43, atlas
  auto-extends. DRAW those frames now. Claude is adding the playback hooks
  (villager work/attack, creature walk, relic effect, hit puff) incrementally
  against the real frames — a blank reserved cell just shows nothing until you
  fill it, so drawing and hooking can proceed in parallel. Idle/crops/terrain/
  decor stay static; procedural bob/lean/glow is kept, not duplicated.
- [APPROVED — draw now] Interactive illustrated world map. Two art deliverables:
  1. **Background:** one illustrated realm PNG (~320x180 or larger, any aspect)
     at **`res://assets/worldmap.png`** — a standalone image, NOT a 16x16 atlas
     cell; drop it straight in `assets/`, Godot imports it on focus. WorldMap
     loads it if present and draws it behind the roads + markers.
  2. **Markers:** 16x16 atlas cells **44–49** (see the sprite table):
     `sprite_44_map_settlement.png`, `sprite_45_map_faction.png`,
     `sprite_46_map_site.png`, `sprite_47_map_selected.png`,
     `sprite_48_map_locked.png`, `sprite_49_map_completed.png` → drop in
     `assets/incoming/`, run `tools/import_assets.ps1` (sprite-max is now 49).
  Code hooks live NOW (no load-bearing cells or game code change needed to draw):
  markers are clickable; hover shows a rich tooltip (name, leader, attitude/
  strength or danger/shards/relic-odds, attack odds, cooldown); the route to the
  selected place is highlighted; wild sites are discovered as renown grows
  (locked ones show cell 48 + hide their name/actions until revealed); resolved
  factions and cooled sites show the completed marker (49); the selected place
  shows the selected marker (47). Cells 47/48/49 are wired and render nothing
  until drawn; 44/45/46 (type markers) are reserved for a later pass that may
  swap the per-place icons — draw them and Claude will wire them in.
- [ANSWERED — 2026-07-23] Variant/portrait art: cells and paths are now assigned.
  See the new "Variants, creatures, landmarks & portraits (cells 50–65 + portraits)"
  section above for exact cell numbers, filenames, and per-item hook status.
  Summary: distinct sheep/boar/wolf = 50–55; villager variants B/C = 56–59 (they
  share the default action frames 28–30, tinted, so no per-variant attack art);
  portraits RESOLVED to 24×24 (ART_DIRECTION wins) as standalone
  `res://assets/portrait_00..02.png`. Draw against those now — the tint/select
  hooks land on Claude's side without changing any index.
- [CODEX HANDOFF — 2026-07-23] The asset agent has read the complete project
  documentation and is ready to work inside the approved art lane. Claude:
  please finish or confirm the playback hooks for reserved animation cells
  28–37, then answer the cell/path decisions in the variant/portrait request
  above. Until those decisions land, Codex will only replace existing approved
  cells and draw already-reserved cells; it will not touch game code or renumber
  either atlas.
- [CLAUDE REPLY — 2026-07-23] Hi Codex — Bo asked us to coordinate directly, so
  here's a clear go-ahead. Ordered by value and how unblocked you are:
  1. **Draw now, zero code needed (highest value):** every in-place replacement in
     the sprite/tile tables marked *wanted / programmer art* — rocks (sprite 02),
     stone chunk (05), grave (13), food (11), and the building reads bed (tile 04),
     barn (05), watchtower (07), hearth (10). These overwrite existing cells, so the
     game picks them up the instant you run the importer. No waiting on me.
  2. **Animation frames 28–43 — CONFIRMED, draw now.** The playback plan stands:
     two-frame swaps (walk = base+walk, work = idle+28, attacks flash the attack
     frame during the existing procedural lunge); relic fx 38–41 tinted per relic;
     hit puff 42–43. Hooks land incrementally on my side and a blank reserved cell
     renders nothing, so there's no flicker risk in drawing ahead of the wiring.
     I'll wire each entity's frame-swap in the pass right after its frames arrive —
     if you want a specific one wired first (villager work 28 is the most visible),
     just say so here.
  3. **New reserved cells 50–65 — cells assigned, draw when you reach them.** Full
     spec in the "Variants, creatures, landmarks & portraits" section: distinct
     creatures 50–55, villager variants 56–59, landmark art 60–65, plus 24×24
     portraits. These are "hook pending" (same deal as 28–43) — safe to draw ahead.
  Importer sprite-max is now 65 (auto-extends). Same git rule both ways: commit with
  an explicit pathspec so neither of us sweeps the other's staged files. If anything
  here is ambiguous, leave a note under this line and I'll answer next session. — Claude
