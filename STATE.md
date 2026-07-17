# STATE.md — Session Handoff (read me first, before touching code)

> Dense resume file for Claude Code. Updated at the end of each work burst.
> CLAUDE.md = rules; VISION.md = the full game; this file = *where we are*.
> Last updated: 2026-07-16, after v1.4 code-complete.

## Position

| Update | Status | Tag |
|---|---|---|
| v1.0 (ROADMAP.md 1–11 + POLISH.md 12–15) | done | v0.75-playable |
| v1.1 Hearth & Home (ROADMAP-1.1.md) | done | (inside later tags) |
| v1.2 Field & Flock (ROADMAP-1.2.md) | done | v1.2-field-flock |
| v1.3 Steel & Oath (ROADMAP-1.3.md) | done | v1.3-steel-oath |
| v1.4 The Wilds (ROADMAP-1.4.md) | **code-complete, untagged** — human DoD pending | — |
| v2.0 The Long Night (ROADMAP-2.0.md) | **N1+N2 built** (siege + 3 endings); N3 scenarios / N4 music+DoD remain | — |

The Long Night: trigger = the four non-Legion factions resolved while the Ashen Legion
stands → FactionManager.long_night_begins → LongNightDirector (DORMANT→WARNING→WAVE↔LULL→WON)
runs a 4-wave siege via raid_director.spawn_legion_wave (siege_active suspends normal raids
+ events). Survive → break_the_legion → realm_ruled. Endings in main._on_realm_ruled: all-allied
= Long Peace, siege-survived = Vhal Reclaimed (true, 2-page), else Ruler of the Realm. Siege
state saved additively (siege{phase,wave,timer} + faction long_night bool).

- **SAVE_VERSION = 25** (history: 21 bushes, 22 warmth/joy/bonds/chronicle,
  23 food kinds, 24 livestock, 25 armor; trap_uses / sites / oath /
  beast-elite flags / expedition supplies / weather ride additively via get()).
- Repo: https://github.com/PakkaponBon/gameproject.git — push after every commit.
- Human-side debt: v1.4 DoD playtest; POLISH.md two-tester gate;
  v1.1/v1.2/v1.3 DoD playtests were skipped by owner's choice.

## What each update added (one line each)
- v1.1: rooms/warmth/joy needs, furniture comfort, bonds+grief, 3 festivals, chronicle (C).
- v1.2: 10 crops, stew, hunting (rabbits→meat/hide), brewing (barley→ale=joy), chicken coops, weather.
- v1.3: armor ladder (wool/hide/ingots → padded/leather/mail via loom+forge, ARMOR claim job),
  spike pits + alarm bells, named faction leaders w/ prized gifts, faction wars, oath of kinship.
- v1.4: 4 wild sites (SiteDefs; cooldowns; loot tables), relic shards + shrine awakening
  (output_pool recipes), bestiary (ash-wolves winter packs, boars bite, Legion elites),
  expedition provisioning + strong/even/grim odds.
- Cross-cutting this era: Kenney CC0 art reskin (same atlas indices!), Kenney Pixel font,
  UiTheme (Title/Header/Muted/SlimPanel variations, icon_button factory), Cities-style UI
  (icon toolbar + corner clusters + collapsible villager card), world map as node map,
  procedural animation (bob/lean/lunge/breath), pacing pass (scout warnings, wealth-scaled
  raids, goal ladder, dilemma ChoicePanel events), time compression (2000 ticks/day, 4-day
  seasons), interactive tutorial (TutorialDirector, 8 do-it steps, saved, old saves skip).

## Atlas maps (indices are load-bearing — code refers to cell*16)
**tiles.png (22 cells, 352px):** 0 grass · 1 dirt · 2 wall(custom brick) · 3 gate ·
4 bedroll · 5 barn-chest · 6 forge-anvil · 7 watchtower · 8 stove-furnace · 9 door ·
10 hearth-glowpot · 11 table · 12 chair · 13 shrine-pedestal · 14 trophy-crest ·
15 brazier-torch · 16 brewery-barrel(custom) · 17 coop-hut(custom) ·
18 pasture-fence(custom) · 19 loom(custom) · 20 spike-pit(custom) · 21 alarm-bell(custom)

**sprites.png (28 cells, 448px):** 0 villager · 1 tree · 2 rock(proc) · 3 crop-sprigs ·
4 wood-logs(custom) · 5 stone-chunk(proc) · 6 ingot-disc(also wool/hide tinted) · 7 sword ·
8 bow · 9 arrow · 10 herb-flask(also ale) · 11 food-beehive · 12 relic-wand(also shard) ·
13 grave(proc) · 14 villager-walk(1px bob) · 15 bandit · 16 pine · 17 jagged-rock(proc) ·
18 mature-crop · 19 flowers · 20 pebbles · 21 berry-bush · 22 mushrooms · 23 rabbit(also
sheep/boar/wolf tinted) · 24 bird(also chicken tinted) · 25 knight-ally · 26 elder-merchant ·
27 armor-crest

**Regenerating art:** tools/*.ps1 (rescued from session scratchpad). Order if rebuilding
from Kenney zips: compose_kenney → make_brewery(16) → make_coop(17) → make_s1_art(18/19,
sprite 27) → make_s2_art(20/21). Kenney zips redownload from kenney.nl (CC0; see CREDITS.md).
GDI+ pitfall: never Save() over a file still open via FromFile — clone to a new Bitmap first.

## Architecture quick map (beyond CLAUDE.md)
- Autoloads: EventBus, GameClock (2000 ticks/day, 4-day seasons), WorldGrid (dual astar,
  rooms/warmth/comfort/traps registries), JobManager, SaveManager, FactionManager, SoundManager.
- Main's scene-local directors: WorldSpawner, RaidDirector (warnings, bells, beast packs),
  FieldKeeper, ForgeKeeper (ALL workstations, station-filtered recipes), TradeDirector,
  KitchenKeeper (meal/stew), EventsDirector (frost/refugee/bard/star/dilemmas/oath/wolves/
  game-replenish), FestivalDirector (static active_name), ChronicleDirector, WeatherDirector
  (static current), HintDirector.
- UI layers (all CanvasLayer, themed via UiTheme.apply_to_layers in main._ready):
  HUD (feed chips, clock cluster, resource strip), BuildPalette (toolbar + sub-tools),
  VillagerPanel (collapsible card), ObjectiveTracker (goal-ladder badge), WorldMap (node map),
  ChroniclePanel, ChoicePanel (pauses sim), HelpPanel (Play/Buildings/Keys tabs), TradePanel,
  PriorityGrid, RosterBar, StoryPanel, PauseMenu.
- Data catalogs: BuildingDefs (+DESC), CropDefs, ResourceDefs, WeaponDefs, RelicDefs,
  TraitDefs, RecipeDefs (station + output/output_pool), FactionDefs (leaders/likes),
  SiteDefs, Balance (all tuning knobs + static mode).
- Job.Type: CHOP HAUL BUILD SUPPLY DECONSTRUCT PLANT HARVEST FEED MINE EQUIP CRAFT AMMO
  RELIC TREAT COOK HUNT ARMOR. Priority mapping: gear/TREAT/FEED→HAUL group, HUNT/MINE→CHOP,
  HARVEST/COOK→PLANT, DECONSTRUCT/CRAFT→BUILD.

## Recurring pitfalls (cost us real crashes — check before writing code)
1. **GDScript `:=` from Variant** breaks the build (warnings-as-errors): anything through
   loosely-typed `main.`, `Dictionary.get()`, `Array.filter()` on a Variant, `pick_random()`.
   Always annotate: `var x: Array = main.pawns.filter(...)`.
2. **Typed var from a freed instance throws before is_instance_valid can run** — read dict
   entries untyped, validate, then use (save_collector crash, commit 38b6f26).
3. **PowerShell here-string commits**: no double quotes, no backticks, no `?` in the
   message — they break `git commit -m @'...'@` argument passing. Plain words only.
4. **PS hashtable keys are case-insensitive** — use digit codes in pixel palettes.
5. **`Hex 'x', Hex 'y'` in PS arrays parses as one call** — wrap each call in parens.
6. Godot editor rewrites .tscn ext_resource uids on save — expect churn; edits by string
   match may need a fresh Read after the editor touched a scene.
7. New top-level Controls added after main._ready won't be themed — parent them under an
   already-themed Control, or theme them explicitly.
8. Scene-tscn edits: bump load_steps when adding ext_resources.

## Duo-agent setup (since 2026-07-16)
- A second agent (Codex) may work the ASSETS lane only: contract in AGENTS.md,
  brief + cell authority in ASSET_SPEC.md, pipeline = assets/incoming/*.png →
  tools/import_assets.ps1. It never touches scripts/scenes/tres.
- Each session: `git pull` first (the other agent pushes too), and check
  ASSET_SPEC.md "Requests to Claude" for code-hook asks (new cells, animation
  frames, villager variants). After adding cells, update BOTH cell tables
  (here and in ASSET_SPEC.md) and the importer's max indices.

## Workflow conventions (owner: Bo, solo, tests via F5 and pastes errors)
- Per phase: build → tick mini-roadmap boxes → commit (message = what + why) → push.
- Tag per update when moving past it (v1.X-name). Leave human DoD boxes unchecked.
- Scope rules honored so far: no dead-end resources (defer materials until their chain
  exists), every new entity ships with save/load, tone rule (no gore; tragedy told not
  shown), no new autoloads, world map stays UI+data.
- Bo says "go next" to advance; flag testing debt honestly but don't stall the build.
