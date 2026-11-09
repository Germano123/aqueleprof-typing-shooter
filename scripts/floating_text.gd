extends Node2D

# FloatingText - Exibe pontuações e bônus flutuantes no local do impacto

@onready var label: Label = $Label

func setup(text: String, start_pos: Vector2, color: Color = Color(1.0, 0.9, 0.2)) -> void:
	global_position = start_pos
	if not is_node_ready():
		await ready
	label.text = text
	label.add_theme_color_override("font_color", color)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 45.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
