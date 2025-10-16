@tool
extends Marker3D

enum IconType {
	STORY,
	SAFEHOUSE,
	MISSION,
	CURRENT,
}

enum Types {
	TRAVEL,
	PROPERTY,
}
enum TravelStatus {
	Locked,
	Unlocked,
}

enum PropertyState {
	Locked,
	Purchased,
}

enum PropertyType {
	REWARD,
	SCENE,
}

const defaultTransitionType = Tween.TRANS_QUINT
const defaultEaseType = Tween.EASE_OUT
const defaultTweenSpeed: float = 1

@export_category("Marker")
var defaultMarkerIcon: IconType = 0
@export_subgroup("Marker Identity")
@export var locationName: String = "":
	set(value):
		locationName = value
@export var markerType: Types = 0:
	set(value):
		if markerType == value: return
		markerType = value
		notify_property_list_changed()

@export var iconColor: Color = Color.DARK_RED:
	set(value):
		iconColor = value
		notify_property_list_changed
	get: return iconColor

var markerIcon: IconType = 0:
	set(value):
		markerIcon = value
		notify_property_list_changed()


		#notify_property_list_changed()

##What is this areas name?
var map: Node3D:
	set(value):
		map = value
		notify_property_list_changed()
		setupMap()

##What scene will this location load?
var travelScene: PackedScene:
	set(value):
		if travelScene == value: return
		travelScene = value
		notify_property_list_changed()
##Controls whether or not this area is locked or unlocked. If its locked then the player will be unable to travel to this location. Otherwise, they will be able to
var travelStatus: TravelStatus = 0:
	set(value):
		travelStatus = value
		notify_property_list_changed()

var hasCollectibleItems: bool = false:
	set(value):
		notify_property_list_changed()
		hasCollectibleItems = value
var hasExploration: bool = false:
	set(value):
		notify_property_list_changed()
		hasExploration = value
var hasCollectibleNotes: bool = false:
	set(value):
		notify_property_list_changed()
		hasCollectibleNotes = value
var useDescription: bool = false:
	set(value):
		useDescription = value
		notify_property_list_changed()

#Property
var propertyID: StringName = &''
var propertyStatus: PropertyState:
	set(value):
		propertyStatus = value
		notify_property_list_changed()
var propertyType: PropertyType:
	set(value):
		propertyType = value
		notify_property_list_changed()
var propertyRewards: Array = []:
	set(value):
		propertyRewards = value
		notify_property_list_changed()
var propertyPrice: int = 100:
	get:
		return propertyPrice
	set(value):
		propertyPrice = value
		notify_property_list_changed()

var visibilityTween: Tween
var sizeTween: Tween
var iconTween: Tween
var locationDescription: String = ""

@onready var collisionShape: CollisionShape3D = $area3d/collisionShape3d
@onready var clickSound: AudioStreamPlayer = $clickSound
@onready var hoverSound: AudioStreamPlayer = $hoverSound
@onready var area3d: Area3D = $area3d
@onready var ping_particles := $pingParticle


func _ready() -> void:
	%icon.position.y = collisionShape.shape.size.y - 4.0
	setupMap()
	setMarkerIcon(markerIcon)


func _process(_delta: float) -> void:
	#super(delta)
	setVisualMarkers()


func setVisualMarkers() -> void:
	if is_instance_valid(collisionShape.shape) and collisionShape.shape is BoxShape3D:
		var boxShape: BoxShape3D = collisionShape.shape
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
		$%cornerUpRight.global_position.z = %topRight.global_position.z

		$%cornerUpLeft.global_position.x = %topLeft.global_position.x
		$%cornerUpLeft.global_position.z = %topLeft.global_position.z


func setupMap() -> void:
	if !Engine.is_editor_hint():
		playCloseAnimation()
		if map:
			defaultMarkerIcon = markerIcon
			setMarkerIcon(markerIcon)
			%mapLabel.text = locationName
			if markerType == Types.PROPERTY:
				set_meta(&"id", propertyID)
				set_meta(&"price", propertyPrice)
				set_meta(&"rewards", propertyRewards)
				if gameState.hasOwnedProperty(get_meta(&"id")):
					setPropertyState(PropertyState.Purchased)

			if travelScene:
				var scene = travelScene.instantiate()
				locationDescription = scene.worldData.worldDescription
				scene.queue_free()


func playOpenAnimation() -> void:
	if map:
		if map.mapScreen.selectedMarker != self or isLocationCurrent():
			enlargeVisual()
			fadeIconIn()


func enlargeVisual(size: float = 1.2) -> void:
	if sizeTween:
		sizeTween.kill()
	sizeTween = create_tween()
	sizeTween.tween_property(self, "scale", Vector3(size, size, size), 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func fadeIconIn() -> void:
	if iconTween:
		iconTween.kill()
	ping_particles.emitting = true
	%mapLabel.no_depth_test = true
	iconTween = create_tween()
	iconTween.parallel().tween_property(%icon, "position:y", collisionShape.shape.size.y - 2.5, 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%icon, "scale", Vector3.ONE, 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel, "modulate", Color.WHITE, 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel, "scale", Vector3.ONE * 1.5, 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	#Don't fade out the icon
	#iconTween.parallel().tween_property(%icon,"modulate",iconColor,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func fadeIconOut() -> void:
	if iconTween:
		iconTween.kill()
	ping_particles.emitting = false
	%mapLabel.no_depth_test = false
	iconTween = create_tween()
	iconTween.parallel().tween_property(%icon, "position:y", collisionShape.shape.size.y - 4.0, 1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%icon, "scale", Vector3.ONE * 0.5, 1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel, "modulate", Color.TRANSPARENT, 1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	iconTween.parallel().tween_property(%mapLabel, "scale", Vector3.ZERO, 1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	#Don't fade out the icon
	#iconTween.parallel().tween_property(%icon,"modulate",Color.TRANSPARENT,1).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func reduceVisual() -> void:
	if sizeTween:
		sizeTween.kill()
	sizeTween = create_tween()
	sizeTween.tween_property(self, "scale", Vector3.ONE, 0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func playCloseAnimation() -> void:
	if map:
		if map.mapScreen.selectedMarker != self and !isLocationCurrent():
			reduceVisual()
			fadeIconOut()
			#setMarkerMaterial(load(map.markerColors[0]))


##Checks if this is the current location.
func isLocationCurrent() -> bool:
	if gameManager.world and is_instance_valid(travelScene):
		if gameManager.world.scene_file_path == travelScene.resource_path:
			return true
	return false


func gotoLocation() -> void:
	if travelScene and get_tree().current_scene.scene_file_path != travelScene.resource_path:
		gameManager.saveTemporaryPawnInfo()
		await Fade.fade_out(0.5).finished
		gameManager.removeWorldMap()
		gameManager.loadWorld(travelScene.resource_path)
	else:
		gameManager.notify_warn("You're already at this location.", 4, 5)


func setPropertyState(value: PropertyState):
	propertyStatus = value


func setVisible(value: bool) -> void:
	if visibilityTween:
		visibilityTween.kill()
	visibilityTween = create_tween()
	if value:
		show()
		#visibilityTween.parallel().tween_property(icon,"modulate",Color.WHITE,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType)
	else:
		#await visibilityTween.parallel().tween_property(icon,"modulate",Color.TRANSPARENT,defaultTweenSpeed).set_ease(defaultEaseType).set_trans(defaultTransitionType).finished
		hide()


func setMarkerMaterial(material: StandardMaterial3D):
	for i in $visualHolder.get_children():
		for marker in i.get_children():
			var ppppm: ParticleProcessMaterial = ping_particles.process_material
			ppppm.color = material.albedo_color
			marker.set_surface_override_material(0, material)


##Used for Navigation visualization on the map
func getNavPoint() -> Vector3:
	return $navPoint.global_position


func setMarkerIcon(icon: IconType):
	if is_instance_valid(%icon):
		%icon.frame = icon


func _get_property_list() -> Array[Dictionary]:
	var ret: Array[Dictionary] = [{}]
	if Engine.is_editor_hint():
		ret.append(
			{
			"name": &"Marker Essentials",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
			}
		)

		ret.append(
			{
			"name": &"map",
			"type": TYPE_NODE_PATH,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
			}
		)

		ret.append(
			{
			"name": &"markerIcon",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint_string": ",".join(IconType.keys())
			}
		)

		##Switch behavior definitions based on marker type
		match markerType:
			Types.TRAVEL:
				ret.append(
					{
					"name": &"Travel Behavior",
					"type": TYPE_NIL,
					"usage": PROPERTY_USAGE_GROUP
					}
				)

				ret.append(
					{
					"name": &"travelScene",
					"type": TYPE_OBJECT,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
					}
				)

				ret.append(
					{
					"name": &"travelStatus",
					"type": TYPE_INT,
					"hint": PROPERTY_HINT_ENUM,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
					"hint_string": ",".join(TravelStatus.keys())
					}

				)

			Types.PROPERTY:
				ret.append(
					{
					"name": &"Property Behavior",
					"type": TYPE_NIL,
					"usage": PROPERTY_USAGE_GROUP
					}
				)

				ret.append(
					{
					"name": &"propertyType",
					"type": TYPE_INT,
					"hint": PROPERTY_HINT_ENUM,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
					"hint_string": ",".join(PropertyType.keys())
					}
				)

#region Info subbroup
		ret.append(
			{
			"name": &"Marker Info",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
			}
		)

		ret.append(
			{
			"name": &"useDescription",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
			}
		)

		match markerType:
			Types.TRAVEL:
				if !useDescription:
					ret.append(
						{
						"name": &"hasCollectibleNotes",
						"type": TYPE_BOOL,
						"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
						}
					)
					ret.append(
						{
						"name": &"hasExploration",
						"type": TYPE_BOOL,
						"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
						}
					)
					ret.append(
						{
						"name": &"hasCollectibleItems",
						"type": TYPE_BOOL,
						"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
						}
					)
				else:
					hasExploration = false
					hasCollectibleItems = false
					hasCollectibleNotes = false
			Types.PROPERTY:
				ret.append(
					{
					"name": &"propertyPrice",
					"type": TYPE_INT,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
					}
				)
				ret.append(
					{
					"name": &"propertyID",
					"type": TYPE_STRING_NAME,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
					}
				)
				match propertyType:
					PropertyType.SCENE:
						ret.append(
							{
							"name": &"travelScene",
							"type": TYPE_OBJECT,
							"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
							}
						)

					PropertyType.REWARD:
						ret.append(
							{
							"name": &"propertyRewards",
							"type": TYPE_ARRAY,
							"hint": PROPERTY_HINT_RESOURCE_TYPE,
							"hint_string": "RewardDefinition",
							"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
							}
						)

				if propertyType == PropertyType.REWARD:
					if useDescription:
						ret.append(
							{
							"name": &"locationDescription",
							"type": TYPE_STRING,
							"hint": PROPERTY_HINT_MULTILINE_TEXT,
							"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
							}
						)
		#endregion
	return ret


func _on_button_pressed() -> void:
	if map:
		map.mapScreen.selectedMarker = self
