extends Node3D

@export var mapName : StringName = &""
const markerColors = ["res://assets/scenes/ui/mapOverview/map/defaultMarker.tres","res://assets/scenes/ui/mapOverview/map/atLocationMarker.tres","res://assets/scenes/ui/mapOverview/map/selectedMarker.tres"]
var camTween : Tween

@onready var pathVis : Path3D = %path3d
@export var navRegion : NavigationRegion3D
@export var modelHolder : Node3D
@onready var cameraController : CharacterBody3D = $cameraController
@export var mapScreen : CanvasLayer
@onready var horizontal = %camHorizs
@onready var vertical = %camVert
@onready var camera : Camera3D = %camera3d
@onready var springArm : SpringArm3D = $cameraController/Camera/camHoriz/camVert/springArm3d
@onready var cameraHolder = $Camera
@onready var mapCursor = %mapSelectionMarker
@export var worldEnv : WorldEnvironment
## Which direction will the camera face on the map? The array holds rotations that the player can cycle through to view different parts of the map
@export var mapRotations : Array[Vector3]
## Which position will the camera be at on the map? The array holds positions that the player can cycle through to view different parts of the map
@export var mapPositions : Array[Vector3]
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1

var direction : Vector3:
	set(value):
		if value != Vector3.ZERO:
			if camTween:
				camTween.kill()
		direction = value
@export var speed : float = 30
var acceleration : float = 5
var cursorSpeed : float = 25
#var desired_springarm_length : float = 10.0
var desired_fov : float = 10.0
var fading_out : bool = false
const MAX_FOV : float = 70.0
const MIN_FOV : float = 10.0

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
	#desired_springarm_length = clamp(desired_springarm_length, 500.0, 5000.0)
	pathVis.hide()
	scanMarkers()
	await get_tree().process_frame
	#fadeModel(modelHolder)
#	modelHolder.global_position.y = -1
	tweenModelPosition(modelHolder,Vector3.ZERO)
	#gameManager.setMotionBlur(camera)
	gameManager.updateGraphics(worldEnv)
	if !UserConfig.configs_updated.is_connected(gameManager.updateGraphics.bind(worldEnv)):
		UserConfig.configs_updated.connect(gameManager.updateGraphics.bind(worldEnv))
	else:
		UserConfig.configs_updated.disconnect(gameManager.updateGraphics.bind(worldEnv))
		UserConfig.configs_updated.connect(gameManager.updateGraphics.bind(worldEnv))

	cameraController.global_position.x = getCurrentLocationMarker().global_position.x
	cameraController.global_position.z = getCurrentLocationMarker().global_position.z


func _physics_process(delta: float) -> void:
	if enabled:
		if !isPanning:
			%mapSelectionMarker.show()
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			direction.x = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).x
			direction.z = getInputDir().rotated(Vector3.UP,%camHoriz.global_transform.basis.get_euler().y).z

			cameraController.velocity.x = lerpf(cameraController.velocity.x, speed * direction.normalized().x,acceleration*delta)
			cameraController.velocity.z = lerpf(cameraController.velocity.z, speed * direction.normalized().z,acceleration*delta)

			camera.fov = lerp(camera.fov, desired_fov, delta * 4.0)
			#%springArm3d.spring_length = lerp(%springArm3d.spring_length, desired_springarm_length, delta * 5.0)
		else:
			%mapSelectionMarker.hide()
			isMovingInput = false
			if camTween:
				camTween.kill()
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
				%mapSelectionMarker.markerIcon.modulate = lerp(%mapSelectionMarker.markerIcon.modulate,Color.DARK_RED,12*delta)
				%mapSelectionMarker.global_position = lerp(%mapSelectionMarker.global_position,to_global(point["position"]),cursorSpeed*delta)
			else:
				%mapSelectionMarker.markerIcon.modulate = lerp(%mapSelectionMarker.markerIcon.modulate,Color.TRANSPARENT,12*delta)
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
	if fading_out: return
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
			#desired_springarm_length -= 2.0
			desired_fov -= 1.0
		if event.is_action_pressed("gMwheelDown"):
			#desired_springarm_length += 2.0
			desired_fov += 1.0
		#desired_springarm_length = clamp(desired_springarm_length, 100.0, 5000.0)
		desired_fov = clamp(desired_fov, MIN_FOV, MAX_FOV)



func scanMarkers()->void:
	for markers in getMarkers():
		if !markers.map:
			markers.playCloseAnimation()
			markers.map = self
			markers.setupMap()
		if markers.isLocationCurrent():
			markers.setMarkerMaterial(load(markerColors[1]))


func getMarkers() -> Array[Marker3D]:
	var m : Array[Marker3D]
	m.assign(%areaNodes.get_children())
	return m


func getCurrentLocationMarker() -> Marker3D:
	for marker in getMarkers():
		if marker.isLocationCurrent():
			return marker
	return null



func setCameraPositionAndRotation(pos:Vector3,rot:Vector3 , posSpeed : float = 3, rotSpeed : float = 3)->void:
	if camTween:
		camTween.kill()
	camTween = create_tween()
	if pos != Vector3.ZERO:
		camTween.parallel().tween_property(cameraController,"global_position",pos,posSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	if rot != Vector3.ZERO:
		camTween.parallel().tween_property(horizontal,"rotation_degrees:y",rot.y,rotSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
		camTween.parallel().tween_property(vertical,"rotation_degrees:x",rot.x,rotSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)


##Clear the current navigation visualization path
func clearNaviPath() -> void:
	return


func createNaviPath(start : Vector3, end : Vector3) -> void:
	clearNaviPath()
	var navAgent : NavigationAgent3D = $pathVisualizerStartPosition/pathVisualizerNavAgent
	$pathVisualizerStartPosition.global_position = start
	navAgent.target_position = end
	var new_curve := Curve3D.new()
	pathVis.curve = new_curve
	navAgent.get_next_path_position()
	var navPath = Util.smooth_position3d_array(navAgent.get_current_navigation_path(), 2)

	for idx in navPath.size():
		var point = navPath.get(idx)
		new_curve.add_point(point, Vector3.ZERO, Vector3.ZERO)


##Marker selected callback
func _on_map_selection_marker_selected_marker(node: Node3D) -> void:
	if is_instance_valid(node):
		pathVis.show()
		var current = getCurrentLocationMarker()
		if node == current:
			clearNaviPath()
			return
		var destination = node.getNavPoint()
		var start_closest = NavigationServer3D.region_get_closest_point(navRegion.get_rid(), current.getNavPoint())
		setCameraPositionAndRotation(Vector3(node.global_position.x,cameraController.global_position.y,node.global_position.z),Vector3.ZERO,1)
		#cameraController.global_position.x = node.global_position.x
		#cameraController.global_position.z = node.global_position.z
		createNaviPath(start_closest, destination)
	else:
		$pathVisualizerStartPosition/path3d.hide()


func _on_travel_button_pressed() -> void:
	#desired_springarm_length = 1
	desired_fov = 0.1
	fading_out = true
