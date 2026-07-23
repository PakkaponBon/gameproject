# ROADMAP-2.3.md — The Frontier (make the open world worth crossing)

> New content **beyond** VISION.md, unlocked by the open-world scale pass
> (64→96 map). The map is now big enough to hold *places* — old, quiet,
> dangerous-and-rewarding features you discover and investigate on the **home
> map itself**. Distinct from v1.4's world-map wild sites (those stay abstract
> UI + expedition; these you physically walk to).
>
> Same rules, always: a data catalog + save/load + the existing job system,
> **no new autoload, no new screen** (guardrail 1-2). Tone rule outranks all:
> ruins are melancholy, never gory — the tragedy is told, never shown.

## Why this, why now
The world just doubled in area and reads emptier. VISION's non-goals forbid a
second simulated map, dungeons/z-levels, and *playing on* the world map — but
nothing forbids landmarks on the home tilemap. Landmarks are the *reason* the
map grew: they give scouting a payoff and turn empty tiles into a frontier.

## Phase F1 — The Land Remembers  *(catalog + scatter + discovery + save)* ✓
- [x] LandmarkDefs catalog: name, atlas cell, tint, scale, blurb, reward table
      (resources / renown / shard / relic), renewable_days, min distance from home.
      Six authored places, all reusing existing sprite cells (nothing renders blank).
- [x] Landmark node (class_name Landmark): a visible feature on the map, snapped
      to a cell, group "landmarks". Undiscovered until a villager passes within a
      few tiles, then it reveals — a toast (EventBus.notice → HUD) + a chronicle line.
- [x] world_spawner scatters landmarks at world-gen, area-scaled and kept out
      of the start cluster (min-distance from center), so the reward is *out there*.
- [x] Save/load: id + cell + discovered + claimed + regrow state, additive via get().

## Phase F2 — Set Out  *(the investigate job + rewards)* ✓
- [x] Click a (dim or revealed) landmark → issues an INVESTIGATE job; a villager
      walks out and works it. Reuses the job/reservation system: new
      Job.Type.INVESTIGATE, mapped to the CHOP (gathering) priority group,
      handled by the standard stationary-work case in pawn_work.
- [x] On completion: rolls the reward table (mirrors FactionManager._grant_site_loot)
      — loose goods spill by the landmark for haulers to carry home, renown granted,
      a relic shard / full relic on the odds. Feedback via toast + chronicle + a
      gold FX puff. One-shot landmarks deplete (dim to spent); renewable ones set
      regrow_ticks and re-open after their cooldown (with a "come back" toast).
- Note (for playtest): INVESTIGATE rides CHOP priority, so villagers pull it by
  nearest-reachable like any gathering job — a far landmark may wait while closer
  wood exists. If it feels unresponsive, F3/tuning can give it a dedicated priority
  or a "send the selected villager" push instead of a queued pull.

## Phase F3 — Frontier Flavor  *(content breadth, tone)*
- [ ] Fill the catalog to ~8 places with distinct payoffs and authored vignettes
      (told-not-shown). A rumor hook: a far, high-value landmark only reveals its
      name once renown is high enough (reuse the SiteDefs reveal idea, home-map side).
- [ ] Light danger option (data flag): some landmarks can rouse a small beast
      or bandit on investigate — reuse raider/critter, no new combat code.

## Phase F4 — Ship it
- [ ] Difficulty/scenario hooks (Wanderers = more landmarks; Peaceful = no danger flag).
- [ ] Numeric balance from playtest (landmark density vs. reward vs. travel cost).
- [ ] DoD (human): start a game, find a landmark across the map, send a villager,
      claim a reward, watch a renewable one come back. Then fold into the ladder.
