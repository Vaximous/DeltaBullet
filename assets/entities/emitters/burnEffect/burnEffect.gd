extends Node3D
var lightTween : Tween
@onready var damageTimer : Timer = $damageTimer
@onready var burnTimer : Timer = $burnTimer
@export var burnTarget : Node3D
##How long will it take to tick and damage the target
@export var burnTickTime : float = 0.5
##How long will the target be burned for
@export var burnTime : float = 10.0:
	set(value):
		burnTime = value
		if is_instance_valid(burnTimer):
			burnTimer.stop()
			burnTimer.wait_time = burnTime
			burnTimer.start()

##How much damage will the target be burned for each tick
@export var burnDamage : float = 10.0

func _ready() -> void:
	fadeFireLightIn()
	damageTimer.wait_time = burnTickTime
	damageTimer.start()
	$burnSound.play()

func fadeFireLightIn()->void:
	%burnLight.light_energy = 0
	if lightTween:
		lightTween.kill()
	lightTween = create_tween()
	lightTween.tween_property(%burnLight,"light_energy",0.5,1)

func fadeFireLightOut()->void:
	burnTarget.set_meta("isBurning", false)
	if lightTween:
		lightTween.kill()
	lightTween = create_tween()
	lightTween.parallel().tween_property(%burnSound,"volume_db",-50,0.5)
	await lightTween.tween_property(%burnLight,"light_energy",0,0.5).finished.connect(queue_free)

func damageTarget(target:Node3D)->void:
	if is_instance_valid(target):
		if target.has_method("hit"):
			target.hit(burnDamage,null)
			damageTimer.start()

func stopBurn()->void:
	for i in get_children():
		if i is GPUParticles3D:
			i.amount = 1
			i.finished.connect(queue_free)
			i.one_shot = true

	fadeFireLightOut()

func _on_burn_timer_timeout() -> void:
	stopBurn()

func _on_damage_timer_timeout() -> void:
	damageTarget(burnTarget)
