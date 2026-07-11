class_name Job
extends RefCounted
## One unit of work at a grid cell. Emits `completed` when a pawn finishes it.

signal completed

enum Type { CHOP, HAUL, BUILD, SUPPLY, DECONSTRUCT, PLANT, HARVEST, FEED, MINE, EQUIP, CRAFT }  # SUPPLY = haul material to a site; FEED = bring food to a collapsed pawn; EQUIP = claim a weapon

var resource_id := ""  # SUPPLY: which material this delivery is for

var type: Type = Type.CHOP
var cell: Vector2i
var work_ticks: int
var target: Node = null  # entity or manager the job belongs to
var reserved: bool = false
