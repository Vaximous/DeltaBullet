extends Node
@export var enabled : bool = true
@export var pawn : BasePawn
@export var animationTree : AnimationTree
@export var mesh : Node3D
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT

var tweener : Tween

func _physics_process(delta: float) -> void:
	if enabled and !pawn.isPawnDead and is_instance_valid(pawn):
		if pawn.is_on_floor():
			animationTree.set("parameters/fallBlend/blend_amount", lerpf(animationTree.get("parameters/fallBlend/blend_amount"), 0.0, delta * 12))
		elif pawn.velocity.y > 0:
			if animationTree.get("parameters/jumpshot/active") == false:
				animationTree.set("parameters/jumpshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			animationTree.set("parameters/jumpshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
			animationTree.set("parameters/fallBlend/blend_amount", lerpf(animationTree.get("parameters/fallBlend/blend_amount"), 1.0, delta * 12))

		animationTree.set("parameters/aimSprintStrafe/blend_position",Vector2(-pawn.velocity.x, -pawn.velocity.z).rotated(mesh.rotation.y))
		animationTree.set("parameters/crouchStrafe/blend_position",animationTree.get("parameters/aimSprintStrafe/blend_position"))
		animationTree.set("parameters/strafeSpace/blend_position",animationTree.get("parameters/aimSprintStrafe/blend_position"))


func _on_pawn_entity_set_movement_state(state: MovementState) -> void:
	if enabled and !pawn.isPawnDead and is_instance_valid(pawn):
		if tweener:
			tweener.kill()
		tweener = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
		tweener.parallel().tween_property(animationTree,"parameters/idleSpace/blend_position",state.movementID,defaultTweenSpeed)
		tweener.parallel().tween_property(animationTree,"parameters/idleSpaceSpeed/scale",state.animationSpeed,0.7)

		tweener.parallel().tween_property(animationTree,"parameters/crouchSpace/blend_position",state.movementID,defaultTweenSpeed)
		tweener.parallel().tween_property(animationTree,"parameters/crouchScale/scale",state.animationSpeed,0.7)
		tweener.parallel().tween_property(animationTree,"parameters/crouchStrafeScale/scale",state.animationSpeed,0.7)

		match state.movementID:
			1:
				animationTree.set("parameters/strafeType/transition_request", "walking")
			2:
				animationTree.set("parameters/strafeType/transition_request", "running")

func _on_pawn_entity_mesh_look_at_changed(value: bool) -> void:
	if enabled and !pawn.isPawnDead and is_instance_valid(pawn):
		setAimingTree(value)

func setAimingTree(value:bool)->void:
	if value and !pawn.isPawnDead and is_instance_valid(pawn):
		animationTree.set("parameters/aimTransition/transition_request", "aiming")
	else:
		animationTree.set("parameters/aimTransition/transition_request", "notAiming")
