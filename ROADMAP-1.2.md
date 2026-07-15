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

## Phase F4 — Brewing  *(new building + recipe)*
- [ ] Barley crop (F1 held it back) + Brewery building (workstation).
- [ ] Barley → ale; ale is a joy good consumed on breaks/festivals.
- [ ] Save: brewery is a building; ale is a resource — both already covered.

## Phase F5 — Livestock  *(new entity, save/load)*
- [ ] Chickens + sheep as critter-class entities; Coop + Pasture buildings.
- [ ] Produce eggs / wool on timers (no breeding sim — buy from caravans).
- [ ] Full save/load for animals and their timers (SAVE_VERSION bump here).

## Phase F6 — Weather  *(light layer)*
- [ ] Rain (crops grow faster, small mood dip), storm (outdoor work slows),
      snow visual in winter. No fire/fluid sim — ever.
- [ ] Drives off GameClock; a per-day weather roll, saved with the day.

## Phase F7 — Ship it
- [ ] SAVE_VERSION bump (once, covering F2–F6 additions), load-guard tested.
- [ ] Hints for the new loops (preserve before winter, hunt for meat).
- [ ] DoD (human): play one year — survive winter on preserves, hunt when
      short, brew for a festival, keep a flock. Then tag v1.2.

## Note on sequencing (read before piling on)
F1 is safe to land now. F2–F6 each add runtime surface (recipes, entities,
save data) to a build that is **17 commits deep and not yet human-tested**.
Per POLISH.md's anti-loop rules, the honest gate before F2 is: push the
current pile, play v1.1 for real, confirm nothing regressed. Then resume
phase by phase.
