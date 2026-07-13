class_name UiTheme
extends RefCounted
## One dark-fantasy theme for the whole UI, built in code (all UI is
## code-built, so the theme is too). Rounded translucent panels, warm
## gold accents, shadowed text — applied once from main / main menu.

const INK := Color(0.93, 0.92, 0.95)
const INK_DIM := Color(0.62, 0.6, 0.68)
const GOLD := Color(0.95, 0.82, 0.5)
const PANEL_BG := Color(0.09, 0.085, 0.12, 0.92)
const EDGE := Color(0.45, 0.38, 0.26, 0.8)

static var _cached: Theme = null

static func get_theme() -> Theme:
	if _cached != null:
		return _cached
	var theme := Theme.new()
	theme.default_font_size = 14
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL_BG, EDGE, 6, 8))
	# Typography hierarchy — assign via label.theme_type_variation.
	theme.set_type_variation("Title", "Label")
	theme.set_font_size("font_size", "Title", 17)
	theme.set_color("font_color", "Title", Color(0.97, 0.93, 0.82))
	theme.set_constant("outline_size", "Title", 2)  # same-color outline = bold
	theme.set_color("font_outline_color", "Title", Color(0.97, 0.93, 0.82, 0.35))
	theme.set_type_variation("Header", "Label")  # small-caps section labels
	theme.set_font_size("font_size", "Header", 11)
	theme.set_color("font_color", "Header", INK_DIM)
	theme.set_type_variation("Muted", "Label")
	theme.set_font_size("font_size", "Muted", 12)
	theme.set_color("font_color", "Muted", INK_DIM)
	# Thin bronze rule between card sections.
	var line := StyleBoxLine.new()
	line.color = Color(EDGE.r, EDGE.g, EDGE.b, 0.45)
	theme.set_stylebox("separator", "HSeparator", line)
	# Slim corner strips (resources, clock, toolbar): same look, tighter.
	var slim := _box(PANEL_BG, EDGE, 6, 6)
	slim.content_margin_top = 4.0
	slim.content_margin_bottom = 4.0
	theme.set_type_variation("SlimPanel", "PanelContainer")
	theme.set_stylebox("panel", "SlimPanel", slim)
	# Buttons: flat dark, gold on hover, sunken when pressed.
	theme.set_stylebox("normal", "Button",
			_box(Color(0.16, 0.15, 0.2, 0.95), Color(0.34, 0.3, 0.24), 4, 5))
	theme.set_stylebox("hover", "Button",
			_box(Color(0.23, 0.21, 0.27, 0.98), GOLD, 4, 5))
	theme.set_stylebox("pressed", "Button",
			_box(Color(0.11, 0.1, 0.14, 0.98), GOLD, 4, 5))
	theme.set_stylebox("disabled", "Button",
			_box(Color(0.13, 0.12, 0.16, 0.6), Color(0.3, 0.28, 0.26, 0.4), 4, 5))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", INK_DIM)
	# Progress bars: thin fully-rounded pill, light fill (callers tint
	# via modulate). Pair with an 8px bar height.
	theme.set_stylebox("background", "ProgressBar",
			_box(Color(0.05, 0.05, 0.07, 0.9), Color(0, 0, 0, 0.5), 4, 1))
	theme.set_stylebox("fill", "ProgressBar",
			_box(Color(0.88, 0.88, 0.9), Color(1, 1, 1, 0.25), 4, 1))
	# Labels: soft shadow so text reads over terrain without a backdrop.
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	# Tooltips: opaque so they read over anything.
	theme.set_stylebox("panel", "TooltipPanel",
			_box(Color(0.09, 0.085, 0.12, 0.98), EDGE, 4, 6))
	theme.set_color("font_color", "TooltipLabel", INK)
	_cached = theme
	return theme

## Apply the theme to every UI layer under `root` (each CanvasLayer's
## top-level Controls; it propagates to their children from there).
static func apply_to_layers(root: Node) -> void:
	for layer in root.get_children():
		if layer is CanvasLayer:
			for control in layer.get_children():
				if control is Control:
					(control as Control).theme = get_theme()

## Icon-only button: pixel-art atlas icon + tooltip; the icon brightens
## on hover and dims on press (on top of the stylebox states).
static func icon_button(sheet: Texture2D, region: Rect2, tint: Color, tip: String,
		size := Vector2(38, 32)) -> Button:
	var btn := Button.new()
	btn.tooltip_text = tip
	btn.custom_minimum_size = size
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	icon.texture = atlas
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = tint
	btn.add_child(icon)
	btn.mouse_entered.connect(func() -> void: icon.modulate = tint.lightened(0.3))
	btn.mouse_exited.connect(func() -> void: icon.modulate = tint)
	btn.button_down.connect(func() -> void: icon.modulate = tint.darkened(0.15))
	btn.button_up.connect(func() -> void:
		icon.modulate = tint.lightened(0.3) if btn.is_hovered() else tint)
	return btn

static func _box(bg: Color, edge: Color, radius: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box
