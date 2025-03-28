extends Control
#Idk if this is the best name but we'll call it this for now
class_name InteractiveCutscene

##stores scale_mode before cutscene was activated
var base_scale_mode
##stores mouse mode before cutscene was activated
var old_mouse_mode
##leaving the cutscene
var leaving
var canleave : bool = true

var doing : bool = false
var cutscene_return_value : Variant = null



func do() -> Variant:
	old_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var v = get_viewport()
	if v is Window:
		base_scale_mode = v.content_scale_mode
		v.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

	doing = true
	_do()
	while doing:
		await get_tree().process_frame
	return cutscene_return_value


func getEventSignal(event : StringName) -> Signal:
	event = &"__gameEventSignals__" + str(event)
	if !has_user_signal(event):
		add_user_signal(event)
	return Signal(self, event)


##override this for custom behavior.
func _do() -> void:
	print("_do called, override for custom behavior.")
	doing = false
	return


func _exit_tree() -> void:
	#Reset values when cutscene leaves the scenetree (the scene is exited)
	Input.mouse_mode = old_mouse_mode

	var v = get_viewport()
	if v is Window:
		v.content_scale_mode = base_scale_mode


func leave_cutscene() -> void:
	if !leaving:
		doing = false
		leaving = true
		await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
		queue_free()
		Fade.fade_in(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"gEscape"):
		get_viewport().set_input_as_handled()
		if canleave:
			leave_cutscene()
