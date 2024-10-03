extends InteractiveObject
@export var cashAmount : int = 0
@onready var meshHolder = $meshes
# Called when the node enters the scene tree for the first time.
func _ready()->void:
	customInteractText = "Pick up $%s" %cashAmount
	objectUsed.connect(pickupCash)
	#useSound.finished.connect(queue_free)

func pickupCash(pawn:BasePawn)->void:
	if pawn.attachedCam:
		gameManager.notifyFade("$%s has been added to your balance." %cashAmount)
		pawn.attachedCam.fireRecoil(randf_range(1.15,1.8),0.0,randf_range(1.15,1.8),true)
	pawn.pawnCash += cashAmount
	meshHolder.hide()
	#useSound.play()
	canBeUsed = false
	$collisionShape3d.disabled = true
	#queue_free()
