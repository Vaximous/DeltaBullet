extends Panel
@onready var phoneBackground : TextureRect = $panelContainer/phoneBG
@onready var phoneContainer : PanelContainer = $panelContainer
@onready var appContainer : GridContainer = $panelContainer/homeContainer/centerContainer/appContainer
@onready var homeContainer : VBoxContainer = $panelContainer/homeContainer
var usingPawn : BasePawn
@export var currentApp : Control = null
var isInApp : bool = false

func setupApps()->void:
	for i in appContainer.get_children():
		if i is AppButton and is_instance_valid(i.app):
			i.pressed.connect(setCurrentApp.bind(i.app))

func removeCurrentApp()->void:
	currentApp = null
	isInApp = false
	homeContainer.show()
	phoneBackground.show()

func setCurrentApp(app:PackedScene)->void:
	var instancedApp = app.instantiate()
	phoneContainer.add_child(instancedApp)
	isInApp = true
	currentApp = instancedApp
	currentApp.tree_exited.connect(removeCurrentApp)
	homeContainer.hide()
	phoneBackground.hide()

func init(pawn:BasePawn)->void:
	%smackneckChat.hide()
	modulate = Color.TRANSPARENT
	var tween : Tween
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self,"modulate",Color.WHITE,0.5).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	setupApps()
	if pawn:
		usingPawn = pawn
		pawn.direction = Vector3.ZERO
		%welcomeLabel.text = "Welcome, %s" %pawn.name
		%gritAmount.text = "Grit: %sG" %pawn.pawnCash
	if SmackneckClient.is_connected_to_masterserver():
		%smacknetConnection.text = "         Connected"
		$%smackneckChat.show()


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


func _on_icon_refresh_timeout() -> void:
	if SmackneckClient.is_connected_to_masterserver():
		var regions = [
			39,
			70,
			102,
			135
		]
		%connection.texture.region.position.y = regions.pick_random()
	else:
		%connection.texture.region.position.y = 7

	%iconRefresh.wait_time = randf_range(6,25)
