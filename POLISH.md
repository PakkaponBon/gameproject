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
- [x] Death feedback: pawn death pause-frame + sound + ~~blood~~ **ash decal** *(tone rule: no gore per GAME_DESIGN)*
- [x] Work particles: wood chips (chop), stone dust (mine), soil puff (farm)
- [x] Item pickup/drop: small bounce/arc animation, not teleport
- [x] Pawn movement: 2-frame walk cycle minimum, face movement direction
- [x] Sound pass v0: chop, mine, build hammer, eat, footsteps (soft), sword hit,
      bow release, pawn hurt, pawn death, raid horn, UI clicks
      *(synthesized procedurally, not downloaded; SoundManager autoload, pitch ±10%)*
- [x] Ambient loop: birds at day, crickets at night, wind
- [x] Day/night visual tint via CanvasModulate (dawn gold → day → dusk orange → night blue)
- [x] Raid feel: warning horn + 1s screen shake on raid spawn, red edge-of-screen
      indicator pointing at spawn direction
- [x] Selection feedback: pawn selected = outline/ring + soft click sound

**DoD:** capture a 60s gameplay clip. Chopping, a raid arriving, and a fight
must be readable and satisfying with sound ON, watching with no explanation.

---

## Phase 13 — Art Pass (ART_DIRECTION.md now binding)
Replace placeholders. Incremental: tiles → pawns → buildings → decor.

- [ ] Terrain tileset: grass/dirt/stone/water with autotile transitions
      (no more hard rectangles between terrain types)
- [ ] Grass variants + decor scatter: flowers, pebbles, bushes, mushrooms —
      procedural scatter at mapgen. Kills the "empty green field" look
- [ ] Tree/rock sprites: 2–3 variants each; trees sway slightly (shader or tween)
- [ ] Pawn sprites: real 16×16 characters, walk animation, work animation,
      carried-item shown when hauling, weapon visible when armed/drafted
- [ ] Enemy sprites: visually distinct from villagers at a glance (silhouette test)
- [ ] Building sprites: wall connects to neighbors (autotile), door open/close
      states, bed/forge/campfire readable at a glance; campfire animated + light
- [ ] Crop growth stages: 3–4 sprites per crop, visibly different
- [ ] Ambient critters: 1–2 harmless (rabbit, bird) wandering — life, not systems
- [ ] Lighting v0: campfire/torch glow at night (PointLight2D)
- [ ] Map edges: fade/border so world doesn't end in a hard line

Source: free packs first (Kenney, itch.io 16×16 — check licenses, credit file),
replace with custom art incrementally. Do NOT hand-draw everything before testing.

**DoD:** side-by-side screenshot old vs new posted somewhere public (devlog).
A stranger can identify: villager vs enemy, each building's purpose, crop maturity —
without labels.

---

## Phase 14 — UI Rework
The panel works; now make it a game UI. Colony sims are READ through UI —
this is gameplay, not chrome.

- [ ] Resource bar: icons + numbers (no text labels), tooltip on hover with detail
- [ ] Pawn card redesign: portrait area, trait icons with tooltip lore text,
      needs bars with icons, current-job line with progress
- [ ] Pawn list (bottom): mini needs/mood indicator per pawn, flash red on
      hunger/injury, click = select + center camera
- [ ] Priorities screen [P]: proper grid (pawns × jobs), click-cycle numbers,
      readable at a glance
- [ ] Build/zone menus: icon buttons with cost display, invalid placement = red
      ghost + reason ("needs wall support", "not enough wood")
- [ ] Notifications: event log feed (right side, RimWorld-style) — raid, death,
      starvation, crop ready, construction done. Click = jump camera
- [ ] Tooltips everywhere: every icon, every button, every bar
- [ ] Pause/speed UI: visible buttons + current speed indicator (already keyboard)
- [ ] Font: single readable pixel font, consistent sizes; Thai glyph support
      check if UI language will ever be Thai
- [ ] Escape menu: settings (volume sliders, resolution/fullscreen), save/load, quit

**DoD:** you play one full in-game day using ONLY the mouse and UI (no memorized
hotkeys, no debug keys). Everything discoverable.

---

## Phase 15 — First 10 Minutes & Balance
Testers bounce in minute 3 if confused. This phase decides everything.

- [ ] Intro event: Fall of Vhal — 3–5 short text/image panels (lore doc has copy),
      skippable, sets tone + goal
- [ ] Starting scenario tuned: 3 pawns, minimal supplies, map guaranteed to have
      wood/stone/water near spawn (mapgen constraint)
- [ ] Soft tutorial: contextual hint popups, max 6 total
      ("Villagers are hungry — zone a field [F]"), each dismissible, never modal
- [ ] Objective nudges v0: early renown goals as visible checklist
      (build 3 beds → stock 10 food → survive first raid) — teaches the loop
      without hard tutorial
- [ ] First raid timing: guaranteed small (1–2 bandits) at end of day 2 —
      early taste of danger, survivable unarmed
- [ ] Difficulty settings: Peaceful / Normal / Hard (raid scale multiplier only)
- [ ] Balance from self-play: 3 full runs to Year 2. Log every boring/confusing
      moment. Fix top 5. Repeat until a run has no note-worthy dead spots
- [ ] Performance check: 15 pawns + raid + full base at stable 60fps
      (profile; usual suspects: pathfinding storms, per-frame job scans)
- [ ] Crash/save hardening: save mid-raid, load, verify identical state;
      autosave each morning; corrupted-save handling (don't crash to desktop)

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
