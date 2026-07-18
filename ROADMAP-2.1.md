# ROADMAP-2.1.md — The Living Realm  *(post-2.0 content depth)*

> The game is complete (v1.0→v2.0). This is a depth pass: more of what makes
> a long game feel alive, built entirely from the data catalogs and existing
> systems. **Art-safe by design** — every phase reuses existing atlas cells,
> so it never collides with the asset agent's graphics rework. Save-safe too:
> catalog entries and events need no version bump.
>
> Toward VISION's content targets: traits ~10→25, events 6→25+, relics 3→10.

## Phase LR1 — The Event Deck  *(events_director; no art)* ✓ this session
- [x] New dilemmas (paused, two real choices, consequences + chronicle):
      the Fever (treat with herbs or ride it out), the Feud (take a side or
      let it settle), the Buried Cache (keep quiet or share), the Scholar
      (pay food to teach a villager a skill).
- [x] New ambient beats (feed-only): a fine harvest, a good/ill omen.

## Phase LR2 — Character Depth  *(trait_defs; no art)* ✓
- [x] Traits 10 → 20. New quirks: Swift, Marksman, Hot-Blooded, Warm, Clumsy
      (a negative, for variety), Old Blood. New backstories: Bellringer,
      Gravedigger, Physician, Runaway. Each uses a key the game already reads
      (work/melee/ranged mult, magic).
- [x] One new key wired: "gregarious" (the Warm trait) speeds bond growth in
      PawnSocial — the mirror of the existing Loner. No art, no save bump.

## Phase LR3 — Magic Variety  *(relic_defs + a little combat; reuses cell 12)* ✓
- [x] relic_tick now dispatches on an explicit "kind" (blast/frost/storm/heal/
      ward); the three originals got their kind, no behavior change.
- [x] Frost (blast + chills — struck raiders act every other tick via a new
      raider.apply_slow), Stormcall (chain — the nearest few each take a hit),
      Ward Totem (wider, more frequent barrier than Barrier). Relics 3 → 6,
      all reuse the relic sprite tinted per color; added to the shrine pool,
      boss drops, and the falling-star event automatically (they read ORDER).

## Phase LR4 — Arms Variety  *(weapon_defs; reuses the sword sprite)* ✓
- [x] Three tier-1 melee weapons via a new weapon "attack_ticks" (swing
      speed): Club (cheap/fast/weak — 1 ingot), Spear (iron-light, solid —
      1 ingot + 2 wood), Warhammer (slow/crushing — 3 ingots). Because armor
      subtracts per hit, the Warhammer's big hits beat elites while the Club
      clears swarms — real tactical spread from the existing armor math.
- [x] Entry via loot AND forge: fallen raiders drop a random tier-1 arm
      (swords common, warhammer rare), and each has a forge recipe. Held
      sprite now tints per weapon so they read apart (all reuse the sword
      cell). ResourceDefs + RecipeDefs + WeaponDefs, no art, no save bump.

## Phase LR5 — Ship it
- [ ] DoD (human): play a long game and confirm the new events, traits,
      relics, and arms show up and read well. Then tag v2.1.
