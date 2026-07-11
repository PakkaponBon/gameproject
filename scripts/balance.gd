class_name Balance
extends RefCounted
## Difficulty settings — data multipliers only, per the roadmap.
## Peaceful: no raids at all. Hard: tougher, harder-hitting enemies.

const MODES := ["Peaceful", "Normal", "Hard"]

static var mode := "Normal"

static func peaceful() -> bool:
	return mode == "Peaceful"

static func enemy_hp_mult() -> float:
	return 1.3 if mode == "Hard" else 1.0

static func enemy_damage_mult() -> float:
	return 1.25 if mode == "Hard" else 1.0
