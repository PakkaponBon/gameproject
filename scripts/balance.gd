class_name Balance
extends RefCounted
## Difficulty settings — data multipliers only, per the roadmap.
## Peaceful: no raids at all. Hard: tougher, harder-hitting enemies.

const MODES := ["Peaceful", "Normal", "Hard"]

# --- food security (anti death-spiral tuning) ---
const START_FOOD := 25          # wild berry bushes at mapgen, each bearing food
const BERRY_REGROW_DAYS := 5.0  # a picked bush bears food again after this
const TURNIP_GROW_DAYS := 1.0   # starter crop: harvest lands before hunger does
const TURNIP_YIELD := 2

static var mode := "Normal"

static func peaceful() -> bool:
	return mode == "Peaceful"

static func enemy_hp_mult() -> float:
	return 1.3 if mode == "Hard" else 1.0

static func enemy_damage_mult() -> float:
	return 1.25 if mode == "Hard" else 1.0
