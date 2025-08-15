extends Control
var marker:
	set(value):
		marker = value
		#print(value)
		setInfo(marker)
@export var map : CanvasLayer
var isTravelHovered : bool = false

func goToSelectedMarker()->void:
	if marker:
		marker.gotoLocation()

func playTravelSound()->void:
	gameManager.playSound(preload("res://assets/sounds/ui/map/travelRandomizer.tres"),-15)

func setIsHovered(value:bool)->void:
	isTravelHovered = value

func _ready() -> void:
	%travelButton.focus_entered.connect(setIsHovered.bind(true))
	%travelButton.mouse_entered.connect(setIsHovered.bind(true))
	%travelButton.mouse_exited.connect(setIsHovered.bind(false))
	%travelButton.focus_exited.connect(setIsHovered.bind(false))

func setInfo(marker):
	if is_instance_valid(marker):
		playOpen()
		%areaName.text = marker.locationName

		if marker.hasCollectibleItems:
			%itemsLabel.show()
		else:
			%itemsLabel.hide()

		if marker.hasExploration:
			%explorationLabel.show()
		else:
			%explorationLabel.hide()

		if marker.hasCollectibleNotes:
			%notesLabel.show()
		else:
			%notesLabel.hide()

		if marker.useDescription:
			%descriptionLabel.show()
			%notesLabel.hide()
			%explorationLabel.hide()
			%itemsLabel.hide()
		else:
			%descriptionLabel.hide()
	else:
		if !isTravelHovered:
			hide()

func playOpen()->void:
	if !visible:
		show()

	if %markerinfoPlayer.is_playing():
		%markerinfoPlayer.stop()
	%markerinfoPlayer.play("open")
