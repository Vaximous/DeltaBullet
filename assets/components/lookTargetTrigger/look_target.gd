extends Marker3D



@export var player_detect_radius : float = 12.0
##lower values = must be looking directly at, higher values = when roughly on screen
@export var screen_center_ratio : float = 0.3
@export var look_time_to_trigger : float = 0.5
@export var trigger_on_look_away : bool = false
var look_time : float = 0.0


func _ready() -> void:
	var sphere = SphereShape3D.new()
	sphere.radius = player_detect_radius
	$Area3D/CollisionShape3D.shape = sphere


signal look_trigger
var looked_at : bool = false
func _physics_process(delta: float) -> void:
	if looked_at:
		return
	var cam = get_viewport().get_camera_3d()
	if $Area3D.has_overlapping_bodies():
		if cam != null:
			if is_looked_at(cam):
				look_time += delta
				if look_time > look_time_to_trigger:
					looked_at = true
					if trigger_on_look_away:
						print("Waiting to look away...")
						while is_looked_at(cam):
							await get_tree().process_frame
					look_trigger.emit()
					print("Looked at me!")


func is_looked_at(camera : Camera3D) -> bool:
	var screen_pos = camera.unproject_position(global_position)
	var center_screen = get_viewport().size / 2.0
	var ratio = (center_screen.distance_to(screen_pos) / get_viewport().size.length()) * 2.0
	return ratio < screen_center_ratio


func reset() -> void:
	look_time = 0.0
	looked_at = false
