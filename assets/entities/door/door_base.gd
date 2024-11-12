extends InteractiveObject
@export_enum("Unlocked","Locked","Keypad") var lockType : int = 0:
	set(value):
		lockType = value
		if !isDoorOpen:
			match lockType:
				0:
					customInteractText = "Open Door"
				1:
					customInteractText = "Locked"
				2:
					customInteractText = "Use Keypad"
@onready var openSound : AudioStreamPlayer3D = $openSound
@onready var closeSound : AudioStreamPlayer3D = $closeSound
@export var isDoorOpen : bool = false:
	set(value):
		isDoorOpen = value
		if value:
			customInteractText = "Close Door"
		else:
			match lockType:
				0:
					customInteractText = "Open Door"
				1:
					customInteractText = "Locked"
				2:
					customInteractText = "Use Keypad"
@export var doorCollision : CollisionShape3D
@export var doorMesh : Node3D
const defaultTweenSpeed : float = 0.25
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var doorTween : Tween

func _ready() -> void:
	objectUsed.connect(openRequest)

func openDoorFront()->void:
	if doorTween:
		doorTween.kill()
	doorTween = create_tween()
	openSound.play()
	doorTween.tween_property(doorMesh,"rotation:y", getShortTweenAngle(doorMesh.rotation.y,90),0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)
	#doorTween.parallel().tween_property(doorCollision,"rotation:y", getShortTweenAngle(doorCollision.rotation.y,90),0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)

func openDoorBack()->void:
	if doorTween:
		doorTween.kill()
	doorTween = create_tween()
	openSound.play()
	doorTween.tween_property(doorMesh,"rotation:y",getShortTweenAngle(doorMesh.rotation.y,-90),0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)
	#doorTween.parallel().tween_property(doorCollision,"rotation:y", getShortTweenAngle(doorCollision.rotation.y,-90),0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)

func closeDoor()->void:
	if doorTween:
		doorTween.kill()
	doorTween = create_tween()
	closeSound.play()
	doorTween.tween_property(doorMesh,"rotation:y",0,0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)
	doorTween.parallel().tween_property(doorCollision,"rotation:y",0,0.5).set_trans(defaultTransitionType).set_ease(defaultEaseType)

func getShortTweenAngle(currentAngle:float,targetAngle:float)->float:
	return currentAngle + wrapf(targetAngle-currentAngle,-PI,PI)

func openRequest(pawn:BasePawn):
	match lockType:
		0:
			pawn.playUseAnimation()
			if !isDoorOpen:
				#Detect which side player is on, for now just do default open animation if its unlocked
				isDoorOpen = true
				openDoorFront()
			else:
				isDoorOpen = false
				closeDoor()
		2:
			pawn.playUseAnimation()
			if !isDoorOpen:
				initializeKeypadScene()

func initializeKeypadScene()->void:
	var cutscene = preload("res://assets/scenes/cutscenes/usenumpad/KeypadCutscene.tscn").instantiate()
	await Fade.fade_out(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED #idk pause it or some shit
	get_tree().root.add_child(cutscene)
	cutscene.do()
	Fade.fade_in(0.3, Color(0,0,0,1),"GradientVertical",false,true).finished
	await cutscene.tree_exited
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT #idk pause it or some shit
