# VISION.md — Ashfall: The Full Game

> The north star. Everything Ashfall grows into after v1.0 ships.
> **Rules of this file:** never code from here directly — when an update begins,
> slice a piece of this into a mini-roadmap with DoD gates, same as ROADMAP.md.
> IDEAS.md stays the parking lot; ideas graduate *into* this file, then into
> roadmaps. The Phase 15 gate (two fresh testers) still comes first. Nothing
> below starts until v1.0 is on itch.io.

---

## The full game in one paragraph

You fled the burning of Vhal with three survivors and a wagon. Ten years of
play later, Ashfall is a village that remembers: every grave has a name, every
festival toasts the ones who made it through, every wall stone was hauled by
someone you know. Around you, five factions scheme, trade, and march; beyond
them, wild places hold the relics of a broken age. You can farm through the
long winters, raise a hall and fill it with song, marry your smith to a
mountain thane, arm a company in iron and oak — and when the Ashen Legion
finally turns its full gaze on the meadow, you will either kneel, break them,
or walk back through the gates of Vhal itself. **Born from ashes. Rebuild the
village. Rule the world. Remember everyone.**

## Pillars (v1.0's four, plus one earned)

1. **Indirect control** — order, don't puppet. Draft is the only exception.
2. **Hearth vs wild** — warmth inside the walls, danger outside. The contrast is the game.
3. **Every threat is also an option** — fight it, join it, or trade with it.
4. **Readable simulation** — always visible why a villager does what they do.
5. **The village remembers** *(new)* — the game keeps your story: chronicles,
   graves, festival toasts, trait-born memories. Loss is permanent and honored.
   This is how a small sim feels big without adding sim depth.

## The three acts (full-game arc)

- **Act I — Embers** (Year 1): survive. Food, walls, first raid, first winter.
  This is v1.0's whole game and stays the strongest tutorial there is.
- **Act II — The Realm** (Years 2–3): the faction game. Contracts, oaths,
  expeditions, wars between neighbors, your name spreading. Ends when four of
  five factions are resolved.
- **Act III — The Long Night** (endgame): the Ashen Legion stops sending
  raiders and comes to finish what it started at Vhal — a multi-wave designed
  siege with warning seasons to prepare. Survive and break them, or stand
  beside allied factions who answer their oaths.

**Endings** (epilogue screens; sandbox always continues after):
- **Ruler of the Realm** — all five factions resolved, any mix (v1.0's ending, kept).
- **The Long Peace** — all five allied, none destroyed. The diplomat's crown.
- **Vhal Reclaimed** *(true ending)* — after the Legion falls, a final scripted
  expedition chain returns to the ruined city with the First Ember relic.
  Told in text panels, warm and quiet. The tragedy stays off-screen forever.

---

## Systems: now → full

### Villagers & needs
- Now: hunger, rest, mood; cap 15.
- Full: add **warmth** (winter + hearths + rooms matter) and **joy**
  (recreation: tavern, festivals, shrine). Cap 20. No aging, no children —
  population grows by refugees and recruits (see Non-goals).

### Skills & callings
- Now: melee, archery with XP.
- Full: the whole board — farming, building, crafting, cooking, hauling,
  melee, archery, **magic affinity** (trait-gated, per canon). One villager in
  ~4 rolls a **calling** (loves a job: faster XP + joy from doing it). All data.

### Relationships & village life
- Now: mourning mood hits.
- Full: **bonds and friction** — pairs of villagers drift toward friendship or
  rivalry from working/eating/fighting together; visible on the pawn card;
  mood consequences on death (a friend's grave hurts more). **Marriages**
  between adult villagers (text event + shared bedroom, tasteful and simple).
  **Festivals** ×3/year: Founding Day (spring), Firstfruits (autumn),
  **Emberlight** (midwinter — candles for Vhal; the tone pillar as content).
- **The Chronicle**: an auto-written log screen — raids survived, deaths,
  weddings, festivals, faction treaties. Cheap to build, enormous for feel.

### Farming & food
- Now: 5 crops, cooking at stoves, berry bushes, winter kill.
- Full: **10 crops** (add barley, carrot, pumpkin, flax, mushroom log — the
  last grows indoors in winter), **brewing** (barley → ale, the tavern input),
  **preserves** (berries → winter jars), **smokehouse** (meat), **compost →
  fertilizer** (field yield boost). **Hunting**: critters become a food source
  (arrow, puff, meat — no gore, rabbit just fades like everything else).

### Livestock *(graduates from IDEAS.md)*
- Chickens and sheep only. Coop + pasture buildings; animals are critter-class
  entities producing eggs/wool on timers. No breeding sim — buy from caravans.

### Production chains
- Now: ore → ingot → sword/bow at forge.
- Full: **flax → cloth → clothes** (warmth + a villager look), **hide →
  leather** (from hunting), forge tiers (wood → iron → **fine** gear with
  quality tags), and relic-shard work at the Shrine (below).

### Building & rooms
- Now: 8 buildings, walls/doors/gates with HP.
- Full: **~30 buildings**. Room detection (enclosed + door = a room): rooms
  give warmth and **comfort** (a light beauty stat — furniture counts, no
  per-tile beauty math). Furniture: table, chairs, hearth, shrine, trophy
  wall, brazier. Wall tiers wood → stone. Floors. The Great Hall — one big
  prestige building per village, festival venue, renown-gated.

### Defense & combat
- Now: HP/damage numbers, walls, towers, draft, safety zones.
- Full: **armor ladder** — padded → leather → iron (armor slot beside weapon
  slot, same equip flow). **Traps** ×3: spike pit, tripwire bell (early
  warning), brazier line (fear zone, enemies path around — uses the existing
  dual-grid trick). **Siege events**: Legion brings a ram (targets gates —
  battering AI already exists), shielded elites (resist arrows, weak to
  magic). Combat model stays numbers-only, forever.

### Magic & relics
- Now: 3 relics (fireball, heal, barrier), boss drops, expedition loot.
- Full: **10 relics** (add frost, ward totem, ember blade, stormcall, the
  quest-relic First Ember...). **Relic shards** from wild sites; a **Shrine**
  building assembles 3 shards into a *known* relic — magic stays treasure
  (never crafted from raw materials; assembly is still expedition-gated).
  Magic affinity trait required to wield, per canon. Cooldowns stay long.

### Factions & diplomacy
- Now: 5 factions, attitude/strength, gifts, envoys, tribute, expeditions, alliance/conquest.
- Full: **named leaders** with portraits and personality quirks (Thane of
  Deepstone loves ingots, despises gifts of food...). **Contracts**: factions
  post requests on the world map ("20 ingots before winter — +attitude, +silver
  renown"). **Oaths of kinship**: marry a villager into a faction — permanent
  attitude floor, they send aid in the Long Night (the villager leaves; a
  real cost). **Faction wars**: neighbors fight each other over time; strength
  scores drift; you can tip wars with supplies. All of it stays world-map
  UI + data + events — never a second simulated map.

### World map & expeditions
- Now: 5 factions, auto-resolved expeditions, ruin loot.
- Full: **wild sites** between factions — the Ruins of Vhal, the Witchfen,
  the Dwarf-road, the Howling Barrow. Each is an expedition table: unique
  relic/shard loot, a text vignette, a respawn timer, a difficulty score.
  **Expedition prep**: pick the party, pack supplies (food/herbs shift the
  odds), see the risk estimate before committing. Still fully auto-resolved.

### Events & story
- Now: frost snap, refugees, raids, envoys, tribute demands.
- Full: a weighted **event deck of 25+**: wanderer at the gate, fever in the
  village (treat with herbs — plague-lite, no body horror), wolf winter,
  falling star (relic shard!), Legion ultimatums, backstory-trait memory
  events (the Last Smith gets a nightmare event; the Orphan gets a quiet
  scene at Emberlight). Events are dictionaries; adding one never adds code.

### Seasons & weather
- Now: 4 seasons, winter crop kill, day/night tint.
- Full: a light **weather layer** — rain (crops grow faster, mood dips),
  storms (outdoor work slows), snow (visual + warmth pressure), drought event
  (water the fields by hauling). No fire-spread simulation, ever — fires are
  scripted event damage only.

### Threats (the bestiary)
- Now: bandits, bosses, Legion raiders.
- Full: **ash-wolves** (winter packs, test your walls), **boar** (hunting
  bites back), **the Marsh Drake** (rare boss at the Witchfen — expedition
  legend, occasionally raids), **Legion ranks** (levy → shieldbearer → the
  Cindermarked). Grounded dark fantasy — no undead, no horror.

### Presentation
- Full: pixel font with Thai glyphs, villager portraits, terrain autotile +
  water, door open/close states, work animations, 6 music tracks (village /
  winter / raid / festival / world map / the Long Night), per-season ambience.
  ART_DIRECTION.md governs all of it.

### Meta
- **Scenarios** ×3: Standard, Hard Winter (autumn start, 2 pawns), Wanderers
  (no wagon larder, high renown gain). **Sandbox toggles** post-ending.
  **Chronicle export** — save your village's story as a text file.
  **Modding**: everything is already data files; ship MODDING.md documenting
  the def dictionaries. Thai + English localization. itch.io first, Steam
  when the update ladder proves people play it.

---

## Content targets (now → full)

| Content | v1.0 | Full |
|---|---|---|
| Crops | 5 | 10 |
| Buildings | 8 | ~30 |
| Furniture | 0 | 8 |
| Weapons | sword, bow | + club, spear, fine tiers |
| Armor | 0 | 3 tiers |
| Relics | 3 | 10 |
| Traits | ~10 | 25 |
| Events | ~6 | 25+ |
| Enemy types | 2 | 8 |
| Wild sites | 0 | 4 |
| Festivals | 0 | 3 |
| Endings | 1 | 3 |
| Music tracks | 2 | 6 |

## The release ladder

Each update = one mini-roadmap (own file or section), own DoD gate, same
anti-loop rules as POLISH.md. One update at a time. Ship before starting the next.

| Version | Name | The point | Headline systems |
|---|---|---|---|
| **v1.0** | **Embers** | Prove it | Everything currently built + Phase 15 gate |
| v1.1 | Hearth & Home | Make them love the village | Rooms/warmth/joy, furniture, festivals, bonds, Chronicle |
| v1.2 | Field & Flock | Deepen the economy | New crops, livestock, hunting, brewing, preserves, weather |
| v1.3 | Steel & Oath | Deepen the realm | Armor, traps, faction leaders, contracts, oaths, faction wars |
| v1.4 | The Wilds | Make the map call to you | Wild sites, bestiary, expedition prep, shards + Shrine |
| **v2.0** | **The Long Night** | Finish the story | Act III siege, three endings, scenarios, music pass |
| post-2.0 | — | Open the doors | MODDING.md, Thai localization, Steam |

Ordering logic: v1.1 before economy/war because *attachment* is the engine of
a colony sim — players defend what they love. Each update also carries a small
slice of the presentation backlog (font → portraits → autotile → water → music).

## Non-goals — never build (moved from guesses to promises)

- Multiplayer, z-levels, naval anything, multiple home maps
- Playing ON the world map (it stays a screen: UI + data + events)
- Children/aging simulation (refugees and recruits grow the village; marriages
  are bonds, not breeding mechanics — tone and scope both say no)
- Organ-level medical, hit locations, gore of any kind
- Fire-spread simulation, fluid/water physics, real-time lighting engine
- Spell crafting from raw materials (shard *assembly* of known relics is the ceiling)
- Procedural dialogue/quest-text generation (every event is authored)

## Guardrails (how this stays buildable by two of us)

1. Every new system = a data catalog + save/load + at most one new screen.
2. If a feature needs a new autoload, the design is wrong — decompose it.
3. Combat stays three numbers. Diplomacy stays two numbers. Complexity lives
   in *content*, not in *simulation depth*.
4. Each update must be fun if it's the last one ever shipped.
5. The tone rule outranks every feature: warm hearth, dark world, no gore,
   tragedy told, never shown.
