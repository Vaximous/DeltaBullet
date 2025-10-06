extends CanvasLayer

#const gamestate_editor_delete_button: PackedScene = preload("res://scenes/UI/elements/gamestate_editor_delete_button.tscn")

@export_file("*.tscn", "*.scn") var available_levels: PackedStringArray
@export var gamestate_editor_panel_style: StyleBoxFlat

var gs_editor_update_index: int = 0
var gs_editor_open_dictionaries: Array
var dev_button_hold_time: float = 0.0


func _ready() -> void:
	#if not Util.is_editor():
		#hide()
	#PlayerProgression.task_added.connect(_on_task_added.unbind(2))
	$ToolsPanel.hide()
	$GamestateViewerPanel.hide()
	$ProgressionViewPanel.hide()
	#for level in available_levels:
		#var button: Button = Button.new()
		#var data = Util.get_scene_data(load(level), "level_data")
		#if data is WorldData:
			#button.text = data.level_name
			#button.tooltip_text = data.level_description + "\n\n" + level
		#else:
			#button.text = level.get_file().get_basename()
			#button.tooltip_text = level
		#%LevelSelectionContainer.add_child(button)
		#button.pressed.connect(gameManager.loadScene.bind(level))


func _physics_process(delta: float) -> void:
	var n = get_tree().get_nodes_in_group(&"gamestate_editor_controller")
	if not n.is_empty():
		gs_editor_update_display(n)
	var n2 = get_tree().get_nodes_in_group(&"progression_viewer_nodes")
	if not n2.is_empty():
		progression_viewer_update_display(n2)

	if Input.is_action_pressed("dev_menu_toggle"):
		dev_button_hold_time += delta
		if dev_button_hold_time >= 1.0:
			visible = !visible
			dev_button_hold_time = 0.0
	else:
		dev_button_hold_time = 0.0


func refresh_progression_view() -> void:
	Util.queueFreeNodeChildren(%ProgressionViewContainer)
	var progression_achievements = get_tree().get_nodes_in_group(&"achievement_tasks")
	var progression_tasks = get_tree().get_nodes_in_group(&"checklist_tasks")

	var achievements_display := FoldableContainer.new()
	#achievements_display.title = "Achievements \t %d / %d" % [PlayerProgression.get_completed_achievements().size(), progression_achievements.size()]
	achievements_display.title_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievements_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_display.folded = true
	var ach_vbox := VBoxContainer.new()
	achievements_display.add_child(ach_vbox)
	var task_display := FoldableContainer.new()
	#task_display.title = "Tasks \t %d / %d" % [PlayerProgression.get_completed_tasks().size(), progression_tasks.size()]
	task_display.title_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task_display.folded = true
	var task_vbox := VBoxContainer.new()
	task_display.add_child(task_vbox)

	%ProgressionViewContainer.add_child(achievements_display)
	%ProgressionViewContainer.add_spacer(false)
	%ProgressionViewContainer.add_child(HBoxContainer.new())
	%ProgressionViewContainer.add_spacer(false)
	%ProgressionViewContainer.add_child(task_display)

	#for ach in progression_achievements:
		#if ach is AchievementTask:
			#var foldcontainer := FoldableContainer.new()
			#foldcontainer.title = "%s : %0.1f%%" % [ach.achievement_name, ach.get_progress_percentage() * 100]
			#foldcontainer.title_alignment = HORIZONTAL_ALIGNMENT_CENTER
			#foldcontainer.fold()
			#ach_vbox.add_child(foldcontainer)
			#var ach_foldvbox := VBoxContainer.new()
			#foldcontainer.add_child(ach_foldvbox)
#
			#var desc := Label.new()
			#desc.text = ach.description
			#desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			#desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#desc.autowrap_mode = TextServer.AUTOWRAP_WORD
			#ach_foldvbox.add_child(desc)
#
			#if not ach.unlock_requirements.is_empty():
				#var no_req_label := Label.new()
				#no_req_label.text = "requirement\n" + ach.unlock_requirements
				#no_req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				#no_req_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				#no_req_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				#ach_foldvbox.add_child(no_req_label)
				#if not ach._has_requirements():
					#no_req_label.modulate.v = 0.6
#
			#if ach.is_secret():
				#var secret_label := Label.new()
				#secret_label.text = "(secret!)"
				#secret_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				#secret_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				#secret_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				#foldcontainer.modulate.a = 0.6
				#foldcontainer.modulate.g = 0.8
				#ach_foldvbox.add_child(secret_label)
#
			#var progress := ProgressBar.new()
			#progress.value = ach.get_progress_percentage() * 100.0
			##progress.show_percentage = false
			#if ach.is_completed():
				#progress.modulate = Color.GREEN_YELLOW
			#else:
				#progress.modulate = Color.YELLOW
			#ach_foldvbox.add_child(progress)

	#for task in progression_tasks:
		#if task is ChecklistTask:
			#var foldcontainer := FoldableContainer.new()
			#foldcontainer.title = "%s : %0.1f%%" % [task.task_name, task.get_progress_percentage() * 100]
			#foldcontainer.title_alignment = HORIZONTAL_ALIGNMENT_CENTER
			#foldcontainer.fold()
			#task_vbox.add_child(foldcontainer)
			#var task_foldvbox := VBoxContainer.new()
			#foldcontainer.add_child(task_foldvbox)
#
			#var desc := Label.new()
			#desc.text = task.description
			#desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			#desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#desc.autowrap_mode = TextServer.AUTOWRAP_WORD
			#task_foldvbox.add_child(desc)
#
			#if not task.unlock_requirements.is_empty():
				#var no_req_label := Label.new()
				#no_req_label.text = "requirement\n" + task.unlock_requirements
				#no_req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				#no_req_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				#no_req_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				#task_foldvbox.add_child(no_req_label)
				#if not task._has_requirements():
					#no_req_label.modulate.v = 0.6
#
			#var progress := ProgressBar.new()
			#progress.value = task.get_progress_percentage() * 100.0
			##progress.show_percentage = false
			#if task.is_completed():
				#progress.modulate = Color.GREEN_YELLOW
			#else:
				#progress.modulate = Color.YELLOW
			#task_foldvbox.add_child(progress)
	$ProgressionViewPanel.size.x = 10


func create_dictionary_view(dict: Dictionary, top_key_name: Variant, depth: int = 0) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.custom_minimum_size.x = 256
	var style_dup: StyleBoxFlat = gamestate_editor_panel_style.duplicate()
	style_dup.border_color.h = depth * 0.12
	style_dup.bg_color.h = depth * 0.12
	pc.set("theme_override_styles/panel", style_dup)

	var mc: MarginContainer = MarginContainer.new()
	mc.set("theme_override_constants/margin_left", 4)
	mc.set("theme_override_constants/margin_right", 4)
	mc.set("theme_override_constants/margin_top", 4)
	mc.set("theme_override_constants/margin_bottom", 4)
	pc.add_child(mc)
	var vbox: VBoxContainer = VBoxContainer.new()
	mc.add_child(vbox)

	if depth == 0:
		var label: Label = Label.new()
		label.text = str(top_key_name)
		vbox.add_child(label)

	var toggle_vis_button: Button = Button.new()
	toggle_vis_button.text = "+"
	vbox.add_child(toggle_vis_button)

	var contents_vbox := VBoxContainer.new()
	vbox.add_child(contents_vbox)
	contents_vbox.add_child(HSeparator.new())
	if not gs_editor_open_dictionaries.has(top_key_name):
		contents_vbox.hide()

	toggle_vis_button.pressed.connect(


		func togglevis() -> void:
		contents_vbox.visible = !contents_vbox.visible; toggle_vis_button.text = "-" if contents_vbox.visible else "+"
		if contents_vbox.visible:
			gs_editor_set_key_open(top_key_name)
		else:
			gs_editor_set_key_close(top_key_name)
	)

	if dict.is_empty():
		var empty_label := Label.new()
		empty_label.text = "{ EMPTY }"
		contents_vbox.add_child(empty_label)
	else:
		for key in dict.keys():
			if key is String:
				if key.begins_with("_") and !Util.is_editor():
					continue

			var dict_vbox := VBoxContainer.new()
			contents_vbox.add_child(dict_vbox)
			dict_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var label_hbox := HBoxContainer.new()
			dict_vbox.add_child(label_hbox)

			var key_label := Label.new()
			key_label.text = str(key)
			label_hbox.add_child(key_label)

			#var del_btn_inst = gamestate_editor_delete_button.instantiate()
			#label_hbox.add_child(del_btn_inst)

			var value = dict[key]

			var nested_element = make_ui_for_variant(key, value, dict, depth)
			dict_vbox.add_child(nested_element)

			#del_btn_inst.doublepressed.connect(gs_editor_delete_key.bind(dict, key, [label_hbox, nested_element]))
	return pc


func gs_editor_set_key_open(key) -> void:
	if !gs_editor_open_dictionaries.has(key):
		gs_editor_open_dictionaries.append(key)


func gs_editor_set_key_close(key) -> void:
	if gs_editor_open_dictionaries.has(key):
		gs_editor_open_dictionaries.erase(key)


func gs_editor_delete_key(dict: Dictionary, key: Variant, controls_to_hide: Array) -> void:
	dict.erase(key)
	for ctrl in controls_to_hide:
		ctrl.hide()
	#refresh_gamestate_viewer()


func make_ui_for_variant(key: Variant, value: Variant, holder: Variant, depth: int = 0) -> Control:
	if not holder is Dictionary:
		if not holder is Array:
			assert(false, "'holder' must be Dictionary or Array")

	match typeof(value):
		TYPE_BOOL:
			return gs_editor_create_checkbox(key, value, holder)
		TYPE_INT:
			return gs_editor_create_spinbox(key, float(value), 1.0, holder)
		TYPE_FLOAT:
			return gs_editor_create_spinbox(key, float(value), 0.001, holder)
		TYPE_STRING:
			return gs_editor_create_lineedit(key, value, holder)
		TYPE_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_INT32_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_FLOAT32_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_INT64_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_FLOAT64_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_STRING_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_PACKED_BYTE_ARRAY:
			return gs_editor_create_nested_array(key, value, holder)
		TYPE_DICTIONARY:
			return gs_editor_create_nested_dictionary(key, value, depth)
	var unhandled_label: Label = Label.new()
	unhandled_label.text = str(value)
	unhandled_label.modulate.v = 0.6
	unhandled_label.mouse_filter = Control.MOUSE_FILTER_STOP
	unhandled_label.tooltip_text = "(unhandled type %d)" % typeof(value)
	return unhandled_label


func gs_editor_create_nested_array(dict_key: Variant, array: Array, holder: Variant) -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	if array.is_empty():
		var empty_label := Label.new()
		empty_label.text = "[ EMPTY ]"
		vbox.add_child(empty_label)
	else:
		for idx in array.size():
			var n = array[idx]
			vbox.add_child(make_ui_for_variant(int(idx), n, array))
	vbox.add_to_group(&"gamestate_editor_controller")
	vbox.set_meta("holder", holder)
	vbox.set_meta("dict_key", dict_key)
	vbox.set_meta("array_size", array.size())
	return vbox


func gs_editor_create_nested_dictionary(dict_key: Variant, dict: Dictionary, depth: int) -> PanelContainer:
	var panel = create_dictionary_view(dict, dict_key, depth + 1)
	panel.add_to_group(&"gamestate_editor_controller")
	return panel


func gs_editor_create_checkbox(dict_key: Variant, pressed: bool, holder: Variant) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.button_pressed = pressed
	checkbox.toggled.connect(func(b): holder[dict_key] = b
	)
	checkbox.add_to_group(&"gamestate_editor_controller")
	checkbox.set_meta("holder", holder)
	checkbox.set_meta("dict_key", dict_key)
	return checkbox


func gs_editor_create_spinbox(dict_key: Variant, value: float, step: float, holder: Variant) -> SpinBox:
	var sb := SpinBox.new()
	sb.allow_lesser = true
	sb.allow_greater = true
	sb.max_value = 10000000
	sb.min_value = -10000000
	sb.value = value
	sb.step = step
	sb.value_changed.connect(func(n): holder[dict_key] = n)
	sb.add_to_group(&"gamestate_editor_controller")
	sb.set_meta("holder", holder)
	sb.set_meta("dict_key", dict_key)
	return sb


func gs_editor_create_lineedit(dict_key: Variant, text: String, holder: Variant) -> LineEdit:
	var le := LineEdit.new()
	le.text = text
	le.text_submitted.connect(func(new_text): holder[dict_key] = new_text)
	le.add_to_group(&"gamestate_editor_controller")
	le.set_meta("holder", holder)
	le.set_meta("dict_key", dict_key)
	return le


func refresh_gamestate_viewer() -> void:
	Util.queueFreeNodeChildren(%GamestateEditorContainer)
	%GamestateEditorContainer.add_child(
		create_dictionary_view(gameState._gameState, "gameState")
	)
	return


func progression_viewer_update_display(node_array: Array[Node]) -> void:
	var search_count = min(10, node_array.size())
	while search_count > 0:
		var update_node = node_array[gs_editor_update_index % node_array.size()]
		if update_node == node_array.back():
			search_count = 0
		gs_editor_update_index += 1

		if update_node is Control:
			if update_node.has_focus() or not update_node.is_visible_in_tree():
				continue
		search_count -= 1

		match update_node.get_meta(&"type"):
			_:
				return


func gs_editor_update_display(node_array: Array[Node]) -> void:
	var search_count = min(10, node_array.size())
	while search_count > 0:
		var update_node = node_array[gs_editor_update_index % node_array.size()]
		if update_node == node_array.back():
			search_count = 0
		gs_editor_update_index += 1

		if update_node is Control:
			if update_node.has_focus() or not update_node.is_visible_in_tree():
				continue
		search_count -= 1

		if update_node is SpinBox:
			var new_value = update_node.get_meta("holder")[update_node.get_meta("dict_key")]
			if new_value != update_node.value:
				#print("Updated [%s], from %s -> %s" % [update_node.get_meta("dict_key"), update_node.value, new_value])
				update_node.set_block_signals(true)
				update_node.value = new_value
				update_node.set_block_signals(false)

		if update_node is LineEdit:
			var new_value = update_node.get_meta("holder")[update_node.get_meta("dict_key")]
			if new_value != update_node.text:
				#print("Updated [%s], from %s -> %s" % [update_node.get_meta("dict_key"), update_node.text, new_value])
				update_node.set_block_signals(true)
				update_node.text = new_value
				update_node.set_block_signals(false)

		if update_node is CheckBox:
			var new_value = update_node.get_meta("holder")[update_node.get_meta("dict_key")]
			if new_value != update_node.button_pressed:
				#print("Updated [%s], from %s -> %s" % [update_node.get_meta("dict_key"), update_node.button_pressed, new_value])
				update_node.set_block_signals(true)
				update_node.button_pressed = new_value
				update_node.set_block_signals(false)

		if update_node is VBoxContainer:
			var size = update_node.get_meta("array_size", 0)
			var new_value = update_node.get_meta("holder")[update_node.get_meta("dict_key")]
			#Array size mismatch. Repopulate the VBox
			if new_value.size() != size:
				#print("Array size mismatch!")
				Util.queueFreeNodeChildren(update_node)
				if new_value.is_empty():
					var empty_label := Label.new()
					empty_label.text = "[ EMPTY ]"
					update_node.add_child(empty_label)
				else:
					for idx in new_value.size():
						var n = new_value[idx]
						update_node.add_child(make_ui_for_variant(int(idx), n, new_value))
				break


func _on_tools_menu_button_toggled(toggled_on: bool) -> void:
	$ToolsPanel.visible = toggled_on


func _on_gamestate_viewer_button_toggled(toggled_on: bool) -> void:
	$GamestateViewerPanel.visible = toggled_on
	if toggled_on and %GamestateEditorContainer.get_child_count() == 0:
		refresh_gamestate_viewer()


func _on_progression_view_toggled(toggled_on: bool) -> void:
	$ProgressionViewPanel.visible = toggled_on
	if toggled_on:
		refresh_progression_view()


#func _on_go_to_shop_pressed() -> void:
	#if not GameManager.collected_loot.is_empty():
		#GameManager.set_scene("res://scenes/UI/sell_chute.tscn")
	#else:
		#GameManager.set_scene("res://scenes/UI/Shop/shop_new.tscn")


func _on_task_added() -> void:
	refresh_progression_view()
#
#
#func _on_max_fuel_button_pressed() -> void:
	#var sub = GameManager.get_player_sub()
	#if sub != null:
		#sub.fuel = INF
	#pass # Replace with function body.


#func _on_disable_fuel_drain_toggled(toggled_on: bool) -> void:
	#if toggled_on:
		#var dup = %FuelDrainStatMod.duplicate()
		#var sub = GameManager.get_player_sub()
		#var stack = Util.get_modifier_stack(sub)
		#if stack == null:
			#%DisableFuelDrain.set_pressed_no_signal(false)
			#return
		#stack.add_child(dup)
		#set_meta("fuel_drain_stat_mod", dup)
		#sub.tree_exiting.connect(%DisableFuelDrain.set.bind("button_pressed", false))
	#else:
		#if has_meta("fuel_drain_stat_mod"):
			#var existing = get_meta("fuel_drain_stat_mod", null)
			#if is_instance_valid(existing):
				#existing.queue_free()
			#remove_meta("fuel_drain_stat_mod")


func _on_refresh_button_pressed() -> void:
	refresh_gamestate_viewer()


func _on_timescale_drag_ended(value_changed: bool) -> void:
	if value_changed:
		%Timescale.value = max(%Timescale.value, 0.1)
		Engine.time_scale = %Timescale.value
	pass # Replace with function body.


func _on_change_level_button_pressed() -> void:
	Console.cvars.maps()


func _on_god_mode_toggle_toggled(toggled_on: bool) -> void:
	gameManager.godmode()
