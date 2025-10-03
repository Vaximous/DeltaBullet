extends Control

var popup : PackedScene = preload("res://assets/scenes/ui/mapOverview/MapPopup.tscn")
@export var map: CanvasLayer

var tween: Tween
var marker:
	set(value):
		marker = value
		#print(value)
		setInfo(marker)
var isTravelHovered: bool = false:
	set(value):
		isTravelHovered = value
		if value:
			%animationPlayer.play("travelButtonHover")
		else:
			%animationPlayer.play("travelButtonunHover")


func _ready() -> void:
	%travelButton.focus_entered.connect(setIsHovered.bind(true))
	%travelButton.mouse_entered.connect(setIsHovered.bind(true))
	%travelButton.mouse_exited.connect(setIsHovered.bind(false))
	%travelButton.focus_exited.connect(setIsHovered.bind(false))


func evaluateSelectedMarker() -> void:
	if marker:
		match marker.markerType:
			marker.Types.TRAVEL:
				marker.gotoLocation()
			marker.Types.PROPERTY:
				#Open a purchase dialog box, if its a reward then it will display the reward
				#the player should get, if its a place that becomes unlocked just show that
				if marker.propertyType == marker.PropertyType.SCENE and marker.propertyStatus == marker.PropertyState.Purchased:
					marker.gotoLocation()

				match marker.propertyStatus:
					marker.PropertyState.Locked:
						%travelButton.hide()
						var clayer = Util.create_canvas_layer(3)
						var _popup = popup.instantiate()
						clayer.add_child(_popup)
						_popup.set_meta(&"price",marker.propertyPrice)
						_popup.set_meta(&"id",marker.propertyID)
						_popup.propertyPurchased.connect(marker.setPropertyState.bind(marker.PropertyState.Purchased))
						_popup.mapScreen = map
						_popup.add_to_group(&"purchaseMapAreaPopup")
						_popup.tree_exited.connect(setInfo.bind(marker))
						_popup.tree_exited.connect(clayer.queue_free)
					marker.PropertyState.Purchased:
						match marker.propertyType:
							marker.PropertyType.REWARD:
								%travelButton.hide()
							marker.PropertyType.SCENE:
								%travelButton.show()
								%travelButton.text = "TRAVEL"


func playTravelSound() -> void:
	if marker:
		match marker.markerType:
			marker.Types.TRAVEL:
				gameManager.playSound(preload("res://assets/sounds/ui/map/travelRandomizer.tres"), -15)
				#marker.gotoLocation()
			marker.Types.PROPERTY:
				if marker.propertyType == marker.PropertyType.SCENE:
					gameManager.playSound(preload("res://assets/sounds/ui/map/travelRandomizer.tres"), -15)
					#marker.gotoLocation()


func setIsHovered(value: bool) -> void:
	isTravelHovered = value


func setInfo(marker):
	if is_instance_valid(marker):
		playOpen()
		%travelButton.show()
		match marker.markerType:
			marker.Types.PROPERTY:
				if marker.propertyStatus == marker.PropertyState.Purchased and marker.propertyType == marker.PropertyType.REWARD:
					%travelButton.hide()
				if marker.propertyType == marker.PropertyType.SCENE:
					%travelButton.text = "TRAVEL"
				elif marker.propertyType == marker.PropertyType.REWARD:
					%travelButton.text = "PURCHASE"

			marker.Types.TRAVEL:
				%travelButton.text = "TRAVEL"

		%areaName.text = marker.locationName
		if marker.locationDescription != "":
			%descriptionLabel.text = marker.locationDescription
		if marker.hasCollectibleItems:
			%itemsLabelContainer.show()
		else:
			%itemsLabelContainer.hide()

		if marker.hasExploration:
			%explorationContainer.show()
		else:
			%explorationContainer.hide()

		if marker.hasCollectibleNotes:
			%notesContainer.show()
		else:
			%notesContainer.hide()

		if marker.useDescription:
			%descriptionLabel.show()
			%notesContainer.hide()
			%explorationContainer.hide()
			%itemsLabelContainer.hide()
		else:
			%descriptionLabel.hide()
	else:
		if !isTravelHovered:
			fadeOut()


func fadeOut() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	await tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.25).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType).finished
	hide()


func fadeIn() -> void:
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType)


func playOpen() -> void:
	fadeIn()

	if %markerinfoPlayer.is_playing():
		%markerinfoPlayer.stop()
	%markerinfoPlayer.play("open")

	if %animationPlayer.is_playing():
		%animationPlayer.stop()
	%animationPlayer.play("travelButtonIn")
