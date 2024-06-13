extends Node3D
class_name BulletHole
var normal : Vector3
var colPoint : Vector3
var rot : float
@onready var particles : Node3D = $particles
var lookAtPoint
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	var timer = get_tree().create_timer(UserConfig.game_decal_remove_time)
	timer.timeout.connect(queue_free)
	$particles/impactParticle.emitting = true
	$particles/dirtParticles.emitting = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
