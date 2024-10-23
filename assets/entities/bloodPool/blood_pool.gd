extends Node3D
@onready var decal : Decal = $pool
var poolDecals : Array = ["res://assets/textures/blood/bloodPool/T_Pool_001.png", "res://assets/textures/blood/bloodPool/T_Pool_002.png", "res://assets/textures/blood/bloodPool/T_Pool_003.png", "res://assets/textures/blood/bloodPool/T_Pool_004.png", "res://assets/textures/blood/bloodPool/T_Pool_005.png", "res://assets/textures/blood/bloodPool/T_Pool_006.png", "res://assets/textures/blood/bloodPool/T_Pool_007.png", "res://assets/textures/blood/bloodPool/T_Pool_008.png", "res://assets/textures/blood/bloodPool/T_Pool_009.png", "res://assets/textures/blood/bloodPool/T_Pool_010.png"]
const defaultTweenSpeed : float = 35
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var poolTween : Tween

func startPool(_size:float = 0.5)->void:
	var timer := get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(deletePool)
	decal.scale = Vector3.ZERO
	decal.texture_albedo = load(poolDecals.pick_random())
	if poolTween:
		poolTween.kill()
	poolTween = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
	poolTween.tween_property(decal,"scale",Vector3(_size,_size,_size),defaultTweenSpeed)

func deletePool()->void:
	if poolTween:
		poolTween.kill()
	poolTween = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
	await poolTween.tween_property(decal,"modulate",Color.TRANSPARENT,0.25).finished
	queue_free()
