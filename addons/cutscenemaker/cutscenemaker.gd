@tool
extends EditorPlugin
@onready var panel = $panel
@onready var vpContainer = $panel/subViewportContainer

func _enter_tree()->void:
	var viewport = EditorInterface.get_editor_viewport_3d(0)
	vpContainer.add_child(viewport.duplicate())
	pass

func _exit_tree()->void:
	# Clean-up of the plugin goes here.
	pass
