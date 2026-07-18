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

## tiles.png — 22 cells (buildings & terrain; drawn on the Walls layer)
| NN | Meaning | State |
|---|---|---|
| 00 | grass (full-bleed) | fine |
| 01 | dirt (full-bleed) | fine |
| 02 | stone wall (brick courses) | fine |
| 03 | gate (stone arch + wooden door) | fine |
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

## sprites.png — 28 cells (entities & items)
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

## Priorities (highest value first)
1. The "wanted" replacements above marked *programmer art* (rocks, grave, stone chunk).
2. Building reads: bed, barn, watchtower, hearth.
3. Food icon that reads as food at 16px.
4. AFTER a code-hook request: villager variants, distinct sheep/boar/wolf,
   door open/close frames, work-swing frames, 32×32 portraits.

## Requests to Claude (append below; Claude clears handled items)
- Gate animation: please reserve new tile-atlas cells and add the code/state hook
  for a short opening/closing animation using existing tile_03 as the closed
  frame. Two transition frames plus one fully open frame should be enough.
  Keep the gate's side masonry compatible with tile_02 so connected walls do
  not develop gaps. Once the cell table is updated, the asset agent can draw
  the approved 16x16 frames.
- Whole-game animation pass requested: please define and reserve named atlas
  cells, extend the importer limits, and add playback hooks for the complete
  ART_DIRECTION.md animation budget. Preserve sprite_00 + sprite_14 as the
  villager's two walk frames; add the two-frame villager work set and two-frame
  melee/bow attacks; add two-frame walk sets for bandit, knight, elder, rabbit,
  sheep, boar, ash-wolf, bird, and chicken plus two-frame attacks for combatants;
  add one shared palette-tinted 3-4 frame relic effect and a two-frame hit puff.
  The gate request above remains part of this pass. Keep crops, ordinary idle
  poses, terrain, decor, and non-interactive buildings static per the hard cap;
  use existing procedural bob/lean/glow where possible rather than allocating
  duplicate frames. Update the cell tables with exact filenames before the
  asset agent draws any of these 16x16 frames.
