# ART_DIRECTION.md — Ashfall

Binding from Phase 10. Before that: colored squares / Kenney CC0 only.

## Identity in one line
Warm hand-built village against a dark fantasy wild — Stardew proportions, RimWorld animation budget, hearth-vs-wild contrast doing the storytelling.

## The core visual idea: HEARTH vs WILD
Two sub-palettes from one master palette:
- **Village (hearth):** warm — honey wood, cream, terracotta, hearth-orange light
- **Wilds/enemies/ruins (wild):** cool & desaturated — moss, slate, cold blue-greens, ash grey
The player should *feel* the border of their walls. Torches/windows glow warm at night while the wild goes blue-black.

## Palette
- Master: **AAP-64** (lospec.com/palette-list/aap-64) — it has both warm and cold ranges; cull to ~32 working colors split into the two sub-palettes
- No pure black (darkest = ash brown-grey), no pure white
- Outlines: dark warm brown inside the village, dark cold grey for wild things — subtle, consistent
- Season tints via modulate: spring green, summer gold, autumn amber, winter blue-white

## Sizes & grid
- Tile: **16x16**
- Villager/enemy: **16x24** (Stardew-ish, head ≈ 40%)
- Gear overlays: sword/bow/staff drawn as separate 16x24 overlay sprites so any villager can equip anything — never bake weapons into body sprites
- Buildings: whole-tile footprint, may overdraw upward
- Portraits: 24x24 bust; World map: single 320x180-ish illustrated screen + faction crest icons (16x16)

## Animation budget (hard cap)
| Thing | Frames |
|---|---|
| Villager walk / work | 2 / 2 |
| Attack (melee/bow) | 2 (windup, strike) |
| Enemies (3–4 types) | 2 walk, 2 attack |
| Idle | 1 |
| Crops | 1 per stage, no sway |
| Spell effects | 3–4 frame bursts, palette-tinted per relic (one effect base, recolored) |
| Hit feedback | white-flash + knockback wobble, 2-frame puff |
Beyond this table → IDEAS.md.

## Shape language
- Village: rounded, hand-made — timber frames, thatch, stone bases, hanging lanterns
- Wild/ruins: jagged edges, broken silhouettes, overgrowth
- Enemies readable at a glance by silhouette (bandit = hood, tribal = antlers, etc.)

## Mood & light
- Day warm modulate → dusk orange → night blue-purple; village light sources punch warm holes in night
- Particles: leaves/snow/pollen (seasonal), embers near forge, drifting ash near ruins
- Combat feedback: flashes, stars, puffs. **No blood, ever.** Death = fall + fade + small grave
- Intro event: 2–3 still images, silhouette/ember style — city burning shown as distant glow, not violence

## Tools & sources
- Aseprite (~$20) or LibreSprite (free)
- Palettes/tutorials: lospec.com; structure reference: Kenney packs
- SFX: jsfxr (UI/hits), freesound.org CC0/CC-BY (nature, fire); spells need distinct per-relic sounds
- Music: 3 loops — village day, raid, world map. Commission cheap or CC-BY with credit

## Production order (Phase 10)
1. Ground tileset + trees, both sub-palettes (biggest transformation first)
2. Villager base + gear overlay set (sword/bow/staff)
3. Enemy types
4. Buildings (village warm-set), ruins
5. Crops, items, icons
6. Portraits, world map screen, UI skin
7. Spell/hit effects, particles, audio last
