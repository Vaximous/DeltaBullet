extends Panel
var usingPawn : BasePawn
@export var currentApp : Control = null
var isInApp : bool = false


func init(pawn:BasePawn)->void:
	modulate = Color.TRANSPARENT
	var tween : Tween
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self,"modulate",Color.WHITE,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

	if pawn:
		usingPawn = pawn
		pawn.direction = Vector3.ZERO
		%welcomeLabel.text = "Welcome, %s" %pawn.name
		%gritAmount.text = "Grit: %sG" %pawn.pawnCash

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gEscape") or event.is_action_pressed("gTabMenu"):
		close()

func close()->void:
	var tween : Tween
	if tween:
		tween.kill()

	tween = create_tween()
	await tween.tween_property(self,"modulate",Color.TRANSPARENT,0.25).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType).finished

	if usingPawn:
		usingPawn.closePhone()
	gameManager.hideMouse()
	gameManager.pauseMenu.canPause = true
	gameManager.removePhoneMenu()
