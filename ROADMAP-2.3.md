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

## Phase F2 — Set Out  *(the investigate job + rewards)*
- [ ] Click a discovered (or visible) landmark → issue an INVESTIGATE job; a
      villager walks there and works it. Reuse the job/reservation system; new
      Job.Type.INVESTIGATE mapped into an existing priority group.
- [ ] On completion: roll the reward table — drop resources on the ground,
      grant renown, maybe a relic shard / relic. Feedback via toast + chronicle
      + StoryPanel for the rare finds. One-shot landmarks deplete (fade/marker);
      renewable ones set regrow_ticks and return after their cooldown.

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
