@tool extends MarginContainer
@export_category("Editor Item")
@onready var itemHolder = %itemHolder
@onready var button : Button = $button
## What item is this?
@export var placeableObject : PackedScene:
	set(value):
		placeableObject = value
		if is_instance_valid(itemHolder):
			for i in itemHolder.get_children():
				i.queue_free()

			var inst = placeableObject.instantiate()
			itemHolder.add_child(inst)
			if inst is RigidBody3D:
				inst.freeze = true

func enlargeControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1.1,1.1),gameManager.defaultTweenSpeed).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)


func resetControlScale(control:Control)->void:
	var tween = create_tween()
	tween.tween_property(control,"scale",Vector2(1,1),gameManager.defaultTweenSpeed).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)



func _process(delta: float) -> void:
	if itemHolder.rotation.y >= 180:
		itemHolder.rotation.y = 0

	itemHolder.rotation.y += 0.55 * delta

func playHoverSound()->void:
	if !%hoverSound.playing:
		%hoverSound.play()


func playEquipSound()->void:
	if !%equipSound.playing:
		%equipSound.play()


func _on_button_focus_entered() -> void:
	enlargeControlScale(self)
	playHoverSound()

func _on_button_focus_exited() -> void:
	resetControlScale(self)
	playHoverSound()


func _on_button_mouse_entered() -> void:
	enlargeControlScale(self)
	playHoverSound()


func _on_button_mouse_exited() -> void:
	resetControlScale(self)
	playHoverSound()
