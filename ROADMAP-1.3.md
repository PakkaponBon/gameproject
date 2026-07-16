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

## Phase S2 — Traps ✓
- [x] Spike Pit (tile 20): block_villagers + NOT block_enemies — the gate
      trick in reverse. Raiders stepping on take 20 damage; 3 uses, then it
      destroys itself through the normal building_destroyed path. Uses are
      saved (trap_uses), so spent spikes stay spent.
- [x] Alarm Bell (tile 21): rings once per raid (horn + clickable feed
      alert) when a raider comes within radius 10.
- [x] Destroyed-building message is now def-aware ("The Gate is destroyed!")
      instead of hardcoded to gates.

## Phase S3 — Faces of the Realm ✓
- [x] Named leaders with a quirk each (data in FactionDefs): Varga Redmark,
      Lord Alden Vale, Mother Fern, Thane Borvik, the Cindermarked. Shown on
      the world-map detail panel; envoy/alliance/conquest lines name them.
- [x] Gift preferences: each leader prizes one good (sword / wool / ingots /
      ale) — gifting it earns +25 attitude and a chronicle line, giving the
      production chains political weight. Falls back to the wood gift.

## Phase S4 — Oaths & Wars ✓
- [x] Faction wars: ~daily chance two open factions skirmish; both bleed
      strength (loser more), floored at 5 — wars soften the realm but the
      killing blow (or friendship) stays the player's. Feed-only news.
- [x] Oath of kinship: a faction at attitude ≥ 50 may propose a marriage
      bond (choice event, names a real villager). Accept: they leave, the
      faction gets a permanent attitude floor of 40 and answers big raids
      like an ally; (KIN) marker + detail line on the map; chronicle keeps
      their name. Decline: -5 attitude. Tone: told, never shown.
- [x] "oath" rides inside the saved factions dict — no version bump.

## Phase S5 — Ship it
- [x] Save additions verified additive on v25 (trap_uses, oath key, armor).
- [x] Hints: loom/armor after the first raid, spike pits after the second.
- [ ] DoD (human): play through a big raid in full armor behind traps,
      watch two factions skirmish, swear one oath. Then tag v1.3.
