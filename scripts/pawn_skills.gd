class_name PawnSkills
extends Node
## Skill XP for one pawn. Generic by design: melee levels here now;
## farming/crafting/archery reuse it in later phases. Levels are derived
## from XP, so only the xp dict needs saving.

const XP_PER_LEVEL := 100.0
const MAX_LEVEL := 10

var xp := {}  # skill id -> accumulated xp

func level(id: String) -> int:
	return clampi(int(float(xp.get(id, 0.0)) / XP_PER_LEVEL), 0, MAX_LEVEL)

func gain(id: String, amount: float) -> void:
	xp[id] = float(xp.get(id, 0.0)) + amount
