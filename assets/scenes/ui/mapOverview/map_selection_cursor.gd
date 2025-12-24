extends Node3D

signal selectedMarker(node: Node3D)

@export var map: Node3D

@onready var area3d: Area3D = $area3d
@onready var markerIcon: Sprite3D = $markerIcon


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gLeftClick"):
		var areas = area3d.get_overlapping_areas()
		if !areas.is_empty():
			selectMarker(areas[0])
		else:
			deselectMarker()


func selectMarker(marker: Area3D):
	if !marker.owner.enabled: return

	if map.mapScreen.selectedMarker:
		#Deselected
		if map.mapScreen.selectedMarker.isLocationCurrent():
			map.mapScreen.selectedMarker.setMarkerMaterial(load(marker.owner.map.markerColors[1]))
			map.mapScreen.selectedMarker.fadeIconIn()
		else:
			map.mapScreen.selectedMarker.setMarkerMaterial(load(marker.owner.map.markerColors[0]))
	map.mapScreen.selectedMarker = marker.owner
	if !map.owner.areaInfo.isTravelHovered:
		marker.owner.clickSound.play()
	#Selected
	if marker.owner.isLocationCurrent():
		marker.owner.setMarkerMaterial(load(marker.owner.map.markerColors[1]))
		marker.owner.fadeIconIn()
	else:
		marker.owner.setMarkerMaterial(load(marker.owner.map.markerColors[2]))
	selectedMarker.emit(marker.owner)
	#map.setCameraPositionAndRotation(Vector3(global_position.x,map.cameraController.global_position.y,global_position.z),Vector3.ZERO,1)


func deselectMarker() -> void:
	if map.mapScreen.selectedMarker:
		var oldSel = map.mapScreen.selectedMarker
		oldSel.fadeIconOut()
		oldSel.setMarkerMaterial(load(oldSel.map.markerColors[0]))
		if !map.owner.areaInfo.isTravelHovered:
			oldSel.clickSound.play()
	map.mapScreen.selectedMarker = null
	selectedMarker.emit(null)


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.owner.has_method("playOpenAnimation"):
		if area.owner.enabled:
			area.owner.playOpenAnimation()
			area.owner.hoverSound.play()


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.owner.has_method("playCloseAnimation"):
		if area.owner.enabled:
			area.owner.playCloseAnimation()
