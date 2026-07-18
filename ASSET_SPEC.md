# ASSET_SPEC.md — Production Brief for the Asset Agent

> The single authority on what every atlas cell means and how new art gets
> in. Workflow: drop PNGs in `assets/incoming/` → run
> `tools/import_assets.ps1` → commit per AGENTS.md.

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

## sprites.png — 50 cells (0–27 items; 28–43 animation frames; 44–49 map markers)
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

## Priorities (highest value first)
1. The "wanted" replacements above marked *programmer art* (rocks, grave, stone chunk).
2. Building reads: bed, barn, watchtower, hearth.
3. Food icon that reads as food at 16px.
4. AFTER a code-hook request: villager variants, distinct sheep/boar/wolf,
   door open/close frames, work-swing frames, 32×32 portraits.

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
