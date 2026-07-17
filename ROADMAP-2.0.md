# ROADMAP-2.0.md — The Long Night (the finale)

> Slice of VISION.md's Act III + endings. The emotional payoff of the whole
> game. Same rules: save/load always, tone rule always (the tragedy is told,
> never shown), world map stays UI+data. Music is a human art pass — deferred.

## Phase N1 — The Gathering Dark  *(trigger + siege + victory)* ✓ this session
- [x] Trigger: when the four other factions are all resolved and the Ashen
      Legion still stands, the Long Night begins (FactionManager.long_night_begins).
- [x] Warning phase: a scripted intro, then ~1.5 days to prepare — normal
      raids suspended (raid_director.siege_active).
- [x] The siege: four escalating Legion waves with lulls between to heal;
      the last led by the Cindermarked (boss). Elites every other raider;
      allies and oath-kin answer. Survive all waves → the Legion breaks.
- [x] LongNightDirector state machine (DORMANT→WARNING→WAVE↔LULL→WON), saved.

## Phase N2 — The Three Endings ✓ this session
- [x] The Long Peace: all five factions allied (no siege) → the diplomat's crown.
- [x] Ruler of the Realm: mixed resolution (kept from v1.0).
- [x] Vhal Reclaimed (true ending): survive the Long Night → a warm, quiet
      multi-page epilogue returning to the ruined city. Told, never shown.

## Phase N3 — Scenarios ✓
- [x] ScenarioDefs catalog (pawns / start season / start food / renown mult /
      blurb). Standard, Hard Winter (autumn start, 2 founders, thin larder),
      Wanderers (bare larder, 1.5× renown). Cycle button + blurb on the main
      menu; choice rides a static through the scene change and saves in the
      realm blob. new_game reads it (season offset, pawn count, forage).

## Phase N4 — Ship it
- [x] Difficulty scales the finale: Hard sieges 1.4× wave sizes; Peaceful
      never sieges — the Legion is resolved by treaty/expedition instead, so
      "no raids" holds all the way to the end (endings stay correct).
- [ ] Numeric balance from playtest (wave sizes / lull length vs a fully
      armored, trapped village) — needs real play.
- [ ] Music pass (human): village / winter / raid / festival / map / Long Night.
- [ ] DoD (human): resolve four factions, survive the Long Night, see Vhal
      Reclaimed. Then tag v2.0 — and the game is done.
