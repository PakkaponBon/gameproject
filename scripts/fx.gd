class_name Fx
extends RefCounted
## One-shot juice helpers: hit flashes, floating damage numbers, particle
## bursts, item drop hops, and (tone rule: no gore) ash marks for deaths.

static func flash(sprite: CanvasItem) -> void:
	var prev := sprite.modulate
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", prev, 0.15)

static func damage_number(anchor: Node2D, amount: float) -> void:
	var holder := Node2D.new()
	holder.position = anchor.position + Vector2(0, -10)
	holder.z_index = 50
	var label := Label.new()
	label.text = str(int(round(amount)))
	label.modulate = Color(1.0, 0.85, 0.3)
	label.position = Vector2(-8, -10)
	label.scale = Vector2(0.6, 0.6)
	holder.add_child(label)
	anchor.get_parent().add_child(holder)
	var tween := holder.create_tween()
	tween.tween_property(holder, "position:y", holder.position.y - 14.0, 0.6)
	tween.parallel().tween_property(holder, "modulate:a", 0.0, 0.6)
	tween.tween_callback(holder.queue_free)

static func burst(parent: Node, world_pos: Vector2, color: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.position = world_pos
	particles.amount = 10
	particles.lifetime = 0.45
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 70.0
	particles.gravity = Vector2(0, 220)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color
	particles.emitting = true
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)

## Tiny floating glyph over an entity's head: readable inner life at a
## glance ("!" hungry, "z" sleeping, "<3" friendship).
static func emote(anchor: Node2D, text: String, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 60
	label.position = Vector2(-4, -24)
	label.scale = Vector2(0.75, 0.75)
	anchor.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 6.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(label.queue_free)

## Melee swing: the body sprite snaps toward the target and settles back.
## Sets a "lunging" meta so per-frame animators leave the offset alone.
static func lunge(body: Node2D, dir: Vector2) -> void:
	if body.has_meta("lunging"):
		return
	body.set_meta("lunging", true)
	var push := dir.normalized() * 5.0
	var tween := body.create_tween()
	tween.tween_property(body, "position", push, 0.06)
	tween.tween_property(body, "position", Vector2.ZERO, 0.14)
	tween.tween_callback(func() -> void: body.remove_meta("lunging"))

## Dropped items bounce into place instead of teleporting.
static func hop(item: Node2D) -> void:
	var rest_y := item.position.y
	item.position.y -= 6.0
	var tween := item.create_tween()
	tween.tween_property(item, "position:y", rest_y, 0.28) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

## Where someone fell: a dark ash smudge that slowly fades. No gore.
static func ash_mark(parent: Node, world_pos: Vector2) -> void:
	var mark := ColorRect.new()
	mark.color = Color(0.28, 0.25, 0.23, 0.5)
	mark.size = Vector2(10, 4)
	mark.position = world_pos + Vector2(-5, 2)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(mark)
	var tween := mark.create_tween()
	tween.tween_interval(25.0)
	tween.tween_property(mark, "modulate:a", 0.0, 5.0)
	tween.tween_callback(mark.queue_free)
