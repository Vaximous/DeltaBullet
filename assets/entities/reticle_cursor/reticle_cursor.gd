extends Node2D

@export_range(0, 32) var arcs: int = 4
@export var enable_center_radius: bool = true
@export var enable_radius: bool = true

@export var crosshair_color: Color = Color.WHITE

var reticle_rotation: float = 1.0
var reticle_rotation_speed: float = 2.0
var reticle_radius: float = 32.0
var reticle_cross_length: float = 8.0

var reticle_center: Vector2
var reticle_delayed_position_1: Vector2
var reticle_delayed_position_2: Vector2


func _process(delta: float) -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if enable_radius:
		reticle_center = lerp(reticle_center, get_global_mouse_position(), delta * 30)
	reticle_delayed_position_1 = lerp(reticle_delayed_position_1, reticle_center, delta * 30)
	reticle_delayed_position_2 = lerp(reticle_delayed_position_2, reticle_delayed_position_1, delta * 30)
	if enable_center_radius:
		reticle_radius = lerp(reticle_radius, reticle_delayed_position_2.distance_to(reticle_center) * 0.1 + 24, delta * 5.0)

	reticle_rotation += reticle_rotation_speed * delta
	queue_redraw()


func _draw() -> void:
	#Draw arcs at 1/8 -> 2/8, 3/8 -> 4/8, 5/8->6/8, 7/8->8/8
	if enable_center_radius:
		draw_circle(reticle_center, reticle_radius / 8.0, crosshair_color, false, 0.5, true)
	if enable_radius:
		draw_circle(reticle_delayed_position_1.lerp(reticle_center, 0.5), reticle_radius / 2.0, crosshair_color, false, 0.5, true)
	#Arcs
	for i in arcs:
		var arc_start_angle: float = ((2 * i) / 8.0 * PI * 2.0) + reticle_rotation
		var arc_end_angle: float = (((2 * i) + 1) / 8.0 * PI * 2.0) + reticle_rotation
		draw_arc(reticle_delayed_position_1, reticle_radius, arc_start_angle, arc_end_angle, 4, crosshair_color)
		#Draw lines between gaps
		draw_line(reticle_delayed_position_2 + Vector2.UP.rotated(arc_start_angle - (2 / 16.0 * PI)) * reticle_radius,
			reticle_delayed_position_2 + Vector2.UP.rotated(arc_start_angle - (2 / 16.0 * PI)) * (reticle_radius + reticle_cross_length),
			crosshair_color)
