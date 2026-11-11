extends Node2D
class_name EnemyWord

# EnemyWord - Inimigo com coloração temática por fase, suporte a escala e barra de vida proporcional

signal word_completed(enemy: EnemyWord)
signal reached_bottom(enemy: EnemyWord)

@export var fall_speed: float = 65.0

var full_word: String = ""
var category_tag: String = "BASE"
var typed_index: int = 0
var is_targeted: bool = false
var is_active: bool = true
var bottom_limit_y: float = 640.0
var enemy_tint_color: Color = Color.WHITE
var cannon_side: String = ""

@onready var label: RichTextLabel = $Container/RichTextLabel if has_node("Container/RichTextLabel") else null
@onready var panel: PanelContainer = $Container/PanelContainer if has_node("Container/PanelContainer") else null
@onready var reticle: Sprite2D = $Reticle if has_node("Reticle") else null
@onready var pod_sprite: Sprite2D = $PodSprite if has_node("PodSprite") else null
@onready var container: Node2D = $Container if has_node("Container") else null
@onready var health_bar: ProgressBar = $Container/HealthBar if has_node("Container/HealthBar") else null
@onready var tag_label: Label = $Container/TagLabel if has_node("Container/TagLabel") else null

var initial_scale: Vector2 = Vector2.ONE

func _ensure_nodes() -> void:
	if label == null and has_node("Container/RichTextLabel"):
		label = $Container/RichTextLabel
	if panel == null and has_node("Container/PanelContainer"):
		panel = $Container/PanelContainer
	if reticle == null and has_node("Reticle"):
		reticle = $Reticle
	if pod_sprite == null and has_node("PodSprite"):
		pod_sprite = $PodSprite
	if container == null and has_node("Container"):
		container = $Container
	if health_bar == null and has_node("Container/HealthBar"):
		health_bar = $Container/HealthBar
	if tag_label == null and has_node("Container/TagLabel"):
		tag_label = $Container/TagLabel

func _ready() -> void:
	_ensure_nodes()
	if container:
		initial_scale = container.scale
	if reticle:
		reticle.visible = false
	_apply_visual_styling()
	_update_text_display()
	_update_health_bar()

func setup(word_str: String, speed: float, spawn_pos: Vector2, target_limit_y: float = 640.0, tag: String = "BASE", tint_col: Color = Color.WHITE, scale_mult: float = 1.0, side: String = "") -> void:
	_ensure_nodes()
	full_word = word_str.to_upper()
	category_tag = tag
	cannon_side = side
	typed_index = 0
	fall_speed = speed
	global_position = spawn_pos
	bottom_limit_y = target_limit_y
	enemy_tint_color = tint_col
	
	if scale_mult != 1.0:
		scale = Vector2(scale_mult, scale_mult)
		
	_apply_visual_styling()
	_update_text_display()
	_update_health_bar()
	if tag_label:
		tag_label.text = category_tag

func _apply_visual_styling() -> void:
	if cannon_side.length() > 0:
		# Alvos de artilharia do Chefe: Ocultar nave alienígena para não ser um inimigo menor
		if pod_sprite:
			pod_sprite.visible = false
		if health_bar:
			health_bar.visible = false
		if tag_label:
			match cannon_side:
				"left":
					tag_label.text = "🎯 ARTILHARIA ESQ"
					tag_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
				"right":
					tag_label.text = "🎯 ARTILHARIA DIR"
					tag_label.add_theme_color_override("font_color", Color(0.9, 0.4, 1.0))
				"core":
					tag_label.text = "🎯 ALVO NÚCLEO"
					tag_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		if pod_sprite:
			pod_sprite.visible = true
			if enemy_tint_color != Color.WHITE:
				pod_sprite.modulate = enemy_tint_color
		if tag_label and enemy_tint_color != Color.WHITE:
			tag_label.add_theme_color_override("font_color", enemy_tint_color.lightened(0.2))

func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	if reticle:
		reticle.visible = targeted
		if targeted:
			var tween := create_tween().set_loops()
			tween.tween_property(reticle, "rotation", TAU, 3.0).as_relative()
	_update_text_display()

func get_first_letter() -> String:
	if full_word.length() > 0:
		return full_word.substr(0, 1)
	return ""

func get_next_letter() -> String:
	if typed_index < full_word.length():
		return full_word.substr(typed_index, 1)
	return ""

func is_completed() -> bool:
	return typed_index >= full_word.length()

func on_correct_letter() -> void:
	typed_index += 1
	_update_text_display()
	_update_health_bar()
	
	if container and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(container, "scale", initial_scale * 1.18, 0.05).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(container, "scale", initial_scale, 0.08).set_trans(Tween.TRANS_QUAD)
	
	if is_completed():
		word_completed.emit(self)

func on_wrong_letter() -> void:
	if container and is_inside_tree():
		var tween := create_tween()
		var orig_pos: Vector2 = container.position
		tween.tween_property(container, "position", orig_pos + Vector2(7, 0), 0.03)
		tween.tween_property(container, "position", orig_pos - Vector2(7, 0), 0.03)
		tween.tween_property(container, "position", orig_pos + Vector2(4, 0), 0.03)
		tween.tween_property(container, "position", orig_pos, 0.03)
	
	if panel and is_inside_tree():
		var color_tween := create_tween()
		color_tween.tween_property(panel, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.04)
		color_tween.tween_property(panel, "modulate", Color.WHITE, 0.12)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	global_position.y += fall_speed * delta
	
	if global_position.y >= bottom_limit_y - 120.0:
		var pulse: float = (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.5
		modulate = Color(1.0, 0.4 + pulse * 0.6, 0.4 + pulse * 0.6)
	
	if global_position.y >= bottom_limit_y:
		reached_bottom.emit(self)

func _update_health_bar() -> void:
	if health_bar:
		var total_hp: float = float(maxi(1, full_word.length()))
		var current_hp: float = float(maxi(0, full_word.length() - typed_index))
		health_bar.max_value = total_hp
		health_bar.value = current_hp

func _update_text_display() -> void:
	if not label:
		return
		
	var typed_part: String = full_word.substr(0, typed_index)
	var next_char: String = ""
	var remaining_part: String = ""
	
	if typed_index < full_word.length():
		next_char = full_word.substr(typed_index, 1)
		remaining_part = full_word.substr(typed_index + 1)
	
	var bbcode: String = "[center]"
	if typed_part.length() > 0:
		bbcode += "[color=#22c55e][b]" + typed_part + "[/b][/color]"
		
	if next_char.length() > 0:
		if is_targeted:
			bbcode += "[color=#facc15][u][b]" + next_char + "[/b][/u][/color]"
		else:
			bbcode += "[color=#f8fafc][b]" + next_char + "[/b][/color]"
			
	if remaining_part.length() > 0:
		bbcode += "[color=#94a3b8]" + remaining_part + "[/color]"
		
	bbcode += "[/center]"
	label.text = bbcode
	
	if tag_label:
		tag_label.text = category_tag

func stop() -> void:
	is_active = false
