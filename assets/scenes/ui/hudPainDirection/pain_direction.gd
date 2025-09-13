extends Control
@export var painDealerPosition : Vector3
var tween : Tween
var pawn : BasePawn
var _2Dto3DPosition : Vector2

func _ready() -> void:
	fadeIn()
	_2Dto3DPosition = get_viewport().get_camera_3d().unproject_position(painDealerPosition)
	rotation = -_2Dto3DPosition.angle()
	await get_tree().create_timer(0.5).timeout
	fadeOut()

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
	tween.tween_property(self,"modulate",Color.WHITE,0.5)

func _physics_process(delta: float) -> void:
	if painDealerPosition:
		rotation = lerpf(rotation,-_2Dto3DPosition.angle(),16*delta)
