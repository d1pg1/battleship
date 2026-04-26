class_name ButtonStyle
extends RefCounted

const ACTIVE_TEX := preload("res://assets/active-button.png")
const INACTIVE_TEX := preload("res://assets/inactive-button.png")
const ACTIVE_REGION := Rect2(95, 302, 1351, 335)
const INACTIVE_REGION := Rect2(94, 317, 1350, 336)
const TEXT_COLOR := Color(0.92, 0.96, 1.0, 1.0)
const ACTIVE_TEXT_COLOR := Color(1.0, 0.9, 0.36, 1.0)
const PRESSED_TEXT_COLOR := Color(1.0, 0.96, 0.76, 1.0)

static func apply(button: Button, font_size: int = 24, min_height: int = 58) -> void:
	button.custom_minimum_size.y = min_height
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", ACTIVE_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", PRESSED_TEXT_COLOR)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_stylebox_override("normal", _make_style(INACTIVE_TEX, INACTIVE_REGION))
	button.add_theme_stylebox_override("hover", _make_style(ACTIVE_TEX, ACTIVE_REGION))
	button.add_theme_stylebox_override("focus", _make_style(INACTIVE_TEX, INACTIVE_REGION))
	button.add_theme_stylebox_override("pressed", _make_style(ACTIVE_TEX, ACTIVE_REGION))
	button.add_theme_stylebox_override("disabled", _make_style(INACTIVE_TEX, INACTIVE_REGION, Color(0.55, 0.58, 0.62, 0.7)))

static func apply_all(root: Node, font_size: int = 24, min_height: int = 58) -> void:
	for child in root.get_children():
		if child is Button:
			apply(child, font_size, min_height)
		apply_all(child, font_size, min_height)

static func _make_style(texture: Texture2D, region: Rect2, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.region_rect = region
	style.texture_margin_left = 36.0
	style.texture_margin_top = 28.0
	style.texture_margin_right = 36.0
	style.texture_margin_bottom = 28.0
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	style.modulate_color = modulate
	return style
