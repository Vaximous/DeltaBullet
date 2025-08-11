extends Node3D
@onready var area3d : Area3D = $area3d
signal selectedMarker(node:Node3D)
@export var map : Node3D


func selectMarker(marker:Area3D):
	if map.mapScreen.selectedMarker:
		#Deselected
		if map.mapScreen.selectedMarker.isLocationCurrent():
			map.mapScreen.selectedMarker.setMarkerMaterial(load(marker.owner.map.markerColors[1]))
			map.mapScreen.selectedMarker.fadeIconIn()
		else:
			map.mapScreen.selectedMarker.setMarkerMaterial(load(marker.owner.map.markerColors[0]))
	map.mapScreen.selectedMarker = marker.owner
	marker.owner.clickSound.play()
	#Selected
	if marker.owner.isLocationCurrent():
		marker.owner.setMarkerMaterial(load(marker.owner.map.markerColors[1]))
		marker.owner.fadeIconIn()
	else:
		marker.owner.setMarkerMaterial(load(marker.owner.map.markerColors[2]))
	selectedMarker.emit(marker.owner)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("gLeftClick"):
		var areas = area3d.get_overlapping_areas()
		if !areas.is_empty():
			selectMarker(areas[0])


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.owner.has_method("playOpenAnimation"):
		area.owner.playOpenAnimation()
		area.owner.hoverSound.play()


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.owner.has_method("playCloseAnimation"):
		area.owner.playCloseAnimation()
