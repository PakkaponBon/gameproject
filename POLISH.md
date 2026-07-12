# POLISH.md — Phases 12–15 (v1.0 → "good")

Follows ROADMAP.md conventions: one phase at a time, DoD gate before next,
IDEAS.md quarantine still applies. NO new gameplay systems in these phases —
polish only. New system ideas go to IDEAS.md.

**Exit criteria for this whole doc ("good"):** a fresh tester plays 30 minutes
without asking the dev a question, loses a pawn, and wants to continue.
Achieved twice with different testers → ready for itch.io.

---

## Phase 12 — Juice & Game Feel
Make every action FELT. No art changes yet — feedback layer only.

- [x] Hit feedback: white flash on damaged entity + floating damage number
- [x] Death feedback: pawn death pause-frame + sound + ~~blood~~ ash-mark decal
      *(tone rule: no gore — GAME_DESIGN.md)*
- [x] Work particles: wood chips (chop), stone dust (mine), soil puff (farm)
- [x] Item pickup/drop: small bounce/arc animation, not teleport
- [x] Pawn movement: 2-frame walk cycle minimum, face movement direction
- [x] Sound pass v0: chop, mine, build hammer, eat, footsteps (soft), sword hit,
      bow release, pawn hurt, pawn death, raid horn, UI clicks
      *(synthesized placeholder WAVs, not downloads; SoundManager autoload, pitch ±10%)*
- [x] Ambient loop: birds at day, crickets at night *(no separate wind layer)*
- [x] Day/night visual tint via CanvasModulate (dawn gold → day → dusk orange → night blue)
- [x] Raid feel: warning horn + 1s screen shake on raid spawn, red edge-of-screen
      indicator pointing at spawn direction
- [x] Selection feedback: pawn selected = outline/ring + soft click sound

**DoD:** capture a 60s gameplay clip. Chopping, a raid arriving, and a fight
must be readable and satisfying with sound ON, watching with no explanation.

---

## Phase 13 — Art Pass (ART_DIRECTION.md now binding)
Replace placeholders. Incremental: tiles → pawns → buildings → decor.

- [ ] Terrain tileset: grass/dirt/stone/water with autotile transitions *(borderless texture done; true autotile + water = human art pass)*
- [x] Decor density pass: 260 scattered props at mapgen (seeded, survives loads)
- [x] Landmark props: great tree, standing stone, ruin marker per map (seeded)
- [x] Y-sorting: entities (pawns, trees, props) y-sorted — pawns walk behind trees
- [ ] Water animation *(no water terrain yet — needs the human tileset pass)*
- [ ] Palette lock in ART_DIRECTION.md *(design decision — yours)*
- [x] Grass variants (covered by decor density pass above)
- [x] Tree/rock sprites: variants + gentle tree sway
- [x] Pawn sprites: 16×16 characters, walk animation, ~~work animation~~,
      carried-item shown when hauling, weapon visible in hand *(work anim = human art)*
- [x] Enemy sprites: hooded silhouette, distinct at a glance
- [ ] Building autotile walls / door open-close states *(readable tiles done; autotile = human art)*
- [x] Crop growth stages: sprout → fruiting sprite + continuous scale
- [x] Ambient critters: rabbits and birds wandering — life, not systems
- [x] Lighting v0: forge/stove glow (PointLight2D)
- [ ] Map edges: fade/border so world doesn't end in a hard line

Source: free packs first (Kenney, itch.io 16×16 — search "16x16 fantasy tileset",
Sprout Lands / Cup Nooble style matches the reference look; check licenses,
credit file), replace with custom art incrementally. Do NOT hand-draw everything
before testing.

**DoD:** side-by-side screenshot old vs new posted somewhere public (devlog).
A stranger can identify: villager vs enemy, each building's purpose, crop maturity —
without labels.

---

## Phase 14 — UI Rework
The panel works; now make it a game UI. Colony sims are READ through UI —
this is gameplay, not chrome.

- [x] Resource bar: icons + numbers (no text labels), tooltip on hover with detail
- [x] Pawn card redesign: trait names with tooltip lore text, needs bars,
      current-job line *(portrait area awaits human portraits)*
- [x] Pawn list (bottom): flash red on hunger/injury, click = select + center camera
- [x] Priorities screen [P]: proper grid (pawns × jobs), click-cycle numbers
- [x] Build/zone menus: icon buttons with cost tooltips, invalid placement = red
      ghost + reason line
- [x] Notifications: event log feed (right side) — death/gate entries click = jump camera
- [x] Tooltips everywhere: icons, buttons, traits, world-map actions
- [x] Pause/speed UI: visible buttons + current speed indicator
- [ ] Font: single readable pixel font, Thai glyph check *(needs a font asset — human pick)*
- [x] Escape menu: settings (volume, fullscreen), save/load, quit

**DoD:** you play one full in-game day using ONLY the mouse and UI (no memorized
hotkeys, no debug keys). Everything discoverable.

---

## Phase 15 — First 10 Minutes & Balance
Testers bounce in minute 3 if confused. This phase decides everything.

- [x] Intro event: Fall of Vhal — 4 text panels, skippable, sets tone + goal
- [x] Starting scenario tuned: 3 pawns, wood/stone/iron guaranteed near spawn
- [x] Soft tutorial: 6 contextual hints (field, beds, walls, draft, herbs, forge),
      each once, never modal (ride the notification feed)
- [x] Objective nudges v0: FIRST STEPS checklist (3 beds → 10 food → survive
      first raid), hides when complete
- [x] First raid timing: guaranteed 2 bandits at end of day 2
- [x] Difficulty settings: Peaceful / Normal / Hard
- [ ] Balance from self-play: 3 full runs to Year 2 *(human — play and log)*
- [ ] Performance check: 15 pawns + raid + full base at stable 60fps *(human — profile in editor)*
- [x] Crash/save hardening: autosave each morning; corrupted/incomplete saves
      rejected with an error, never a crash *(mid-raid save/load verify = human run)*

**DoD — THE GATE:** 2 different fresh testers (friends, closed test, not public):
each plays 30 min with zero questions answered, loses ≥1 pawn, and asks to keep
playing. Both pass → STOP POLISHING. Go to itch.io release (see release plan).

---

## Anti-loop rules (read when tempted to keep polishing)
1. Each phase gets ONE pass. Imperfect but DoD-passing = done. Second passes
   only after external feedback demands them.
2. "Until it's good" = the Phase 15 gate, nothing else. Passing the gate and
   still not releasing = fear, not quality control.
3. Time cap: if any phase exceeds 3 weeks, cut scope to meet DoD and move on.
4. No new systems. The moment "what if we add..." appears → IDEAS.md, close file.
