@tool
extends EditorPlugin

## Preload the main panel scene
const MainPanel := preload("res://addons/cutsceneMaker/ui/cutsceneMaker.tscn")
const PLUGIN_NAME := "Cutscene Creator"
const PLUGIN_HANDLER_PATH := "res://addons/cutscenemaker/cutscenemaker.gd"
const PLUGIN_ICON_PATH := "res://addons/cutsceneMaker/ico.png"

## References used by various other scripts to quickly reference these things
var editorView: Control  # the root of the cutscene editor

## Signal emitted if godot wants us to save
signal cutscene_save

## Initialization
func _init() -> void:
	self.name = "PawnEngineCSPlugin"

#region ACTIVATION & EDITOR SETUP
################################################################################
## Activation & Editor Setup
func _enable_plugin():
	add_autoload_singleton(PLUGIN_NAME, PLUGIN_HANDLER_PATH)

func _disable_plugin():
	remove_autoload_singleton(PLUGIN_NAME)

func _enter_tree() -> void:
	editorView = MainPanel.instantiate()
	editorView.plugin_reference = self
	editorView.hide()
	get_editor_interface().get_editor_main_screen().add_child(editorView)
	_make_visible(false)
	# Auto-update the singleton path for alpha users
	# TODO remove at some point during beta or later
	remove_autoload_singleton(PLUGIN_NAME)
	add_autoload_singleton(PLUGIN_NAME, PLUGIN_HANDLER_PATH)

func _exit_tree() -> void:
	if editorView:
		remove_control_from_bottom_panel(editorView)
		editorView.queue_free()
#endregion

#region PLUGIN_INFO
################################################################################
func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon():
	return load(PLUGIN_ICON_PATH)
#endregion

#region EDITOR INTERACTION
################################################################################
## Editor Interaction
func _make_visible(visible:bool) -> void:
	if not editorView:
		return

	if editorView.get_parent() is Window:
		if visible:
			get_editor_interface().set_main_screen_editor("Script")
			editorView.show()
			editorView.get_parent().grab_focus()
	else:
		editorView.visible = visible

func _save_external_data() -> void:
	if _editorView_and_manager_exist():
		editorView.editors_manager.save_current_resource()

func _handles(object) -> bool:
	if _editorView_and_manager_exist() and object is Resource:
		return editorView.editors_manager.can_edit_resource(object)
	return false

func _edit(object) -> void:
	if object == null:
		return
	_make_visible(true)
	if _editorView_and_manager_exist():
		editorView.editors_manager.edit_resource(object)

## Helper function to check if editorView and its manager exist
func _editorView_and_manager_exist() -> bool:
	return editorView and editorView.editors_manager
#endregion
