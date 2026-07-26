# ROADMAP-2.4.md — The Wider World (make the big map feel like a world)

> Content beyond VISION, riding the open-world scale + Frontier work. The map
> is 2.25× bigger but still uniform grass/dirt noise. This gives it *regions*:
> concentric wilds that get wilder toward the frontier edge, so crossing the
> world means passing through real country — and the frontier genuinely feels
> like one.
>
> Same rules: data catalog + regenerated-from-seed (no new save) + no new
> autoload + no new screen. Art-free — reuses the existing grass/dirt tiles;
> Codex can add distinct terrain art later without any code change.

## Phase W1 — Biomes  *(regions + biased ground + biased scatter)* ✓
- [x] BiomeDefs catalog: Meadow (home), Deepwood, Highlands, Ashlands — each with
      a dirt bias and per-thing scatter weights (tree/ore/bush/decor/landmark).
- [x] World-gen assigns a biome per cell = distance-from-home + low-freq noise
      (ragged concentric rings): green safe center, ashen dangerous edge. Stored
      on WorldGrid.biomes, regenerated from the seed on load (nothing new saved).
- [x] Ground grass/dirt mix is biome-biased (lush meadow → barren ashlands).
- [x] Scatter is biome-weighted (WorldSpawner._biome_weighted_cell): forests
      cluster in the Deepwood, ore in the Highlands, bushes/flowers in the Meadow,
      and the richest landmarks out in the Ashlands — which also pushes them to
      the far edges, reinforcing the Frontier's "reward is out there."
- [x] WorldGrid.biome_at(cell) for any system that wants to ask.

## Phase W2 — Region Character  *(make biomes matter to play)*
- [ ] Biome-flavored ambient: which critters spawn where (boar/wolf lean wild),
      weather/tint per region, a one-line "you cross into the Ashlands" notice.
- [ ] Danger gradient: raids/beasts skew toward the wild rings; the Ashlands
      edge is where the Frontier's danger-on-investigate (v2.3 F3) concentrates.
- [ ] Hook biome into the villager/landmark tooltips (name the country).

## Phase W3 — Ship it
- [ ] Optional distinct terrain art (Codex: sand/marsh/ash tiles) swapped in by
      biome once drawn — pure art, no code change to the region logic.
- [ ] Balance from playtest: ring radii, scatter weights, ore/wood reachability
      from a central start (make sure early wood/stone stay close enough).
- [ ] DoD (human): start a game, cross from green home to grey edge, confirm the
      world reads as regions and the far country pays off.
