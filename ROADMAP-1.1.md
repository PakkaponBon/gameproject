# ROADMAP-1.1.md — Hearth & Home

> Slice of VISION.md. The point: make players love the village before we
> deepen war or economy. Same rules as ROADMAP.md: one phase at a time,
> DoD gates, everything ships with save/load, tone rule always.

## Phase H1 — Rooms & Warmth
- [x] Room detection in WorldGrid: flood fill from map edge on building change;
      unreached non-wall cells = indoors
- [x] Warmth need: drains outdoors in winter, refills indoors, fast near a
      warmth source. Cold = mood + work-speed penalty. **No HP damage** — cold
      makes villagers miserable, not dead (avoids a new death spiral)
- [x] Hearth building (warmth source, radius) + brazier (cheap, small radius)
- [x] Hint: first autumn — "Winter is coming. Wall in a room with a hearth."

## Phase H2 — Comfort & Joy
- [x] Furniture in BuildingDefs (data only): table, chair, shrine, trophy wall
- [x] Tile atlas extended for hearth/brazier/furniture
- [x] Comfort near furniture (radius model) → joy regen + gathering target
- [x] Joy need: slow drain; refills near shrine/hearth/furniture, big boost at
      festivals; low joy = mood penalty
- [x] Break behavior: villagers on break seek the nicest spot (hearth/shrine)

## Phase H3 — Bonds
- [x] PawnSocial component: pair scores drift up from shared meals/breaks/fights,
      down when a Loner is in the pair; friend at +40, rival at -40
- [x] Mood: friend nearby small +, rival nearby small -, friend's death = deep grief
- [x] Villager card shows strongest bond ("Friend of Fenna")
- [x] Saved per pawn

## Phase H4 — Festivals
- [x] FestivalDirector: Founding Day (spring 1), Firstfruits (autumn 1),
      Emberlight (winter 3 — candles for Vhal, the tone pillar as content)
- [x] Festival day: joy/mood boost, evening gathering at the nicest spot,
      feed + chronicle entries. Work continues (colony sim, not cutscene)

## Phase H5 — The Chronicle
- [x] EventBus.chronicle_entry signal; ChronicleDirector (scene-local, capped log)
- [x] Entries wired: deaths, grief, raids won, festivals, refugees, realm ruled
- [x] Chronicle panel: toolbar button (memorial-stone icon) + [C], scrollable story
- [x] Saved with the game

## Phase H6 — Ship it
- [x] Save v22: warmth/joy, social scores, chronicle entries (rooms re-derive)
- [x] New-game intro line mentions the cold; hints updated
- [ ] DoD (human): play one year — winter without a hearth is visibly miserable,
      with one is visibly cozy; a festival fires with a gathering; two bonds
      form; the chronicle reads back like a story. Then tag v1.1.
