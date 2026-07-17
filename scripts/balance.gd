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

# --- hunting ---
const MEAT_PER_KILL := 2        # raw food dropped when a rabbit is caught
const CRITTER_TARGET := 5       # huntable game kept topped up (ambiance + renewable meat)

# --- livestock ---
const EGG_LAY_DAYS := 1.0       # a hen lays an egg (raw food) about once a day
const WOOL_DAYS := 1.5          # a sheep grows a bundle of wool this often
const HIDE_CHANCE := 0.4        # chance a hunted rabbit also yields a hide

# --- bestiary ---
const WOLF_PACK_CHANCE := 0.25  # per winter morning: ash-wolves test the walls
const BOAR_CHANCE := 0.25       # share of replenished game that is a boar
const BOAR_BITE := 10.0         # a cornered boar wounds its hunter

static var mode := "Normal"

static func peaceful() -> bool:
	return mode == "Peaceful"

static func enemy_hp_mult() -> float:
	return 1.3 if mode == "Hard" else 1.0

static func enemy_damage_mult() -> float:
	return 1.25 if mode == "Hard" else 1.0

static func raid_interval_mult() -> float:
	return 0.75 if mode == "Hard" else 1.0

## Long Night wave sizes scale with difficulty (Peaceful never sieges).
static func siege_wave_mult() -> float:
	return 1.4 if mode == "Hard" else 1.0
