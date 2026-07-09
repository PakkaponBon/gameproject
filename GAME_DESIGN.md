# GAME_DESIGN.md — Ashfall (working title)

The "what is this game" document. Every feature must serve this. Doesn't fit → IDEAS.md.

## Pitch
A dark-origin **fantasy colony sim**: your home city burned, your family was killed. You lead the survivors to a quiet meadow, rebuild from nothing — then take the world back. Villagers farm, craft, and fight; surrounding factions can be befriended, allied… or destroyed. Every faction dealt with, by treaty or by sword, brings you closer to ruling it all.

**One line:** *Born from ashes. Rebuild the village. Rule the world.*

## Player fantasy
"From refugee to ruler." The warmth of building a home + the power fantasy of conquest. The village is cozy *because* the world outside isn't.

## Tone
Warm hearth, dark world. The village feels safe and hand-built; the wilds and enemy factions are threatening. Violence exists (combat, loss) but no gore — knocked-down sprites, puffs, fade-outs. The origin tragedy is told, not shown.

## Story frame
- **Opening event:** scripted intro — the city falls, you flee with 3 survivors and a wagon. That's the tutorial framing.
- **Founding villagers carry it:** each starting survivor has a backstory trait from the fall (Orphaned: +combat, mood penalty near fire; Last Smith: +crafting; Witness: +vigilance, nightmares). Traits = data, not cutscenes.
- **Ending:** when every faction on the world map is allied or destroyed → "Ruler of the Realm" — crown event, epilogue screen, sandbox continues.

## Core loop (minute-to-minute)
1. Spot a need (food low, weapons needed, faction threat growing)
2. Order: zone farms, place blueprints, craft gear, set priorities, draft fighters
3. Villagers execute autonomously
4. Events hit (raids, envoys, discoveries) → react, re-plan

## Meta loop
Seasons drive the economy (plant → harvest → survive winter). Faction pressure drives the arc: grow strength → deal with the next faction (ally or conquer) → territory/tribute grows → stronger factions notice you → endgame.

## Pillars
1. **Indirect control** — order, don't puppet. Draft mode is the combat exception.
2. **Hearth vs wild** — inside the walls is warm and safe; outside is dangerous. The contrast IS the game feel.
3. **Every threat is also an option** — factions can be fought OR joined. Two paths to victory: diplomat or conqueror (or mix).
4. **Readable simulation** — always visible why a villager does what they do.
5. **Small map, big consequences** — one home map + abstract world map. Depth over sprawl.

## Systems (v1.0 scope)

### Villagers
- Needs: hunger, rest, mood
- Skills: farming, building, crafting, cooking, hauling, **melee, archery, magic affinity**
- Backstory traits (1–2 each) with stat effects
- Cap: 15. Death is possible (combat, neglect, starvation) — loss is real in this game. Funerals/mood hits instead of gore.

### Work & economy
- Job queue with reservations, per-villager priority grid
- Farming/seasons: fields, 4–6 crops, winter pressure, cooking (economy backbone — unchanged from skeleton plan)
- Resources: wood, stone, **iron ore → ingots**, crops, meals, **weapons/gear**

### Weapons (the tier ladder)
| Tier | Weapon | Get it | Who can use | Notes |
|---|---|---|---|---|
| 1 | **Sword** (+club/spear variants) | Craft at forge from iron; common loot | Anyone | Cheap, reliable, melee |
| 2 | **Bow** | Craft (harder recipe); requires Archery skill ≥ threshold | Skilled villagers only | Ranged, needs arrows, skill-gated |
| 3 | **Magic** (staves/relics) | **Cannot craft.** Rare: ruin expeditions, faction rewards, rare merchant stock | Villagers with Magic affinity trait | Strongest by far; long cooldowns; each relic unique (fireball, heal, barrier, frost) |

Design intent: swords arm the mob, bows arm the trained, magic is treasure that decides battles — scarcity + cooldowns keep it from trivializing combat.

### Combat
- Real-time with pause; drafted villagers take move/attack orders, undrafted flee to a safety zone
- HP, damage, armor — light data model (no hit locations/organs)
- Injuries: wounded → bed rest / healing herbs / heal magic. Death if untreated or overwhelmed
- Defenses: walls, gates, watchtowers (archer slots), 1–2 trap types

### Factions & world map (the arc)
- Abstract world map screen: **5 factions** around your region (bandit clans, a proud kingdom remnant, forest tribe, mountain holds, and **the enemy that burned your city — faction #5, the strongest, the de-facto final boss**)
- Each faction: strength score, attitude meter (hostile ↔ allied), personality (aggressive / greedy / honorable)
- **Interactions:** envoys & gifts (diplomacy), trade, tribute demands, their raids (played out on your home map), **your expeditions** (send an armed party; off-map battles auto-resolve from strength + gear + luck)
- **Per-faction resolution:** attitude maxed → alliance (trade bonus + they join major battles). Strength zeroed → destroyed/absorbed (loot + tribute)
- **Victory:** all 5 resolved (any mix of ally/destroy) → Ruler of the Realm event. Sandbox continues.

### Progression
- Forge/workshop tiers (wood gear → iron gear)
- Ruin expeditions on the world map: risk a party for relic chances (the magic faucet)
- Village renown from wins/alliances → unlocks bigger buildings, attracts new villagers

## Content rules
- No gore/dismemberment; death = knockdown → fade, grave + mood consequences
- The city-fall backstory is text/ambience — never depicted on-screen violence against family
- Writing voice: grounded, a little grim, warm inside the walls

## Explicitly OUT of v1.0 (IDEAS.md)
Multiplayer, mods, z-levels, playing ON the world map (it's a menu/event layer, not a second sim), romance/children, siege engines, spell crafting, naval anything, multiple home maps, livestock systems.

## Decisions made (change here if wrong)
- **World map = abstract screen**, not a second playable map. Expeditions auto-resolve; only raids on YOUR village are simulated. This one decision is what keeps "rule the world" shippable solo.
- **5 factions** in 1.0
- **Seasons stay in** — economic pressure layer under the war layer
- **Death is in**, gore is not
- **Working title: "Ashfall"** — placeholder, rename anytime
