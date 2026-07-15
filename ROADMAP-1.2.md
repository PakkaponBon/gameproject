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

## Phase F2 — Preserves & Cooking Variety  *(recipes = data)*
- [ ] Preserves: at the stove, raw food → "preserve" (keeps through winter,
      the anti-famine buffer). Recipe data + a kitchen policy toggle.
- [ ] A second cooked good (stew) for meal variety → small extra mood.
- [ ] Save: preserves are just FoodItem variants (meal flag already saved).

## Phase F3 — Hunting  *(reuses critters + jobs)*
- [ ] Critters become huntable: a drafted or auto HUNT job; arrow puff,
      no gore (rabbit fades like everything else per tone rule).
- [ ] Drops meat (food) + occasionally hide (for F-later leather).
- [ ] Balance knobs in Balance: critter respawn, meat yield.

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
