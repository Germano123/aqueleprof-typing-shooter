extends Node2D
class_name BossDreadnought

# BossDreadnought - Encouraçado Ômega com 3 pontos vitais e escudo central invulnerável

signal vital_point_damaged(point_name: String, current_hp: int, max_hp: int)
signal cannon_destroyed(side: String)
signal shield_collapsed()
signal boss_defeated()

const MAX_CANNON_HP: int = 5
const MAX_CORE_HP: int = 5

var left_cannon_hp: int = MAX_CANNON_HP
var right_cannon_hp: int = MAX_CANNON_HP
var core_hp: int = MAX_CORE_HP

var shield_active: bool = true
var is_defeated: bool = false

@onready var left_cannon_node: Node2D = $LeftCannon if has_node("LeftCannon") else null
@onready var right_cannon_node: Node2D = $RightCannon if has_node("RightCannon") else null
@onready var core_node: Node2D = $Core if has_node("Core") else null
@onready var shield_sprite: Sprite2D = $Core/ShieldSprite if has_node("Core/ShieldSprite") else null

@onready var left_hp_bar: ProgressBar = $LeftCannon/HealthBar if has_node("LeftCannon/HealthBar") else null
@onready var right_hp_bar: ProgressBar = $RightCannon/HealthBar if has_node("RightCannon/HealthBar") else null
@onready var core_hp_bar: ProgressBar = $Core/HealthBar if has_node("Core/HealthBar") else null
@onready var core_status_label: Label = $Core/StatusLabel if has_node("Core/StatusLabel") else null

func _ready() -> void:
	reset_boss()
	_animate_idle()

func reset_boss() -> void:
	left_cannon_hp = MAX_CANNON_HP
	right_cannon_hp = MAX_CANNON_HP
	core_hp = MAX_CORE_HP
	shield_active = true
	is_defeated = false
	
	if shield_sprite:
		shield_sprite.visible = true
		shield_sprite.modulate = Color(0.2, 0.8, 1.0, 0.8)
		
	if core_status_label:
		core_status_label.text = "ESCUDO ATIVO"
		core_status_label.modulate = Color(0.3, 0.8, 1.0)
		
	_update_hp_bars()

func _animate_idle() -> void:
	# Flutuação e pulso do escudo de força
	if shield_sprite:
		var stween := create_tween().set_loops()
		stween.tween_property(shield_sprite, "scale", Vector2(1.15, 1.15), 1.2).set_trans(Tween.TRANS_SINE)
		stween.tween_property(shield_sprite, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)

func damage_vital_point(point_name: String, amount: int = 1) -> bool:
	if is_defeated:
		return false
		
	match point_name.to_lower():
		"left", "canhão esquerdo", "esq":
			if left_cannon_hp <= 0:
				return false
			left_cannon_hp = maxi(0, left_cannon_hp - amount)
			_flash_node(left_cannon_node, Color(1.5, 0.2, 0.2))
			vital_point_damaged.emit("left", left_cannon_hp, MAX_CANNON_HP)
			if left_cannon_hp == 0:
				_play_sfx("explosion")
				cannon_destroyed.emit("left")
				_disable_cannon(left_cannon_node)
			_check_shield_status()
			_update_hp_bars()
			return true
			
		"right", "canhão direito", "dir":
			if right_cannon_hp <= 0:
				return false
			right_cannon_hp = maxi(0, right_cannon_hp - amount)
			_flash_node(right_cannon_node, Color(1.5, 0.2, 0.2))
			vital_point_damaged.emit("right", right_cannon_hp, MAX_CANNON_HP)
			if right_cannon_hp == 0:
				_play_sfx("explosion")
				cannon_destroyed.emit("right")
				_disable_cannon(right_cannon_node)
			_check_shield_status()
			_update_hp_bars()
			return true
			
		"core", "núcleo", "nucleo":
			if shield_active:
				# Escudo ativo reflete o dano
				_play_sfx("hit")
				if shield_sprite:
					_flash_node(shield_sprite, Color(2.0, 2.0, 2.0))
				return false
				
			if core_hp <= 0:
				return false
				
			core_hp = maxi(0, core_hp - amount)
			_flash_node(core_node, Color(2.0, 0.3, 0.3))
			vital_point_damaged.emit("core", core_hp, MAX_CORE_HP)
			if core_hp == 0:
				is_defeated = true
				_play_sfx("explosion")
				boss_defeated.emit()
				_defeat_sequence()
			_update_hp_bars()
			return true
			
	return false

func _play_sfx(sfx_name: String) -> void:
	if not is_inside_tree():
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		match sfx_name:
			"explosion": sm.play_explosion()
			"hit": sm.play_hit()
			"shield_break": sm.play_shield_break()

func _check_shield_status() -> void:
	if shield_active and left_cannon_hp <= 0 and right_cannon_hp <= 0:
		shield_active = false
		_play_sfx("shield_break")
		if shield_sprite:
			var tween := create_tween()
			tween.tween_property(shield_sprite, "scale", Vector2(1.8, 1.8), 0.3)
			tween.parallel().tween_property(shield_sprite, "modulate:a", 0.0, 0.3)
			tween.tween_callback(func(): shield_sprite.visible = false)
			
		if core_status_label:
			core_status_label.text = "VULNERÁVEL!"
			core_status_label.modulate = Color(1.0, 0.3, 0.3)
			
		shield_collapsed.emit()

func _disable_cannon(node: Node2D) -> void:
	if node:
		node.modulate = Color(0.4, 0.4, 0.4, 0.8)

func _flash_node(node: CanvasItem, flash_col: Color) -> void:
	if not node:
		return
	var orig_col: Color = node.modulate
	node.modulate = flash_col
	var tween := create_tween()
	tween.tween_property(node, "modulate", orig_col, 0.15)

func _update_hp_bars() -> void:
	if left_hp_bar:
		left_hp_bar.value = float(left_cannon_hp)
	if right_hp_bar:
		right_hp_bar.value = float(right_cannon_hp)
	if core_hp_bar:
		core_hp_bar.value = float(core_hp)

func _defeat_sequence() -> void:
	# Sequência épica de explosões e tremor ao destruir o chefe
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): queue_free())

func is_left_cannon_alive() -> bool:
	return left_cannon_hp > 0

func is_right_cannon_alive() -> bool:
	return right_cannon_hp > 0

func is_shield_active() -> bool:
	return shield_active

func get_target_global_position(point_name: String) -> Vector2:
	match point_name.to_lower():
		"left", "canhão esquerdo", "esq":
			if left_cannon_node:
				return left_cannon_node.global_position
			return global_position + Vector2(-180, 10)
		"right", "canhão direito", "dir":
			if right_cannon_node:
				return right_cannon_node.global_position
			return global_position + Vector2(180, 10)
		_:
			if core_node:
				return core_node.global_position
			return global_position
