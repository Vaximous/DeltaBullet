@tool
extends PanelContainer

const gizmo_plugin := preload("res://addons/airducteditorgizmotool/airduct_gizmo_plugin.gd")


signal part_selected


func setup_available_parts(for_part : String) -> void:
	var available : Array[String]

	#name , scene
	for k in gizmo_plugin.Segments:
		available.append(k)

	match for_part:
		"OmniSplit":
			available.erase("OmniSplit")
			pass
		gizmo_plugin.Segments.Left45:
			pass
		gizmo_plugin.Segments.Right45:
			pass
		gizmo_plugin.Segments.DuctConnector:
			pass
		gizmo_plugin.Segments.LongAirduct:
			pass
		gizmo_plugin.Segments.Left90:
			pass
		gizmo_plugin.Segments.Right90:
			pass
		gizmo_plugin.Segments.Single:
			pass
		gizmo_plugin.Segments.VentDown:
			pass
		gizmo_plugin.Segments.VentLeft:
			pass
		gizmo_plugin.Segments.VentRight:
			pass
		gizmo_plugin.Segments.TSplit:
			pass

	for part_name in available:
		var button : Button = Button.new()
		button.text = part_name
		match part_name:
			"Left45":
				button.text += "// A"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_left_45.tres")
			"Left90":
				button.text += "// Shift+A"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_left_90.tres")
			"Right45":
				button.text += "// D"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_right_45.tres")
			"Right90":
				button.text += "// Shift+D"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_right_90.tres")
			"Single":
				button.text += "// W"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_forward.tres")
			"LongAirduct":
				button.text += "// Shift+W"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_forward_double.tres")
			"TSplit":
				button.text += "// T"
				button.shortcut = preload("res://addons/airducteditorgizmotool/shortcut_Tsplit.tres")
		button.pressed.connect(_on_button_pressed.bind(part_name))
		%OptionsContainer.add_child(button)


func _on_button_pressed(part_name : String) -> void:
	part_selected.emit(part_name)
	queue_free()
