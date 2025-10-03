extends MarginContainer
signal propertyPurchased
var mapScreen : CanvasLayer
@onready var animPlayer : AnimationPlayer = %animationPlayer

func _ready() -> void:
	initializePanel()

func initializePanel()->void:
	animPlayer.play("open")
	await get_tree().process_frame
	if mapScreen:
		mapScreen.screenBusy = true

func close()->void:
	animPlayer.play("close")
	if mapScreen:
		mapScreen.screenBusy = false

func purchase()->void:
	if has_meta(&"price"):
		if gameState.getPawnCash() >= get_meta(&"price"):
			if has_meta(&"id"):
				gameState.AddProperty(get_meta(&"id"))

			propertyPurchased.emit()
			gameState.addPawnCash(-get_meta(&"price"))
			Util.display_message_simple("Property Purchased")
			%successfulPurchase.play()
			close()
		else:
			Util.display_message_simple("Insufficient Funds",5,true)
			%unsuccessfulPurchase.play()
			close()
