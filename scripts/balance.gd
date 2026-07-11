class_name Balance
extends RefCounted
## Difficulty settings — data multipliers only, per the roadmap.

static var hard := false

static func enemy_hp_mult() -> float:
	return 1.3 if hard else 1.0

static func enemy_damage_mult() -> float:
	return 1.25 if hard else 1.0
