extends Sprite2D
var painDealerNode : Node3D
var tween : Tween
#var _2Dto3DPosition : Vector2
var lifetime : float = 1.0

func _ready() -> void:
	fadeIn()


func _process(delta: float) -> void:
	var pawn = gameManager.getCurrentPawn()
	if not painDealerNode == null and not pawn == null:
		scale = Vector2.ONE * clamp(remap(pawn.global_position.distance_to(painDealerNode.global_position), 5.0, 35.0, 1.0, 0.35), 0.35, 1.0)
		var cam := get_viewport().get_camera_3d()
		var cam_dir_to_dealer = pawn.global_position.direction_to(painDealerNode.global_position) * cam.global_transform.basis
		rotation = -Vector2(cam_dir_to_dealer.x, cam_dir_to_dealer.z).normalized().angle_to(Vector2.UP)
	lifetime -= delta
	if lifetime <= 0.0:
		modulate.a -= delta
	if modulate.a <= 0.0:
		queue_free()


func reset_alpha() -> void:
	lifetime = 1.0
	modulate.a = 1.0


##Not needed
func fadeOut()->void:
	if tween:
		tween.kill()
	tween = create_tween()
	await tween.tween_property(self,"modulate",Color.TRANSPARENT,0.5).finished
	queue_free()


func fadeIn()->void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self,"modulate",Color.WHITE,0.25)
