# ROADMAP-1.4.md — The Wilds

> Slice of VISION.md ("v1.4 The Wilds — make the map call to you").
> Same rules: one phase at a time, DoD gates, save/load always, tone rule
> always. The world map stays UI + data + events — never a second sim.

## Phase W1 — Wild Sites ✓
- [x] SiteDefs catalog: Ruins of Vhal (relic odds, stone), the Witchfen
      (herbs), the Dwarf-road (iron), the Howling Barrow (double shards,
      hardest) — difficulty, loot, cooldown, chronicle vignette each.
      Expeditions generalized beyond "ruins"; site cooldowns saved
      (additive "sites" key in the realm blob).
- [x] All four on the world map with icons, flavor, danger/loot/odds
      detail, and per-site expedition buttons; cold trails shown and
      the button disabled until ready.

## Phase W2 — Shards & the Shrine ✓
- [x] Relic shards: the common site treasure (full relics stay rare).
- [x] The Shrine is now a workstation (and glows): 3 shards → one relic,
      random from the known set (recipe "output_pool" support). Assembly
      stays expedition-gated — magic is never crafted from raw materials.

## Phase W3 — Bestiary ✓
- [x] Ash-wolves: winter mornings may loose a pack of 3-4 (no faction, no
      scout warning, no gate-battering — walls fully answer wolves). Fast,
      fragile, hit softly; a felled wolf drops meat. Saved via a beast flag.
- [x] Boars: a share of replenished game is a boar — extra meat, but it
      wounds its hunter once when cornered (Balance.BOAR_BITE).
- [x] Legion elites: Ashen Legion raids of 5+ field armored ranks
      (armor 4, +20 hp, deep-red). Saved via an elite flag.

## Phase W4 — Expedition Prep
- [ ] Provisioning: expeditions auto-pack spare food/herbs; supplies raise
      power and cut casualty odds; the world map shows what they'd take.
- [ ] Risk estimate: "odds look strong / even / grim" before committing.

## Phase W5 — Ship it
- [ ] Save additions verified; hints for sites and the shrine.
- [ ] DoD (human): raid all four sites, awaken a relic at the shrine,
      survive a wolf winter, read the odds before an expedition. Tag v1.4.
