# MODDING.md — Adding Content to Ashfall

> Ashfall is data-over-code by design: crops, buildings, weapons, relics,
> recipes, factions, wild sites, scenarios, and traits are all dictionaries
> in `scripts/*_defs.gd`. Most new content is a dictionary entry — no new
> script. This file shows exactly how, catalog by catalog.
>
> Two rules that apply to everything:
> 1. **A new *visual* means a new atlas cell**, which is the one thing that
>    needs a code hook (see "Art & the atlas" at the bottom). Reusing an
>    existing sprite/tile index needs no code at all.
> 2. **Adding fields never needs a save bump; new persisted *entities* do.**
>    Pure catalog entries (a crop, a recipe) are safe. See "Saves".

---

## Crops — `scripts/crop_defs.gd`
Add an id to `ORDER` and an entry to `DEFS`. Grows on the field, drops food
(or a resource) at maturity. `resource_output` is optional — omit it for a
food crop.
```gdscript
const ORDER := [..., "onion"]
"onion": {"name": "Onion", "grow_days": 2.0, "yield": 3, "color": Color(0.85, 0.8, 0.6)},
# a resource crop instead of food:
"flax": {"name": "Flax", "grow_days": 3.0, "yield": 2, "color": Color(0.7, 0.8, 0.9),
         "resource_output": "fiber"},   # "fiber" must exist in ResourceDefs
```
Order = the fast-thin → slow-rich ladder shown in the field palette.

## Resources / items — `scripts/resource_defs.gd`
Everything loose on the ground. `sprite` is a sprites.png cell index.
Optional flags turn an item into gear the job system auto-claims:
```gdscript
"fiber": {"name": "Fiber", "color": Color(0.8, 0.85, 0.7), "sprite": 3},
# gear flags (each makes villagers claim it off the ground):
#   "shots": 5        -> ammo (bows)
#   "relic": true     -> a relic (magic-affinity villagers)
#   "armor": 3.0      -> wearable armor (upgrade-only claim)
#   "medicine": 25.0  -> a healing herb
#   "node_color"/"node_yield" -> minable ore deposit
```

## Buildings — `scripts/building_defs.gd`
Add to `ORDER`, `DEFS`, and the `DESC` help text. `tile` is a tiles.png cell.
`block_villagers`/`block_enemies` drive the two pathing grids (that is how
gates and spike pits work). Optional behavior flags:
```gdscript
"well": {
    "name": "Well", "cost": {"stone": 3}, "refund": {"stone": 1},
    "build_ticks": 40, "tile": Vector2i(5, 0),   # reuses the barn tile
    "ghost": Color(0.5, 0.6, 0.8),
    "block_villagers": false, "block_enemies": false, "storage": false,
},
# behavior flags (mix as needed):
#   "storage": true            -> acts as a stockpile
#   "sleep_spot": true         -> a bed
#   "workstation": true        -> runs RecipeDefs recipes whose station == this id
#   "kitchen": true            -> cooks food into meals/stew
#   "warmth_radius": 4         -> heats a room (winter)
#   "comfort": 2               -> furniture (joy on breaks)
#   "light": true              -> glows at night (PointLight2D)
#   "livestock": "chicken", "livestock_count": 2   -> stocks animals when built
#   "trap_damage": 20.0, "trap_uses": 3            -> a trap (with block_villagers)
#   "alarm_radius": 10         -> rings when a raider is near
#   "range_bonus": 3           -> archers shoot farther from it
#   "renown_req": 1            -> gated until you earn renown
```

## Recipes — `scripts/recipe_defs.gd`
A workstation makes the first recipe (by `ORDER`) whose `station` matches the
building and whose `inputs` are in stock. `output` OR `output_pool` (random):
```gdscript
const ORDER := [..., "bake_bread"]
"bake_bread": {"name": "Bake Bread", "station": "stove", "inputs": {"wheat": 2},
               "output": "food", "output_count": 2, "craft_ticks": 30, "max_stock": 8},
# random output (like the shrine): "output_pool": ["relic_fireball", "relic_heal"]
```

## Weapons — `scripts/weapon_defs.gd`
An entry here PLUS a ResourceDefs entry (so it exists as an item) PLUS a
forge recipe (so it can be made). `tier`/`skill` gate who can wield it.
```gdscript
"spear": {"name": "Spear", "damage": 14.0, "tier": 1},
"crossbow": {"name": "Crossbow", "damage": 16.0, "tier": 2, "ranged": true,
             "range": 5, "kite_range": 2, "skill": "archery", "skill_min": 5},
```

## Relics — `scripts/relic_defs.gd`
Magic, never craftable — comes from bosses, sites, the shrine, merchants.
One of `damage`(+`radius`) / `heal` / `armor`(+`duration`) makes the spell:
```gdscript
const ORDER := [..., "relic_frost"]
"relic_frost": {"name": "Frost", "cooldown": 450, "range": 6, "damage": 20.0, "radius": 2},
```
Also add a ResourceDefs entry with `"relic": true`, and (optional) put it in
the shrine's `awaken_relic` `output_pool`.

## Traits — `scripts/trait_defs.gd`
`ORDER` = the random quirk pool; `BACKSTORIES` = the fall-of-Vhal scars.
Modifiers are multiplied in wherever the game reads that key:
```gdscript
"blessed": {"name": "Blessed", "work_speed_mult": 1.1, "magic": true,
            "lore": "Something watches over them. +10% work; can wield relics."},
# known keys: melee_damage_mult, ranged_damage_mult, work_speed_mult,
#             magic (bool), solitary (bool, sours bonds)
```

## Factions — `scripts/faction_defs.gd`
Five is the design number; changing count touches victory/Long-Night logic —
prefer editing the existing five. `likes` is the prized gift (+25 attitude):
```gdscript
"deepstone": {"name": "Deepstone Holds", "personality": "greedy",
    "strength": 70, "attitude": -10, "leader": "Thane Borvik",
    "quirk": "The halls are rich, cold, and thirsty.",
    "likes": "ale", "likes_count": 2},
# personality: "aggressive" | "honorable" | "greedy"
```

## Wild sites — `scripts/site_defs.gd`
Expedition targets on the world map. Add to `ORDER`, `DEFS`, AND a `PLACES`
node in `world_map.gd` (position + icon — that part is a small code edit):
```gdscript
"witchfen": {"name": "The Witchfen", "strength": 65.0, "cooldown_days": 3,
    "relic_chance": 0.15, "shards": 1, "resources": {"herb": 4},
    "report": "The fen yielded herbs and a splinter of old magic.",
    "vignette": "The fen lights led them in circles until dawn."},
```

## Scenarios — `scripts/scenario_defs.gd`
Opening variants; add to `ORDER` + `DEFS` and it appears in the menu cycle.
```gdscript
"refuge": {"name": "Refuge", "pawns": 5, "start_season": 0, "start_food": 40,
    "renown_mult": 0.75, "blurb": "Five made it out with a full cart. An easier road."},
# start_season: 0 spring, 1 summer, 2 autumn, 3 winter
```

## Balance — `scripts/balance.gd`
All tuning knobs (food, hunting, livestock, bestiary) as consts, plus the
per-difficulty multipliers as static funcs. Change numbers freely; per
CLAUDE.md, balance is always a data change, never a code change.

---

## Art & the atlas (the one code-touching part)
Sprites live in two packed PNGs addressed by **cell index × 16px**:
`assets/sprites.png` (28 cells) and `assets/tiles.png` (22 cells). Full cell
maps are in STATE.md and ASSET_SPEC.md.
- **Reusing** an existing index (a new item that looks like the ingot, a new
  building that reuses the barn tile) = zero code.
- **A NEW cell** needs: (1) the art packed in via `tools/import_assets.ps1`
  or a generator in `tools/`, (2) for a tile, a line in `assets/tileset.tres`
  (`NN:0/0 = 0`), and (3) the importer's max-index bumped. This is the one
  thing an asset-only agent must *request* rather than do (see AGENTS.md).

## Saves
`SaveManager.SAVE_VERSION` (currently 25) is checked exactly — a mismatch
refuses the save with an error, never a crash. Rule of thumb:
- Catalog entries (crop, recipe, building, trait…) — **no bump**. Existing
  saves keep working; new content just becomes available.
- A new **persisted entity** (like livestock was) or a changed field shape —
  **bump SAVE_VERSION** and read new fields with `data.get(key, default)`.

## Editing the .gd dictionaries safely (GDScript gotchas)
This project treats warnings as errors, so a bad edit fails the build:
- Don't add a typed local inferred from a dict: `var d := DEFS.get(id)` is
  Variant and will fail. Read untyped or annotate: `var d: Dictionary = ...`.
- Keep `Color(...)` / `Vector2i(...)` literal inside `const` dicts (they are
  constant expressions — fine).
- After adding a building/site that needs a new atlas cell, you cannot see it
  in-game until the cell exists — reuse an index first to test the data.
