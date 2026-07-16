# ROADMAP-1.3.md — Steel & Oath

> Slice of VISION.md ("v1.3 Steel & Oath — deepen the realm"). Same rules:
> one phase at a time, DoD gate, everything ships with save/load, tone rule
> always. This update also pays the debts v1.2 deferred here: sheep/wool
> and hide/leather, because they feed the armor ladder.

## Phase S1 — The Armor Ladder  *(materials + gear slot)* ✓
- [x] Sheep as a second livestock kind + Pasture building (tile 18); sheep
      grow wool on a timer (Balance.WOOL_DAYS).
- [x] Hunting also drops hide sometimes (Balance.HIDE_CHANCE).
- [x] Loom building (tile 19, workstation): 2 wool → padded coat, 2 hide →
      leather jerkin. Forge: 3 ingots → iron mail. No intermediate
      cloth/leather resources — recipes take the raw material straight.
- [x] Armor slot beside the weapon: ARMOR claim job (upgrade-only — a pawn
      only takes armor better than what it wears; swaps drop the old piece),
      value flows into existing damage math, shown on the card, dropped on
      death, survives expeditions, saved. SAVE_VERSION → 25.

## Phase S2 — Traps
- [ ] Spike pit: enemies stepping on it take damage; breaks after a few
      triggers. Villagers path around it automatically.
- [ ] Alarm bell: rings (horn + feed alert) when a raider comes near — the
      early-warning building for players who missed the scout line.

## Phase S3 — Faces of the Realm
- [ ] Named faction leaders with a quirk each (data in FactionDefs), shown
      on the world-map detail panel; envoy/gift lines mention them.
- [ ] Leader gift preferences sharpen the personality math.

## Phase S4 — Oaths & Wars
- [ ] Faction wars: neighbors skirmish over time; strengths drift against
      each other; feed lines report the realm moving on its own.
- [ ] Oath of kinship: marry a villager into a faction (choice event) —
      you lose the villager, gain a permanent attitude floor + their aid
      in big raids. A real cost for a real bond. Tone: text, warm, brief.

## Phase S5 — Ship it
- [ ] Save bump verified end-to-end; hints for armor/traps.
- [ ] DoD (human): play through a big raid in full armor behind traps,
      watch two factions skirmish, swear one oath. Then tag v1.3.
