extends Sprite2D


var velocity : Vector2
var rotational_velocity : float


#Instantiate and use this function
func spawn_at_location(parent : Node, location : Vector2) -> void:
	parent.add_child(self)
	global_position = location
	rotation = randf_range(-PI, PI)
	velocity.y = randf_range(-700, -850)
	velocity.x = randf_range(-50, 250) #go to right more often
	rotational_velocity = randf_range(-100, 100)


func _process(delta: float) -> void:
	velocity.y += delta * 4500
	rotation += rotational_velocity * delta
	global_position += velocity * delta


func fade_out() -> void:
	if has_meta(&"fading"):
		return
	set_meta(&"fading", true)
	while scale.length() > 0.01:
		scale *= 0.98
		await get_tree().process_frame
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	fade_out()


func _on_lifetime_timeout() -> void:
	fade_out()
