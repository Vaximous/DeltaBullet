extends Control
var tween : Tween
var marker:
	set(value):
		marker = value
		#print(value)
		setInfo(marker)
@export var map : CanvasLayer
var isTravelHovered : bool = false:
	set(value):
		isTravelHovered = value
		if value:
			%animationPlayer.play("travelButtonHover")
		else:
			%animationPlayer.play("travelButtonunHover")

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
		if marker.locationDescription != "":
			%descriptionLabel.text = marker.locationDescription
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
			fadeOut()

func fadeOut()->void:
	if tween:
		tween.kill()
	tween = create_tween()
	await tween.tween_property(self,"modulate",Color.TRANSPARENT,0.25).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType).finished
	hide()

func fadeIn()->void:
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self,"modulate",Color.WHITE,0.5).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType)

func playOpen()->void:
	fadeIn()

	if %markerinfoPlayer.is_playing():
		%markerinfoPlayer.stop()
	%markerinfoPlayer.play("open")

	if %animationPlayer.is_playing():
		%animationPlayer.stop()
	%animationPlayer.play("travelButtonIn")
