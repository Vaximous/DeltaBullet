extends Node



@export var text : String = ""
@export_range(1.5, 10.0, 0.1) var duration : float = 5.0
@export var abort_if_displaying : bool = true


func display_text() -> void:
	if text == "":
		return
	Util.display_message_simple(text, duration, abort_if_displaying)
