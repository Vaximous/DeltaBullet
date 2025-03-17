extends InteractiveObject
@onready var healthComponent : HealthComponent = $healthComponent
@export var defaultStream : AudioStream
var peer : HTTPClient = HTTPClient.new()
var radioURL : String = "nosystem.giize.com:2086/psyradium"
var httpReq  = "GET / HTTP/1.1\n\n"
const radioPort : int = -1
var buffer : int = 16
var stream : AudioStreamMP3 = AudioStreamMP3.new()
var active : bool = false:
	set(value):
		active = value
		if value:
			customInteractText = "Turn Radio Off"
		else:
			customInteractText = "Turn Radio On"

func _ready()->void:
	objectUsed.connect(toggleRadio)

func _process(delta: float) -> void:
	if active:
		#peer.get_connection().put_data(httpReq.to_utf8_buffer())
		print(peer.get_status())
		if peer.get_status() == peer.STATUS_CONNECTED:
			var available = peer.get_connection().get_available_bytes()
			if available >= buffer*1000:
				stream.data = peer.get_connection().get_data(available)[1]
			musicManager.change_song_to(stream)

func toggleRadio(pawn:BasePawn)->void:
	pawn.playInteractAnimation()
	$click.play()
	if pawn.attachedCam != null:
		pawn.attachedCam.fireRecoil(randf_range(2.5,8.5),0,randf_range(12.5,15.5),true)
	if !active:
		active = true
		peer.connect_to_host(radioURL)
	else:
		active = false
		musicManager.change_song_to(null,0.5)

func _on_health_component_health_depleted()->void:
	canBeUsed = false
	beenUsed = true
	remove_from_group("Interactable")


func _on_hitbox_damaged(amount, impulse, vector)->void:
	apply_impulse(impulse,vector)


func hit(dmg, dealer=null, hitImpulse:Vector3 = Vector3.ZERO, hitPoint:Vector3 = Vector3.ZERO)->void:
	apply_impulse(hitImpulse,hitPoint)

	if is_instance_valid(healthComponent):
		#print("dmg:%s"%int(dmg))
		#print("hp:%s"%healthComponent.health)
		if is_instance_valid(dealer):
			healthComponent.damage(int(dmg),dealer)
		else:
			healthComponent.damage(int(dmg),null)

	$audioStreamPlayer3d.play()
	if active:
		active = false
		musicManager.change_song_to(null,0.5)
