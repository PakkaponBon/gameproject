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

## Phase LR3 — Magic Variety  *(relic_defs + a little combat; reuses cell 12)*
- [ ] Dispatch relics by an explicit "kind" (back-compat with the 3 originals).
- [ ] Frost (blast + slows raiders), Stormcall (chain — the N nearest each
      take a hit), Ward Totem (a stronger, wider barrier). Toward 3→~6 relics;
      all reuse the relic sprite, tinted per color. Add to the shrine pool.

## Phase LR4 — Arms Variety  *(weapon_defs; reuses the sword/bow sprites)*
- [ ] Club (cheap tier-1), Spear (tier-1, small reach edge), Warhammer
      (tier-1, heavy, slow). Each = WeaponDefs + ResourceDefs (reuse sword
      sprite, tinted) + a forge recipe. If distinct icons are wanted later,
      file an ASSET_SPEC request.

## Phase LR5 — Ship it
- [ ] DoD (human): play a long game and confirm the new events, traits,
      relics, and arms show up and read well. Then tag v2.1.
