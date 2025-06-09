@tool
extends Marker3D
class_name AIMarker
@export_category("AI Marker")
@onready var markerMesh : MeshInstance3D = $MarkerMesh
@onready var markerLabel : Label3D = $MarkerMesh/markerLabel
@export_enum("Walkable","Cover","Jump") var markerType : int = 0:
	set(value):
		markerType = value
		setVisual()


func _ready() -> void:
	if Engine.is_editor_hint():
		if markerMesh:
			markerMesh.show()
	else:
		if markerMesh:
			markerMesh.hide()


func setVisual()->void:
	match markerType:
		0:
			if Engine.is_editor_hint():
				var _material:StandardMaterial3D = StandardMaterial3D.new()
				markerMesh.material_override = _material
				_material.albedo_color = Color.WHITE
				markerLabel.modulate = Color.WHITE
			markerLabel.text = "Walk Marker"
		1:
			if Engine.is_editor_hint():
				var _material:StandardMaterial3D = StandardMaterial3D.new()
				markerMesh.material_override = _material
				_material.albedo_color = Color.GREEN
				markerLabel.modulate = Color.GREEN
			markerLabel.text = "Cover Marker"
		2:
			if Engine.is_editor_hint():
				var _material:StandardMaterial3D = StandardMaterial3D.new()
				markerMesh.material_override = _material
				_material.albedo_color = Color.BLUE
				markerLabel.modulate = Color.BLUE
			markerLabel.text = "Jump Marker"
