class_name Job
extends RefCounted
## One unit of work at a grid cell. Emits `completed` when a pawn finishes it.

signal completed

enum Type { CHOP, HAUL, BUILD, SUPPLY }  # SUPPLY = haul material to a blueprint

var type: Type = Type.CHOP
var cell: Vector2i
var work_ticks: int
var target: Node2D = null
var reserved: bool = false
