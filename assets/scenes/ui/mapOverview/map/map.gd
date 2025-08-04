extends Node3D

var camTween : Tween
@onready var cameraController : CharacterBody3D = $cameraController
@export var mapScreen : CanvasLayer
@onready var horizontal = $Camera/camHoriz
@onready var vertical = $Camera/camHoriz/camVert
@onready var camera : Camera3D = $Camera/camHoriz/camVert/springArm3d/camera3d
@onready var springArm : SpringArm3D = $cameraController/Camera/camHoriz/camVert/springArm3d
@onready var cameraHolder = $Camera
## Which direction will the camera face on the map? The array holds rotations that the player can cycle through to view different parts of the map
@export var mapRotations : Array[Vector3]
## Which position will the camera be at on the map? The array holds positions that the player can cycle through to view different parts of the map
@export var mapPositions : Array[Vector3]
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1

var direction : Vector3
var speed : float = 10
var acceleration : float = 5

#Variables
@export var enabled: bool = true
var isPanning := false
##Enables the movement keys to be emitted
var movementEnabled:bool = true
##Enables the mouse action buttons to be emitted
var mouseActionsEnabled:bool = true
var mouseButtonInput:InputEventMouseButton = InputEventMouseButton.new()
var inputDir : Vector3 = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
var motionX : float = 0.0

func getInputDir()->Vector3:
	inputDir = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
	return inputDir


func _ready() -> void:
	scanMarkers()

	#gameManager.setMotionBlur(camera)


func _physics_process(delta: float) -> void:
	if enabled:
		if !isPanning:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			direction.x = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).x
			direction.z = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).z

			cameraController.velocity.x = lerpf(cameraController.velocity.x, speed * direction.normalized().x,acceleration*delta)
			cameraController.velocity.z = lerpf(cameraController.velocity.z, speed * direction.normalized().z,acceleration*delta)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
			direction = Vector3.ZERO
			cameraController.velocity = Vector3.ZERO

		cameraController.move_and_slide()

		if Input.is_action_pressed("gRightClick"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN:
			%camHoriz.rotation_degrees.y += motionX
		motionX = deg_to_rad(-event.relative.x * UserConfig.game_control_mouseSens * 55)

	isPanning = Input.is_action_pressed("gPanMap")

	if isPanning:
		if event is InputEventMouseMotion:
			cameraController.global_position += Vector3(-event.relative.x,0,-event.relative.y).rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y) * 0.05

	if event is InputEventMouseButton:
		if event.is_action_pressed("gMwheelUp"):
			if !springArm.spring_length < -4:
				springArm.spring_length -= 0.5

		if event.is_action_pressed("gMwheelDown"):
			if !springArm.spring_length > 6:
				springArm.spring_length += 0.5

func scanMarkers()->void:
	for markers in %areaNodes.get_children():
		if !markers.map:
			markers.playCloseAnimation()
			markers.map = self
			markers.setupMap()

func setCameraPositionAndRotation(pos:Vector3,rot:Vector3)->void:
	if camTween:
		camTween.kill()
	camTween = create_tween()
	camTween.parallel().tween_property(cameraHolder,"global_position",pos,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	camTween.parallel().tween_property(horizontal,"rotation_degrees:y",rot.y,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	camTween.parallel().tween_property(vertical,"rotation_degrees:x",rot.x,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
