@tool
extends Marker3D
var visibilityTween : Tween
var sizeTween : Tween
var iconTween : Tween
const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed : float = 1

@export var iconColor : Color = Color.DARK_RED
@onready var collisionShape: CollisionShape3D = $area3d/collisionShape3d
@onready var clickSound : AudioStreamPlayer = $clickSound
@onready var hoverSound : AudioStreamPlayer = $hoverSound
@onready var area3d : Area3D = $area3d
@onready var ping_particles := $pingParticle
@export var map : Node3D:
	set(value):
		map = value
		setupMap()
##What is this areas name?
@export var locationName : String = ""
##What scene will this location load?
@export var travelScene : PackedScene
##Controls whether or not this area is locked or unlocked. If its locked then the player will be unable to travel to this location. Otherwise, they will be able to
@export_enum("Locked","Unlocked") var travelStatus : int = 1
## This ID will correspong with whichever area value the selection index is currently on. If it equals the selection index of the map, it will be visible. Otherwise it won't be
@export var travelGroupID = 0
##This is the ID of the location itself.
@export var travelID = 0




func setVisualMarkers()->void:
	if is_instance_valid(collisionShape.shape) and collisionShape.shape is BoxShape3D:
		var boxShape : BoxShape3D = collisionShape.shape
		ping_particles.scale = collisionShape.shape.size
		ping_particles.scale.y = 1.0
		collisionShape.global_position = global_position
		%visualHolder.global_position.x = collisionShape.global_position.x
		%visualHolder.global_position.z = collisionShape.global_position.z
		%positionReference.scale = boxShape.size
		##Bottom
		$%cornerBottomRight.global_position.x = %bottomRight.global_position.x
		$%cornerBottomRight.global_position.z = %bottomRight.global_position.z

		$%cornerBottomLeft.global_position.x = %bottomLeft.global_position.x
		$%cornerBottomLeft.global_position.z = %bottomLeft.global_position.z

		##Top
		$%cornerUpRight.global_position.x = %topRight.global_position.x
		$%cornerUpRight.global_position.z =%topRight.global_position.z

		$%cornerUpLeft.global_position.x = %topLeft.global_position.x
		$%cornerUpLeft.global_position.z = %topLeft.global_position.z


func setupMap()->void:
	if !Engine.is_editor_hint():
		playCloseAnimation()
		if map:
			if !map.mapScreen.index_changed.is_connected(updateVisibility.unbind(1)):
				map.mapScreen.index_changed.connect(updateVisibility.unbind(1))
				%mapLabel.text = locationName


func updateVisibility()->void:
	if map.mapScreen.selectedIndex == travelGroupID:
		setVisible(true)
	else:
		setVisible(false)


func _process(_delta: float) -> void:
	#super(delta)
	setVisualMarkers()


func _ready() -> void:
	%icon.position.y = collisionShape.shape.size.y - 4.0
	setupMap()


func playOpenAnimation()->void:
	if map:
		if map.mapScreen.selectedMarker != self or isLocationCurrent():
			enlargeVisual()
			fadeIconIn()



func enlargeVisual(size:float=1.2)->void:
	if sizeTween:
		sizeTween.kill()
	sizeTween = create_tween()
	sizeTween.tween_property(self,"scale",Vector3(size,size,size),0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func fadeIconIn()->void:
	if iconTween:
		iconTween.kill()
	ping_particles.emitting = true
	%mapLabel.no_depth_test = true
	iconTween = create_tween()
	iconTween.parallel().tween_property(%icon,"position:y",collisionShape.shape.size.y - 2.5,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%icon,"scale",Vector3.ONE,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel,"modulate",Color.WHITE,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel,"scale",Vector3.ONE*1.5,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	#Don't fade out the icon
	#iconTween.parallel().tween_property(%icon,"modulate",iconColor,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func fadeIconOut()->void:
	if iconTween:
		iconTween.kill()
	ping_particles.emitting = false
	%mapLabel.no_depth_test = false
	iconTween = create_tween()
	iconTween.parallel().tween_property(%icon,"position:y",collisionShape.shape.size.y - 4.0,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%icon,"scale",Vector3.ONE*0.5,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel,"modulate",Color.TRANSPARENT,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel,"scale",Vector3.ZERO,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	#Don't fade out the icon
	#iconTween.parallel().tween_property(%icon,"modulate",Color.TRANSPARENT,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func reduceVisual()->void:
	if sizeTween:
		sizeTween.kill()
	sizeTween = create_tween()
	sizeTween.tween_property(self,"scale",Vector3.ONE,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func playCloseAnimation()->void:
	if map:
		if map.mapScreen.selectedMarker != self and !isLocationCurrent():
			reduceVisual()
			fadeIconOut()
			#setMarkerMaterial(load(map.markerColors[0]))


##Checks if this is the current location.
func isLocationCurrent() -> bool:
	if gameManager.world.scene_file_path == travelScene.resource_path:
		return true
	return false


func gotoLocation()->void:
	if travelScene and get_tree().current_scene.scene_file_path != travelScene.resource_path:
		gameManager.saveTemporaryPawnInfo()
		await Fade.fade_out(0.5).finished
		gameManager.removeWorldMap()
		gameManager.loadWorld(travelScene.resource_path)
	else:
		gameManager.notify_warn("You're already at this location.", 4, 5)


func setVisible(value:bool)->void:
	if visibilityTween:
		visibilityTween.kill()
	visibilityTween = create_tween()
	if value:
		show()
		#visibilityTween.parallel().tween_property(icon,"modulate",Color.WHITE,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		#await visibilityTween.parallel().tween_property(icon,"modulate",Color.TRANSPARENT,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		hide()


func setMarkerMaterial(material:StandardMaterial3D):
	for i in $visualHolder.get_children():
		for marker in i.get_children():
			var ppppm : ParticleProcessMaterial = ping_particles.process_material
			ppppm.color = material.albedo_color
			marker.set_surface_override_material(0,material)


##Used for Navigation visualization on the map
func getNavPoint() -> Vector3:
	return $navPoint.global_position


func _on_button_pressed() -> void:
	if map:
		map.mapScreen.selectedMarker = self
