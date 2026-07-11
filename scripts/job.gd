class_name Job
extends RefCounted
## One unit of work at a grid cell. Emits `completed` when a pawn finishes it.

signal completed

enum Type { CHOP, HAUL, BUILD, SUPPLY, DECONSTRUCT, PLANT, HARVEST, FEED, MINE, EQUIP, CRAFT, AMMO, RELIC, TREAT }  # SUPPLY = haul to a site; FEED/TREAT = bring food/herbs to a downed/wounded pawn; EQUIP/AMMO/RELIC = claim gear

var resource_id := ""  # SUPPLY: which material this delivery is for

var type: Type = Type.CHOP
var cell: Vector2i
var work_ticks: int
var target: Node = null  # entity or manager the job belongs to
var reserved: bool = false
