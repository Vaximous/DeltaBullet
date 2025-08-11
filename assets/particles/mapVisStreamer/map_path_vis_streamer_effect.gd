extends PathFollow3D


@export var speed : float = 50.0
@export var fade_curve : Curve


@onready var sprite = $sprite3d


func _process(delta: float) -> void:
	progress += speed * delta

	#Fade it out of its close to the start/end using fade_margin on progress
	sprite.modulate.a = get_fade_amount()

	if progress_ratio >= 1.0:
		queue_free()


func get_fade_amount() -> float:
	return fade_curve.sample(progress_ratio)
