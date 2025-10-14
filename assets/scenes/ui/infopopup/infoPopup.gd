extends MarginContainer

@export var informationBank: PopupInfobank

var currentSlide: int = 0:
	set(value):
		if value < 0:
			value = 0
		currentSlide = value
		setInformationPanel()

@onready var animPlayer: AnimationPlayer = %animationPlayer


func _ready() -> void:
	initializePanel()
	setInformationPanel()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape"):
		close()


func initializePanel() -> void:
	animPlayer.play("open")


func close() -> void:
	animPlayer.play("close")


func addToSlide(value: int) -> void:
	currentSlide += value

func setInformationPanel()->void:
	%right.show()
	%left.show()
	if is_instance_valid(informationBank):
		if currentSlide == informationBank.infoSlides.size()-1:
			%right.hide()

		if currentSlide == 0:
			%left.hide()

		if currentSlide > informationBank.infoSlides.size()-1:
			currentSlide = informationBank.infoSlides.size()-1
		%infoText.text = informationBank.infoSlides[currentSlide].infoText
		if is_instance_valid(informationBank.infoSlides[currentSlide].infoTexture):
			%infoPicture.texture = informationBank.infoSlides[currentSlide].infoTexture
		else:
			%infoPicture.texture = null
