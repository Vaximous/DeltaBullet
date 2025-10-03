extends Node3D

var camRotation: Vector3 = Vector3.ZERO

@onready var customCharacter: BasePawn = $pawnEntity
@onready var inputComponent: InputComponent = $inputComponent
@onready var horizOffset: Node3D = $horizOffset
@onready var vertOffset: Node3D = $horizOffset/vertOffset


func _on_input_component_on_mouse_motion(motion):
	if motion is InputEventMouseMotion:
		horizOffset.rotation_degrees.y += rad_to_deg(-motion.relative.x * gameManager.mouseSens)
		vertOffset.rotation_degrees.x += rad_to_deg(-motion.relative.y * gameManager.mouseSens)
			#Lock Cam
		vertOffset.rotation.x = clamp(vertOffset.rotation.x, deg_to_rad(-60), deg_to_rad(88))
