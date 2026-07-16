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

## Phase W4 — Expedition Prep ✓
- [x] Provisioning: expeditions auto-pack up to 3 spare raw food (+power,
      fewer casualties) and a bundle of herbs (fewer casualties); the
      march-out line reports what they took. Rides the saved expedition dict.
- [x] Risk estimate on the map: strong / even / grim odds shown for every
      site and for attacking any unresolved faction. Armor now counts
      toward expedition power (it keeps them swinging longer).

## Phase W5 — Ship it
- [x] Save additions verified additive (beast/elite flags, sites, packed
      supplies all ride existing structures). Hints: wild sites once a
      party stands ready; the shrine once 3 shards are held.
- [ ] DoD (human): raid all four sites, awaken a relic at the shrine,
      survive a wolf winter, read the odds before an expedition. Tag v1.4.
