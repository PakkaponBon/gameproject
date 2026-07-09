# ROADMAP.md — Ashfall: Skeleton → v1.0

Current state: **v0.1-skeleton** (world, pathfinding, jobs, hauling, needs, multi-villager priorities).

Rules: one phase at a time, in order. Each phase gates on its **Definition of Done (DoD)**. Git tag per phase. From Phase 1 on, every new system ships with save/load. Not required by a DoD → IDEAS.md.

> Scope note: this is the FANTASY concept (combat + factions). It's ~2x the cozy version. Phases 4–6 are the new weight — respect the gates.

---

## Phase 1 — Persistence (v0.2)
- [ ] Save: grid, tiles, villagers (position, needs, skills, traits, inventory, priorities), items, jobs, stockpiles, buildings, clock/season
- [ ] Load mid-job without desync; autosave each morning + manual save menu
- [ ] Save versioning field

**DoD:** Save mid-haul → quit → load → resumes exactly.
**Tag:** `v0.2-persistence`

---

## Phase 2 — Construction (v0.3)
- [ ] Blueprint → haul materials → timed build job
- [ ] Buildings: wall, gate, bed/house, storage barn
- [ ] Deconstruct (partial refund)

**DoD:** Order a walled yard + gate + house + barn; built hands-off.
**Tag:** `v0.3-construction`

---

## Phase 3 — Economy: Farming & Seasons (v0.4)
- [ ] Day/night + calendar (4 seasons × N days), season in UI + visual tint
- [ ] Rest need, sleep in beds, exhaustion slows work
- [ ] Field zoning, crop lifecycle (plant → grow → harvest), 3+ crops, winter kills crops
- [ ] Eating, starvation → collapse → death if neglected
- [ ] Mood v0: single value from needs (hungry/exhausted lower it), modifies work speed — foundation for trait/death effects later
- [ ] Mining job: stone + iron ore nodes

**DoD:** 3 villagers survive a year hands-off with a good field plan; a bad plan starves them.
**Tag:** `v0.4-economy`

---

## Phase 4 — Combat Core (v0.5)  *(new weight starts here)*
- [ ] HP / damage / armor data model; wounded state → bed rest to heal; death + grave + mood hit
- [ ] Draft mode: move/attack orders; undrafted villagers flee to safety zone
- [ ] Melee combat: unarmed + Tier 1 swords
- [ ] Forge building + crafting job: iron ingots → swords (first crafting chain)
- [ ] Enemy raid v0: bandits spawn at edge, attack villagers/doors; walls & gates block pathing
- [ ] Combat skills (melee) affecting hit/damage
- [ ] Trait data model v0: traits as resources with stat/mood modifiers; 2–3 test traits incl. Magic affinity (Phase 5 needs it; full backstory pool comes Phase 9)
- [ ] Pause + speed controls (pause/1x/3x, basic) — required to test raids; UI polish stays in Phase 7

**DoD:** Survive a 4-bandit raid using a wall choke + 3 drafted sword villagers; one villager can be wounded and recover.
**Tag:** `v0.5-combat`

---

## Phase 5 — Weapon Tiers & Magic (v0.6)
- [ ] Bows: harder recipe, Archery skill gate, arrows as ammo; watchtower building (archer slot)
- [ ] Ranged combat AI (kite, tower priority)
- [ ] Magic relics: item type with unique spell + long cooldown (fireball, heal, barrier minimum)
- [ ] Magic affinity trait gates relic use; relics NOT craftable
- [ ] Traveling merchant event v0: rare wanderer, buy/sell menu (also the trade primitive Phase 6 diplomacy reuses)
- [ ] Relic sources v0: merchant stock + raid boss drop + debug spawn command (expeditions come in Phase 6)
- [ ] Healing herbs job/item (non-magic healing path)

**DoD:** A mixed squad (2 swords, 1 archer on tower, 1 relic user) beats a raid that swords alone lose.
**Tag:** `v0.6-arsenal`

---

## Phase 6 — Factions & World Map (v0.7)  *(the arc)*
- [ ] World map screen: 5 factions with strength, attitude, personality
- [ ] Diplomacy: envoys, gifts, trade, tribute demands; attitude max → alliance
- [ ] Faction raids scale with their strength/attitude; allies send help to big defenses
- [ ] Expeditions: send an armed party (they leave the map for N days) → auto-resolve from strength+gear+luck → loot/relics/casualties
- [ ] Ruin sites on world map (relic faucet)
- [ ] Faction destruction (strength zero) + absorption tribute
- [ ] Victory check: all 5 resolved → Ruler of the Realm event + epilogue, sandbox continues
- [ ] Opening event: city-fall intro, 3 survivors with backstory traits

**DoD:** A full campaign is completable both ways: ally at least 2 factions, destroy at least 2, beat faction #5, see the crown screen.
**Tag:** `v0.7-realm`

---

## Phase 7 — UI & Game Feel (v0.75)
- [ ] Villager panel (needs, mood, skills, gear, job); work priority grid
- [ ] Squad/draft UI, gear assignment UI
- [ ] World map UI polish: faction cards, attitude bars, expedition planner
- [ ] Resource + calendar HUD; pause/1x/3x; notifications feed; main menu
- [ ] Placement previews, selection highlights, threat warnings

**DoD:** A friend plays 30 minutes — builds, fights a raid, sends an envoy — without asking how.
**Tag:** `v0.75-playable`

---

## Phase 8 — External Playtest (v0.8)
- [ ] Windows export to 3–5 friends; watch 2+ live, silent, take notes
- [ ] Fix top confusions + crashes ONLY; repeat once

**DoD:** New player survives to year 2 and resolves one faction without help.
**Tag:** `v0.8-playtested`

---

## Phase 9 — Content & Balance (v0.85)
- [ ] Cooking (meals > raw), 2–3 more events (frost snap, refugee arrival, tribute ultimatum)
- [ ] Villager variety: names, portraits, full backstory trait pool
- [ ] Renown progression: unlock buildings, attract villagers
- [ ] Balance: weapon tier curve, faction difficulty curve, economy math pass
- [ ] Difficulty settings: normal + hard (data multipliers only)

**DoD:** Two campaigns (diplomat run vs conqueror run) feel like different games.
**Tag:** `v0.85-content`

---

## Phase 10 — Art & Audio (v0.9)  *(per ART_DIRECTION.md)*
- [ ] Tileset: seasonal ground, village warm-set, wilds dark-set, ruins
- [ ] Villagers: base + 2-frame walk/work, gear visible (sword/bow/staff overlays)
- [ ] Enemies: 3–4 types, 2-frame budget
- [ ] Portraits, world map art, spell effects (small, punchy)
- [ ] SFX: combat hits, spells (distinct), craft, farm, UI; Music: 3 loops (village day, raid, world map)
- [ ] Title screen + intro event art (2–3 still images, told-not-shown)

**DoD:** A cold screenshot reads "indie fantasy colony sim," not prototype.
**Tag:** `v0.9-polish`

---

## Phase 11 — Release (v1.0)
- [ ] Crash-proofing: 3 full campaigns, zero log errors
- [ ] Settings: volume, fullscreen, keybinds
- [ ] Exports: Windows + Linux; itch.io page (5 screenshots, 60s GIF, description)
- [ ] Launch; 2 weeks critical fixes; then DECIDE: grow or next game

**DoD:** A stranger finishes a campaign without a crash.
**Tag:** `v1.0`

---

## Scope guardrails
- The world map is menus + events. If you catch yourself simulating enemy villages tile-by-tile, stop — that's a different, 5-year game.
- No: multiplayer, mods, z-levels, siege engines, spell crafting, romance, livestock, naval. IDEAS.md.
- If Phase 6 starts sprawling, cut factions from 5 → 3. Shipping beats scale.
