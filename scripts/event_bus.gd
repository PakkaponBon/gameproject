extends Node
## Autoload: global signal hub. Systems emit here so emitters don't need
## references to listeners. New cross-system signals go here, not point-to-point.

signal building_built(cell: Vector2i, building_id: String)
signal building_deconstructed(cell: Vector2i)
signal building_destroyed(cell: Vector2i)  # smashed by enemies: no refund
signal crop_harvested(cell: Vector2i)
signal merchant_arrived
signal merchant_left
signal play_sfx(id: String)
signal play_fx(job_type: int, cell: Vector2i)  # work-completion particles
signal chronicle_entry(text: String)  # one line for the village's story
signal raider_stole(world_pos: Vector2)  # a looter grabbed goods — chase!
signal notice(text: String, tint: Color, jump: Vector2)  # transient HUD toast from any entity
