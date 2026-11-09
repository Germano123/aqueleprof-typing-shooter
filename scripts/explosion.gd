extends Node2D

# Explosion - Efeito visual de explosão com partículas, onda de choque e flash de luz

@onready var particles: CPUParticles2D = $CPUParticles2D
var shockwave_radius: float = 0.0
var shockwave_alpha: float = 1.0

func _ready() -> void:
	SoundManager.play_explosion()
	if particles:
		particles.emitting = true
	
	# Animação do anel de onda de choque expansivo
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "shockwave_radius", 70.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "shockwave_alpha", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if shockwave_radius > 0.0 and shockwave_alpha > 0.01:
		draw_arc(Vector2.ZERO, shockwave_radius, 0.0, TAU, 32, Color(0.2, 0.9, 1.0, shockwave_alpha * 0.8), 3.0, true)
		draw_circle(Vector2.ZERO, shockwave_radius * 0.4, Color(1.0, 0.3, 0.2, shockwave_alpha * 0.4))
