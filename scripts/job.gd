class_name Job
extends RefCounted
## One unit of work at a grid cell. Emits `completed` when a pawn finishes it.

signal completed

enum Type { CHOP, HAUL, BUILD, SUPPLY, DECONSTRUCT, PLANT, HARVEST }  # SUPPLY = haul material to a blueprint

var type: Type = Type.CHOP
var cell: Vector2i
var work_ticks: int
var target: Node = null  # entity or manager the job belongs to
var reserved: bool = false
