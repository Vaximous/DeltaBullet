extends InteractiveObject
@onready var mesh = $meshInstance3d
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	objectUsed.connect(healPawn)
	useSound.finished.connect(queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta)->void:
	if beenUsed:
		mesh.transparency = lerpf(mesh.transparency, 1.0, 15*delta)
		if mesh.transparency >= 0.98:
			pass
			#queue_free()

func healPawn(pawn:BasePawn)->void:
	if !beenUsed:
		if pawn:
			if pawn.healthComponent.health < 100:
				pawn.healthComponent.health = 100
				if pawn.attachedCam:
					pawn.attachedCam.fireVignette(0.9,Color.DARK_OLIVE_GREEN)
					pawn.attachedCam.fireRecoil(0,randf_range(5.15,7.8),0,true)
					var _notification = load("res://assets/scenes/ui/generalNotif/generalNotification.tscn").instantiate()
					gameManager.activeCamera.hud.gameNotifications.add_child(_notification)
					_notification.doNotification(null,"Medkit", "Health fully recovered.")
					gameManager.playSound(gameManager.getGlobalSound("healSound"))
					useSound.play()
				remove_from_group("Interactable")
				beenUsed = true
