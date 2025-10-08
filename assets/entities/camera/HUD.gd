extends Control
signal interactionunFound
signal interactionFound
@export_category("Hud")
var vignetteTween : Tween
var reloadTween : Tween
var blurTween : Tween
var painDir : PackedScene = load("res://assets/scenes/ui/hudPainDirection/painDirection.tscn")
const defaultTransitionType = Tween.TRANS_QUART
const defaultEaseType = Tween.EASE_OUT
var camOwner : PlayerCamera
var followEntity : Node3D:
	set(value):
		followEntity = value
		if followEntity is BasePawn:
			if !followEntity.healthComponent.healthChanged.is_connected(hpCheck):
				followEntity.healthComponent.healthChanged.connect(hpCheck.unbind(1))
@onready var vignette : ColorRect = $vignette
@onready var closeCrosshair : TextureRect = $closeCrosshair
@onready var reloadProgress : TextureProgressBar = $Crosshair/reloadProgress
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
@onready var radialBlur : ColorRect = $radialBlur
var ray = PhysicsRayQueryParameters3D.new()
var flashTween : Tween
var interactTween : Tween
var hudTween : Tween
var interactVisible:bool = false:
	set(value):
		interactVisible = value
		if value:
			await get_tree().process_frame
			fadeInteractHudIn()
			interactionFound.emit()
		else:
			await get_tree().process_frame
			fadeInteractHudOut()
			interactionunFound.emit()

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	enableHud()
	%scope.modulate = Color.TRANSPARENT
	if !gameManager.getEventSignal("playerDied").is_connected(gameManager.onPlayerDeath):
		gameManager.getEventSignal("playerDied").connect(gameManager.onPlayerDeath)
	if !gameManager.getEventSignal(&"playerShot").is_connected(spawnBulletCasing):
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
	vignetteTween.parallel().tween_method(setVignetteColor,vignette.get_material().get_shader_parameter("color"),color,duration).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	vignetteTween.parallel().tween_method(setVignetteSoftness,vignette.get_material().get_shader_parameter("softness"),0.8,2).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func setVignetteSoftness(amount:float)->void:
	vignette.get_material().set_shader_parameter("softness",amount)

func setVignetteColor(color:Color)->void:
	vignette.get_material().set_shader_parameter("color",color)

func invokePainDirection(from : Node3D)->void:
	#If we already know about this node damaging us, just reset alpha
	for n in get_tree().get_nodes_in_group(&"hud_dir_pain_indicator"):
		if n.painDealerNode == from:
			n.reset_alpha()
			return
	#It's a new attacker, add
	var pDir = painDir.instantiate()
	pDir.painDealerNode = from
	%centerContainer.add_child(pDir)
	pDir.global_position = get_tree().root.size / 2.0

func disableVignette()->void:
	if vignetteTween:
		vignetteTween.kill()
	vignetteTween = create_tween()
	vignetteTween.parallel().tween_method(setVignetteColor,vignette.get_material().get_shader_parameter("color"),Color.TRANSPARENT,3).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)
	vignetteTween.parallel().tween_method(setVignetteSoftness,vignette.get_material().get_shader_parameter("softness"),5,2).set_ease(gameManager.defaultEaseType).set_trans(gameManager.defaultTransitionType)

func showReloadProgress()->void:
	if reloadTween:
		reloadTween.kill()
	reloadTween = create_tween()
	reloadProgress.modulate = Color.TRANSPARENT
	reloadProgress.show()
	reloadTween.parallel().tween_property(reloadProgress,"modulate",Color.WHITE,0.25).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType)

func hideReloadProgress()->void:
	if reloadProgress.visible:
		if reloadTween:
			reloadTween.kill()
		reloadTween = create_tween()
		reloadProgress.show()
		await reloadTween.parallel().tween_property(reloadProgress,"modulate",Color.TRANSPARENT,0.25).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType).finished
		reloadProgress.hide()

func reloadProgressActivate(time:float)->void:
	if reloadTween:
		reloadTween.kill()
	reloadTween = create_tween()
	reloadProgress.show()
	reloadProgress.value = 0
	reloadTween.parallel().tween_property(reloadProgress,"modulate",Color.WHITE,0.25).set_trans(gameManager.defaultTransitionType).set_ease(gameManager.defaultEaseType)
	await reloadTween.parallel().tween_property(reloadProgress,"value",100,time).finished
	hideReloadProgress()

func flashColor(color:Color)->void:
	if flashTween:
		flashTween.kill()
	flashTween = create_tween()
	bulletTimeFlash.color = color
	flashTween.parallel().tween_property(bulletTimeFlash,"color",Color.TRANSPARENT,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


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

func disableScope()->void:
	if hudTween:
		hudTween.kill()
	hudTween = create_tween()
	hudTween.parallel().tween_property(%scope,"modulate",Color.TRANSPARENT,0.10)
	hudTween.parallel().tween_property(crosshair,"self_modulate",Color.WHITE,0.25)
	camOwner.set_meta("scopedAiming",true)

func enableScope()->void:
	if hudTween:
		hudTween.kill()
	hudTween = create_tween()
	hudTween.parallel().tween_property(%scope,"modulate",Color.WHITE,0.05)
	hudTween.parallel().tween_property(crosshair,"self_modulate",Color.TRANSPARENT,0.25)
	camOwner.set_meta("scopedAiming",false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta)->void:
	if UserConfig.game_show_fps:
		fpsControl.show()
		fpsLabel.text = "FPS: %s" %int(Engine.get_frames_per_second())
	else:
		fpsControl.hide()

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

func triggerRadialBlur(blurPosition:Vector2 = Vector2(0.5,0.5),blurPower:float=0.3,blurSpeed = 0.5)->void:
	if blurTween:
		blurTween.kill()
	blurTween = create_tween()
	var currentPower = radialBlur.material.get_shader_parameter("power")
	radialBlur.material.set_shader_parameter("power", currentPower + blurPower)
	radialBlur.material.set_shader_parameter("center",blurPosition)

	blurTween.tween_property(radialBlur.material,"shader_parameter/power",0,blurSpeed)

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
