extends Control
signal interactionunFound
signal interactionFound
@export_category("Hud")
var vignetteTween : Tween
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var camOwner : PlayerCamera
var followEntity : Node3D:
	set(value):
		followEntity = value
		if followEntity is BasePawn:
			followEntity.healthComponent.healthChanged.connect(hpCheck.unbind(1))
@onready var vignette : ColorRect = $vignette
@onready var gameNotifications : VBoxContainer = $marginContainer/control/gameNotifications
@onready var questNotifHolder : MarginContainer = $questNotification
@export var cam : Camera3D
@export var interactionOffset : Vector2 = Vector2.ZERO
@onready var interactHud : Control = $Interact
@onready var interactText : RichTextLabel = $Interact/panel/richTextLabel
@onready var camVert = $"../camPivot/horizonal/vertholder/vertical"
@onready var camHoriz = $"../camPivot/horizonal"
@onready var camCast : RayCast3D = $"../camPivot/horizonal/vertholder/vertical/springArm3d/Camera/RayCast3D"
@export var crosshair : TextureRect
@onready var healthBG = $hpBG
@onready var healthTexture = $healthTexture
var slidingCrosshairPos : Vector2 = Vector2.ZERO
@export var hudEnabled = true
@onready var healthBar = $hpBar
@onready var fpsControl = $FPSCounter
@onready var bulletTimeFlash : ColorRect = $bulletTimeFlash
@onready var bulletTimeOn : AudioStreamPlayer = $bulletTimeFlash/bulletTimeOn
@onready var bulletTimeOff : AudioStreamPlayer = $bulletTimeFlash/bulletTimeOff
@onready var fpsLabel = $FPSCounter/label
@onready var interactAnim = $Interact/interactAnimPlayer
@onready var stableCrosshair : TextureRect = $stableCrosshair
var ray = PhysicsRayQueryParameters3D.new()
var flashTween : Tween
var interactTween : Tween
var hudTween : Tween
var interactVisible:bool = false:
	set(value):
		interactVisible = value
		await get_tree().process_frame
		if value:
			fadeInteractHudIn()
			interactionFound.emit()
		else:
			fadeInteractHudOut()
			interactionunFound.emit()

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	enableHud()
	gameManager.getEventSignal("playerDied").connect(gameManager.onPlayerDeath)
	gameManager.getEventSignal(&"playerShot").connect(spawnBulletCasing)
	#Dialogic.timeline_started.connect(disableHud)
	#Dialogic.timeline_ended.connect(enableHud)
	#Dialogic.timeline_started.connect(gameManager.showMouse)
	#Dialogic.timeline_ended.connect(gameManager.hideMouse)
	if gameManager.world:
		if gameManager.world.worldData.worldEditable:
			%worldEditButton.show()
		else:
			%worldEditButton.hide()

func enableVignette(color:Color,duration:float)->void:
	if vignetteTween:
		vignetteTween.kill()
	vignetteTween = create_tween()
	vignetteTween.parallel().tween_method(setVignetteColor,vignette.get_material().get_shader_parameter("color"),Color.DARK_RED,3).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	vignetteTween.parallel().tween_method(setVignetteSoftness,vignette.get_material().get_shader_parameter("softness"),0.8,2).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func setVignetteSoftness(amount:float)->void:
	vignette.get_material().set_shader_parameter("softness",amount)

func setVignetteColor(color:Color)->void:
	vignette.get_material().set_shader_parameter("color",color)

func disableVignette()->void:
	if vignetteTween:
		vignetteTween.kill()
	vignetteTween = create_tween()
	vignetteTween.parallel().tween_method(setVignetteColor,vignette.get_material().get_shader_parameter("color"),Color.TRANSPARENT,3).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	vignetteTween.parallel().tween_method(setVignetteSoftness,vignette.get_material().get_shader_parameter("softness"),5,2).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)



func flashColor(color:Color)->void:
	if flashTween:
		flashTween.kill()
	flashTween = create_tween()
	const defaultTransitionType = Tween.TRANS_QUART
	const defaultEaseType = Tween.EASE_OUT
	bulletTimeFlash.color = color
	flashTween.parallel().tween_property(bulletTimeFlash,"color",Color.TRANSPARENT,1).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func fadeInteractHudIn()->void:
	if interactTween:
		interactTween.kill()
	interactTween = create_tween()
	interactTween.tween_property(interactHud,"modulate",Color.WHITE,0.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func fadeInteractHudOut()->void:
	if interactTween:
		interactTween.kill()
	interactTween = create_tween()
	interactTween.tween_property(interactHud,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta)->void:
	# If in Dialogue
	if interactVisible:
		#interactHud.modulate = lerp(interactHud.modulate, Color.WHITE, 8*delta)
		interactHud.position.y = lerpf(interactHud.position.y, crosshair.position.y + interactionOffset.y, 8*delta)
		interactHud.position.x = lerpf(interactHud.position.x, crosshair.position.x + interactionOffset.x, 8*delta)
	else:
		#interactHud.modulate = lerp(interactHud.modulate, Color.TRANSPARENT, 24*delta)
		interactHud.position = lerp(interactHud.position, crosshair.position, 16*delta)


	#Crosshair Follow
	var pos
	if UserConfig.game_crosshair_dynamic_position:
		if camCast.is_colliding():
			pos = camCast.get_collision_point()
			slidingCrosshairPos = cam.unproject_position(pos)
		else:
			pos = get_owner().camCastEnd.global_position
			slidingCrosshairPos = cam.unproject_position(pos)

		#if camOwner:
			#if camOwner.followingEntity and camOwner.followingEntity is BasePawn:
				#if camOwner.followingEntity.currentItem:
					#var ray_target_point = get_hit_target(camOwner.camCast)
					#ray.from = camOwner.followingEntity.currentItem.muzzlePoint.global_position
					#ray.to = ray_target_point
					##ray.collision_mask = raycaster.collision_mask
					#var result = gameManager.world.worldMisc.get_world_3d().direct_space_state.intersect_ray(ray)
					#if result:
						#%worldCrosshair.visible = true
						#%worldCrosshair.global_position = lerp(%worldCrosshair.global_position,result.position,24*delta)
						#%worldCrosshair.global_rotation.z = crosshair.rotation
						#%worldCrosshair.modulate = Color(1,1,1,(%worldCrosshair.global_position - camOwner.followingEntity.global_position).normalized().x * 2)
						##print((%worldCrosshair.global_position - camOwner.followingEntity.global_position).normalized())
						#if %worldCrosshair.texture != crosshair.texture:
							#%worldCrosshair.texture = crosshair.texture
					#else:
						#%worldCrosshair.visible = false
				#else:
					#%worldCrosshair.visible = false

		crosshair.scale = clamp(crosshair.scale,Vector2(0.5,0.5),Vector2(1.5,1.5))
		crosshair.positionOverride = lerp(crosshair.positionOverride, slidingCrosshairPos, get_owner().recoilReturnSpeed*delta)

	#if hudEnabled:
		#modulate = lerp(modulate,Color.WHITE,12*delta)
		#healthBar.self_modulate = lerp(healthBar.self_modulate,Color.WHITE,12*delta)
		#healthBG.self_modulate = lerp(healthBG.self_modulate,Color.WHITE,12*delta)
		#healthTexture.self_modulate = lerp(healthTexture.self_modulate,Color.WHITE,12*delta)
	#else:
		#modulate = lerp(modulate,Color.TRANSPARENT,12*delta)
		#crosshair.tintCrosshair(Color.TRANSPARENT)
		#healthBar.self_modulate = lerp(healthBar.self_modulate,Color.TRANSPARENT,12*delta)
		#healthBG.self_modulate = lerp(healthBG.self_modulate,Color.TRANSPARENT,12*delta)
		#healthTexture.self_modulate = lerp(healthTexture.self_modulate,Color.TRANSPARENT,12*delta)

func hpCheck()->void:
	if is_instance_valid(followEntity) and followEntity is BasePawn:
		if !followEntity.healthComponent.isDead:
			if followEntity.healthComponent.health <= 150:
				enableVignette(Color.DARK_RED,2)
			else:
				disableVignette()

	if UserConfig.game_show_fps:
		fpsControl.show()
		fpsLabel.text = "FPS: %s" %Engine.get_frames_per_second()
	else:
		fpsControl.hide()

func getCrosshair():
	if crosshair:
		return crosshair

func fadeHudIn()->void:
	if hudTween:
		hudTween.kill()
	hudTween = create_tween()
	hudTween.tween_property(self,"modulate",Color.WHITE,0.5).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func fadeHudOut()->void:
	if hudTween:
		hudTween.kill()
	hudTween = create_tween()
	hudTween.tween_property(self,"modulate",Color.TRANSPARENT,0.25).set_ease(defaultEaseType).set_trans(defaultTransitionType)


func setInteractionText(text : String)->void:
	interactText.text = text


func get_hit_target(raycast : RayCast3D) -> Vector3:
	var ray_target_point : Vector3 = raycast.global_position + (-raycast.global_transform.basis.z * 5000)

	var state : PhysicsDirectSpaceState3D = gameManager.world.worldMisc.get_world_3d().direct_space_state
	var rayq : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(raycast.global_position, ray_target_point, 0b10000, [])
	if state != null:
		rayq.collide_with_areas = true
		rayq.hit_back_faces = true
		rayq.hit_from_inside = false
		rayq.exclude.append(RID(camOwner.followingEntity.currentItem.weaponOwner))
		for hitbox in camOwner.followingEntity.currentItem.weaponOwner.getAllHitboxes():
			rayq.exclude.append(RID(hitbox))
		var intersect = state.intersect_ray(rayq)
		if !intersect.is_empty():
			if camOwner.followingEntity.currentItem.weaponOwner and !ray_target_point.z > camOwner.followingEntity.currentItem.weaponOwner.global_position.z:
				ray_target_point = intersect['position']
			else:
				ray_target_point = intersect['position']
		else:
			rayq.collide_with_areas = false
			rayq.collision_mask = raycast.collision_mask
			intersect = state.intersect_ray(rayq)
			if !intersect.is_empty():
				ray_target_point = intersect['position']
	return ray_target_point


const bulletcasing_scene = preload("res://assets/scenes/ui/HudBulletCasingFly.tscn")
func spawnBulletCasing() -> void:
	var spawn_pos = $weaponBar.global_position
	var inst = bulletcasing_scene.instantiate()
	inst.spawn_at_location(self, spawn_pos)


func disableHud()->void:
	hudEnabled = false
	fadeHudOut()


func enableHud()->void:
	hudEnabled = true
	fadeHudIn()
