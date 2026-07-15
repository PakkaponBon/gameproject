# ROADMAP-1.2.md — Field & Flock

> Slice of VISION.md ("v1.2 Field & Flock — deepen the economy"). Same
> rules as ROADMAP.md: one phase at a time, DoD gate, everything ships
> with save/load, tone rule always. Build order runs safest-first
> (data-only) → riskiest-last (new entities), so the game stays shippable
> at every step.

## Phase F1 — More Crops  *(data only, no new systems)* ✓
- [x] 5 → 10 crops in CropDefs: carrot, corn, pumpkin, cabbage, beans
      (all food, spread across fast/thin ↔ slow/rich). Barley + flax wait
      for their chains (F4/v1.3) so no crop yields a dead-end resource.
- [x] Each a distinct tint so a mixed field reads at a glance.
- No save bump: crops already persist by id + growth.

## Phase F2 — Cooking Variety  *(FoodItem kinds)* ✓
- [x] Stew: a heartier dish (3 raw food) the cook makes when the pantry is
      flush (≥6 raw) — fills fully, +mood, and +joy (comfort in the cold,
      ties into v1.1's joy need).
- [x] FoodItem generalized meal:bool → kind:"raw"/"meal"/"stew"; distinct
      tint per kind. Save v23 (back-compat reads old "meal" bool).
- [~] Preserves DROPPED on purpose: with no food-spoilage system a
      "keeps-through-winter" ration is meaningless, and adding spoilage
      risks reviving the food death spiral we deliberately fixed. Revisit
      only if a spoilage layer ever lands (it is a non-goal for now).

## Phase F3 — Hunting  *(reuses critters + jobs)* ✓
- [x] Rabbits are huntable game (birds stay pure ambiance): each carries a
      HUNT job; a villager runs it down and a short scuffle catches it.
      HUNT shares the CHOP (gathering) priority — no new UI.
- [x] Drops meat (raw food) with a dust puff — no gore, per tone rule.
- [x] Population topped up daily to Balance.CRITTER_TARGET, so hunting is
      renewable and never empties the meadow. Meat yield = Balance.MEAT_PER_KILL.
- [~] Hide DEFERRED to v1.3 (leather chain) — same rule as F1's barley/flax:
      no crop/kill yields a resource with no use yet.

## Phase F4 — Brewing  *(new building + recipe)* ✓
- [x] Barley crop + Barley/Ale resources + Brewery workstation (new atlas
      tile 16, a barrel). RecipeDefs brew_ale: 2 barley → ale, max_stock 4.
- [x] Recipe station filtering fixed: recipes name their building, so a
      brewery never forges swords (latent gap — forge was the only station).
- [x] Ale is a joy good: villagers drink a mug on breaks/festival evenings
      for +joy +mood (cooldown so they don't drain the cellar at once).
- [x] Save: brewery is a building, ale/barley are resources — all already
      covered by existing collectors. No version bump.

## Phase F5 — Livestock  *(new entity, save/load)* ✓ (chickens)
- [x] Chickens as a critter-class Livestock entity; Chicken Coop building
      (new atlas tile 17). A fresh coop comes stocked with 2 hens (load
      restores saved animals instead, so no duplication).
- [x] Hens lay an egg (raw food) about once a day (Balance.EGG_LAY_DAYS).
- [x] Full save/load: livestock cells, kind, and lay timers. SAVE_VERSION 24.
- [~] Sheep + Pasture + wool DEFERRED to v1.3: wool is a dead-end resource
      until the cloth chain exists (same rule as barley/flax/hide). The
      Livestock entity is already kind-generic, so sheep drop in cheaply then.

## Phase F6 — Weather  *(light layer)* ✓
- [x] WeatherDirector rolls each morning: rain (crops grow faster, small
      outdoor mood dip), storm (outdoor work ×0.75 + bigger mood dip),
      snow (winter visual). Static reads for crops/work; screen-space
      particle overlay; a feed line on change. No fire/fluid sim.
- [x] Saved with the day ("weather" field on the v24 save).

## Phase F7 — Ship it
- [x] SAVE_VERSION at 24 (covers F2 stew-kind + F5 livestock; F6 weather
      rides the same version). Load-guards read new fields with defaults.
- [x] Hint for the egg loop (build a coop). Hunting/brewing are discoverable
      through the build menu + auto-behavior.
- [ ] DoD (human): play one year — hunt when short, brew for the mood,
      keep a flock, weather a storm. Then tag v1.2.

## Note on sequencing (read before piling on)
F1 is safe to land now. F2–F6 each add runtime surface (recipes, entities,
save data) to a build that is **17 commits deep and not yet human-tested**.
Per POLISH.md's anti-loop rules, the honest gate before F2 is: push the
current pile, play v1.1 for real, confirm nothing regressed. Then resume
phase by phase.
