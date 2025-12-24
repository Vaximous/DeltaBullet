extends MarginContainer

signal propertyPurchased

var mapScreen: CanvasLayer
@onready var rewardsBoxes : HBoxContainer = $popupVbox/contents/panelContainer/hSplitContainer/rewardsContainer/vBoxContainer/rewardsBox
@onready var rewardsContainer : ScrollContainer = $popupVbox/contents/panelContainer/hSplitContainer/rewardsContainer
@onready var animPlayer: AnimationPlayer = %animationPlayer


func _ready() -> void:
	initializePanel()


func initializePanel() -> void:
	animPlayer.play("open")
	await get_tree().process_frame
	rewardsContainer.hide()
	if mapScreen:
		mapScreen.screenBusy = true

	if has_meta(&"price"):
		%cost_sep.show()
		%cost_container.show()
		%grit_cost.show()
		%grit_cost_label.text = str(get_meta(&"price"))
	else:
		%cost_sep.hide()
		%cost_container.hide()
		%grit_cost.hide()

	if has_meta(&"price_dollen") and has_meta(&"price"):
		%vSeparator.show()
	else:
		%vSeparator.hide()

	if has_meta(&"price_dollen"):
		%cost_sep.show()
		%cost_container.show()
		%dollen_cost.show()
		%dollen_cost_label.text = str(get_meta(&"price_dollen"))
	else:
		%dollen_cost.hide()
		%dollen_cost_label.text = str(get_meta(&"price_dollen"))

	if has_meta(&"rewards"):
		if get_meta(&"rewards").size() > 0:
			rewardsContainer.show()
		for i in get_meta(&"rewards"):
			var display = i.rewardDisplay.instantiate()
			rewardsBoxes.add_child(display)


func close() -> void:
	animPlayer.play("close")
	if mapScreen:
		mapScreen.screenBusy = false


func purchase() -> void:
	if has_meta(&"price"):
		if gameState.getPawnCash() >= get_meta(&"price"):
			if has_meta(&"id"):
				gameState.AddProperty(get_meta(&"id"))
			if has_meta(&"rewards"):
				for i in get_meta(&"rewards"):
					match i.rewardType:
						i.RewardType.STAT:
							gameManager.give_stat_modifier(gameManager.getCurrentPawn(),i.rewardID)

			propertyPurchased.emit()
			gameState.addPawnCash(-get_meta(&"price"))
			Util.display_message_simple("Property Purchased")
			%successfulPurchase.play()
			close()
		else:
			Util.display_message_simple("Insufficient Funds", 5, true)
			%unsuccessfulPurchase.play()
			close()
