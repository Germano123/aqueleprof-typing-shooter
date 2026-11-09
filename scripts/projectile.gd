extends Node2D

# Projectile - Laser de plasma veloz que viaja até o alvo

@export var speed: float = 2400.0
var target_position: Vector2 = Vector2.ZERO
var target_node: Node2D = null

func setup(origin: Vector2, target_pos: Vector2, node_ref: Node2D = null) -> void:
	global_position = origin
	target_position = target_pos
	target_node = node_ref
	look_at(target_position)
	rotation += PI / 2.0 # Alinhado com a textura vertical

func _process(delta: float) -> void:
	if is_instance_valid(target_node):
		target_position = target_node.global_position
		
	var dir := (target_position - global_position).normalized()
	var step := speed * delta
	
	if global_position.distance_to(target_position) <= step:
		global_position = target_position
		_on_hit()
	else:
		global_position += dir * step
		look_at(target_position)
		rotation += PI / 2.0

func _on_hit() -> void:
	SoundManager.play_hit()
	queue_free()
