extends Node3D

var camTween : Tween
@onready var modelHolder : Node3D = $model
@onready var cameraController : CharacterBody3D = $cameraController
@export var mapScreen : CanvasLayer
@onready var horizontal = $Camera/camHoriz
@onready var vertical = $Camera/camHoriz/camVert
@onready var camera : Camera3D = %camera3d
@onready var springArm : SpringArm3D = $cameraController/Camera/camHoriz/camVert/springArm3d
@onready var cameraHolder = $Camera
@onready var mapCursor = %mapSelectionMarker
## Which direction will the camera face on the map? The array holds rotations that the player can cycle through to view different parts of the map
@export var mapRotations : Array[Vector3]
## Which position will the camera be at on the map? The array holds positions that the player can cycle through to view different parts of the map
@export var mapPositions : Array[Vector3]
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1

var direction : Vector3
var speed : float = 15
var acceleration : float = 5
var cursorSpeed : float = 25

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
var positionMouse : Vector3 = Vector3.ZERO
var isMovingInput := false
var mousePosition2D : Vector2

func getInputDir()->Vector3:
	inputDir = Vector3(Input.get_action_strength("gMoveRight") - Input.get_action_strength("gMoveLeft"), 0, Input.get_action_strength("gMoveBackward") - Input.get_action_strength("gMoveForward"))
	return inputDir


func _ready() -> void:
	scanMarkers()
	await get_tree().process_frame
	#fadeModel(modelHolder)
	modelHolder.global_position.y = -1
	tweenModelPosition(modelHolder,Vector3.ZERO)
	#gameManager.setMotionBlur(camera)


func _physics_process(delta: float) -> void:
	if enabled:
		if !isPanning:
			%mapSelectionMarker.show()
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			direction.x = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).x
			direction.z = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).z

			cameraController.velocity.x = lerpf(cameraController.velocity.x, speed * direction.normalized().x,acceleration*delta)
			cameraController.velocity.z = lerpf(cameraController.velocity.z, speed * direction.normalized().z,acceleration*delta)
		else:
			%mapSelectionMarker.hide()
			isMovingInput = false
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
			direction = Vector3.ZERO
			cameraController.velocity = Vector3.ZERO
			cameraController.global_position = lerp(cameraController.global_position,cameraController.global_position + positionMouse.rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y),5*delta)

		cameraController.move_and_slide()

		##Use the mouse position and set the cursor to it
		if is_instance_valid(camera):
			var point = gameManager.get_from_mouse(1000,self,camera,[cameraController.get_rid()])
			if point.has("position"):
				#%mapSelectionMarker.global_position = Vector3.ZERO
				%mapSelectionMarker.global_position = lerp(%mapSelectionMarker.global_position,to_global(point["position"]),cursorSpeed*delta)

		if Input.is_action_pressed("gRightClick"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func tweenModelPosition(object:Node3D,newPosition:Vector3,tweenSpeed:float=0.5)->void:
	var tween = create_tween()
	tween.parallel().tween_property(object,"global_position",newPosition,tweenSpeed).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func fadeModel(parent:Node3D)->void:
	var tween = create_tween()
	for i in parent.get_children():
		if i is Node3D:
			fadeModel(i)
		if i is MeshInstance3D:
			i.transparency = 1
			tween.parallel().tween_property(i,"transparency",0,0.5).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mousePosition2D = event.relative
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN:
			%camHoriz.rotation_degrees.y += motionX
		motionX = deg_to_rad(-event.relative.x * UserConfig.game_control_mouseSens * 55)


	isPanning = Input.is_action_pressed("gPanMap")

	if isPanning:
		if event is InputEventMouseMotion:
			positionMouse = Vector3(-event.relative.x,0,-event.relative.y)

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
