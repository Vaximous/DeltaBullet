extends InteractiveObject
@export var defaultStream : AudioStream
var active : bool = false:
	set(value):
		active = value
		if value:
			customInteractText = "Turn Radio Off"
		else:
			customInteractText = "Turn Radio On"

func _ready()->void:
	objectUsed.connect(toggleRadio)

func toggleRadio(pawn:BasePawn)->void:
	pawn.playInteractAnimation()
	$click.play()
	if pawn.attachedCam != null:
		pawn.attachedCam.fireRecoil(randf_range(2.5,8.5),0,randf_range(12.5,15.5),true)
	if !active:
		active = true
		musicManager.change_song_to(defaultStream,0.5)
	else:
		active = false
		musicManager.change_song_to(null,0.5)

func _on_health_component_health_depleted()->void:
	canBeUsed = false
	beenUsed = true
	remove_from_group("Interactable")


func _on_hitbox_damaged(amount, impulse, vector)->void:
	apply_impulse(impulse,vector)
	$audioStreamPlayer3d.play()
	if active:
		active = false
		musicManager.change_song_to(null,0.5)
