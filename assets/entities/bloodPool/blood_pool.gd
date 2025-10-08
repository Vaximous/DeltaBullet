extends Node3D

const poolDecals: Array = [preload("res://assets/textures/blood/bloodPool/T_Pool_001.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_002.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_003.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_004.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_005.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_006.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_007.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_008.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_009.png"), preload("res://assets/textures/blood/bloodPool/T_Pool_010.png")]
const defaultTweenSpeed: float = 35
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT

var removing: bool = false
var poolTween: Tween

@onready var decal: Decal = $pool


func _enter_tree() -> void:
	gameManager.registerDecal(self)


func startPool(_size: float = 0.5) -> void:
	get_tree().create_timer(UserConfig.game_decal_remove_time).timeout.connect(deletePool)
	decal.scale = Vector3(0.01, 0.01, 0.01)
	decal.texture_albedo = poolDecals.pick_random()
	for i in decal.get_children():
		i.texture_albedo = decal.texture_albedo
	if poolTween:
		poolTween.kill()
	poolTween = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
	poolTween.tween_property(decal, "scale", Vector3(_size, _size, _size), defaultTweenSpeed)
	#decalCollisionCheck(Vector3(_size,_size,_size))

#func decalCollisionCheck(_scale:Vector3)->void:
	#%collisionShape3d.shape.size = _scale
	#var overlap = %collisionChecker.get_overlapping_areas()
	#for i in overlap:
		#i.get_owner().queue_free()


func deletePool() -> void:
	if !removing:
		removing = true
		if poolTween:
			poolTween.kill()
		poolTween = create_tween().set_ease(defaultEaseType).set_trans(defaultTransitionType)
		await poolTween.tween_property(decal, "modulate", Color.TRANSPARENT, 0.25).finished
	queue_free()
