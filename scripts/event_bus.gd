extends Node
## Autoload: global signal hub. Systems emit here so emitters don't need
## references to listeners. New cross-system signals go here, not point-to-point.

signal building_built(cell: Vector2i, building_id: String)
