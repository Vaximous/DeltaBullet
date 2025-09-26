extends PanelContainer



static var displaying : bool = false


static func display_text(text : String, duration : float = 5.0, abort_if_displaying : bool = false) -> Control:
	var scene = load("res://assets/scenes/ui/PopupMessage.tscn") as PackedScene
	var inst = scene.instantiate()
	Util.create_canvas_layer(100).add_child(inst)
	inst._display_text(text, duration, abort_if_displaying)
	return inst


func _display_text(text : String, duration : float = 5.0, abort_if_displaying : bool = false) -> void:
	if abort_if_displaying and displaying:
		queue_free()
		return
	await wait_for_finish()
	$animationPlayer.play("fadein")
	%label.text = text
	$timer.start(clamp(duration, 1.5, 60.0))
	displaying = true


func _on_timer_timeout() -> void:
	$animationPlayer.play("fadeout")
	if $animationPlayer.is_playing():
		await $animationPlayer.animation_finished
	displaying = false
	queue_free()


static func wait_for_finish() -> void:
	while displaying:
		await Engine.get_main_loop().process_frame
