extends Node3D

var camRotation: Vector3 = Vector3.ZERO

@onready var customCharacter: BasePawn = $pawnEntity
@onready var inputComponent: InputComponent = $inputComponent
@onready var horizOffset: Node3D = $horizOffset
@onready var vertOffset: Node3D = $horizOffset/vertOffset


func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		gameManager.hideMouse()
	else:
		gameManager.showMouse()

	if Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED or Input.mouse_mode == Input.MouseMode.MOUSE_MODE_HIDDEN:
		if event is InputEventMouseMotion:
			horizOffset.rotation_degrees.y += rad_to_deg(-event.relative.x * UserConfig.game_control_mouseSens * 0.1)
			vertOffset.rotation_degrees.x += rad_to_deg(-event.relative.y * UserConfig.game_control_mouseSens * 0.1)
				#Lock Cam
			vertOffset.rotation.x = clamp(vertOffset.rotation.x, deg_to_rad(-20), deg_to_rad(20))
