extends CharacterBody3D
class_name PlayerCamera
signal cameraRotationUpdated
##Variable Set
var lowHP : bool = false
var isFreecam : bool = true
var speed : float = 9.0
var acceleration: float = 3.0
var vertVeclocity : Vector3 = Vector3.ZERO
var killEffect : bool = false
var castLerp : Vector3 = Vector3.ZERO
@onready var killSound : AudioStreamPlayer = $killSound
@export_subgroup("Camera")
@export var cameraData : CameraData:
	set(value):
		cameraData = value
		if cameraData != null:
			hud.hudEnabled = cameraData.isHudEnabled
@export var followingEntity : Node3D
@export var followNode : Node3D:
	set(value):
		followNode = value
		if followingEntity is BasePawn:
			followingEntity.interactRaycast = interactCast
			if !followingEntity.killedPawn.is_connected(emitKilleffect):
				followingEntity.killedPawn.connect(emitKilleffect)
	get:
		return followNode
#onReady Set
@onready var headshotSound : AudioStreamPlayer = $headshotSound
@onready var killVignette : ColorRect = $HUD/killVignette
@onready var vignette : ColorRect = $HUD/vignette
@onready var hpAudio : AudioStreamPlayer = $HUD/vignette/lowHP
@onready var hud : Control = $HUD
@onready var weaponHud : TextureRect = $HUD/weaponBar
@onready var weaponLabel : Label = $HUD/weaponBar/weaponName
@onready var weaponAmmoLabel : Label = $HUD/weaponBar/currentAmmoCount
@onready var weaponMagCountLabel : Label = $HUD/weaponBar/currentMagCount
@onready var horizontal : Node3D = $camPivot/horizonal
@onready var verticalHolder : Node3D = $camPivot/horizonal/vertholder
@onready var vertical : Node3D = $camPivot/horizonal/vertholder/vertical
@onready var camSpring : SpringArm3D = $camPivot/horizonal/vertholder/vertical/springArm3d
@onready var camera : Camera3D = $camPivot/horizonal/vertholder/vertical/springArm3d/Camera
@onready var camPivot : Node3D = $camPivot
@onready var interactCast : RayCast3D = $camPivot/horizonal/vertholder/vertical/springArm3d/Camera/interactCast
@onready var camCast : RayCast3D = $camPivot/horizonal/vertholder/vertical/springArm3d/Camera/RayCast3D
@onready var camCastEnd : Marker3D = $camPivot/horizonal/vertholder/vertical/springArm3d/Camera/RayCast3D/camRayEnd
@onready var debugCast : RayCast3D = $camPivot/horizonal/vertholder/vertical/springArm3d/Camera/debugCast

@export_subgroup("Behavior")
var motionX : float = 0.0:
	set(value):
		motionX = value
		cameraRotationUpdated.emit()
var motionY : float = 0.0:
	set(value):
		motionY = value
		cameraRotationUpdated.emit()
@export var itemEquipOffsetToggle : bool = false

@export_subgroup("Recoil")
var camEuler
@export var camRecoilStrength : float
@export var camReturnSpeed : float
@export var camRecoil : Vector3
@export var camCurrRot : Vector3
@export var camTargetRot : Vector3
@export var recoilReturnSpeed : float = 5.0
@export var recoilLookSpeed : float = 0.05
var camReturnVect : Vector3 = Vector3(motionX, motionY, 0)
@export_subgroup("Zoom")
var aimFOV
@export var isZoomed : bool = false
@export var currentFOV : float = 90.0
@export var zoomAmount : float = 25.0:
	set(value):
		zoomAmount = value
		aimFOV = currentFOV - value
		if cameraData:
			zoomAmount = cameraData.zoomAmount


var controllerVector = Vector2.ZERO:
	set(value):
		controllerVector = value.normalized()
		if controllerVector != Vector2.ZERO:
			motionX = rad_to_deg(-controllerVector.x * gameManager.controllerSens)
			motionY = rad_to_deg(-controllerVector.y * gameManager.controllerSens)
			castLerp = Vector3(motionY* recoilLookSpeed+0.01,motionX* recoilLookSpeed,0)
			camPivot.rotation_degrees.y += motionX
			vertical.rotation_degrees.x += motionY
			#Lock Cam
			vertical.rotation.x = clamp(vertical.rotation.x, deg_to_rad(-88), deg_to_rad(88))
var defaultZoomAmount : float = 25.0
var defaultZoomSpeed : float = 16.0
@export var zoomSpeed : float = 11.0:
	set(value):
		zoomSpeed = value
		if cameraData:
			zoomSpeed = cameraData.zoomSpeed

#Component Set
@export_subgroup("Components")
@export var velocityComponent : Node
@export var inputComponent : Node

var direction : Vector3 = Vector3.ZERO
var camRot: float:
	set(value):
		camRot = value

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready()->void:
	camera.make_current()
	Dialogic.current_timeline = null
	Dialogic.end_timeline()
	gameManager.activeCamera = self
	currentFOV = gameManager.defaultFOV
	gameManager.hideMouse()
	aimFOV = currentFOV - zoomAmount
	Fade.fade_in(0.3, Color(0,0,0,1),"GradientVertical",false,true)
	Dialogic.timeline_started.connect(playTextAppearSound)

func _input(_event)->void:
	if Input.is_action_pressed("gRightClick"):
		isZoomed = true
	else:
		isZoomed = false


func _physics_process(delta)->void:
	controllerVector.y = Input.get_action_strength("gLookDown") - Input.get_action_strength("gLookUp")
	controllerVector.x = Input.get_action_strength("gLookRight") - Input.get_action_strength("gLookLeft")
	#Interact Cast HUD
	if !isFreecam:
		interactCheck()

	#Weapon Hud
	if !followNode == null:
		if "currentItem" in followingEntity:
			if followingEntity.currentItem != null:
				weaponHud.modulate = lerp(weaponHud.modulate,Color(1,1,1,0.8),12*delta)
				weaponAmmoLabel.text = str(followingEntity.currentItem.currentAmmo)
				if followingEntity.currentItem.currentAmmo <= 2:
					weaponAmmoLabel.modulate = lerp(weaponAmmoLabel.modulate,Color.RED,18*delta)
				else:
					weaponAmmoLabel.modulate = lerp(weaponAmmoLabel.modulate,Color.WHITE,18*delta)
				weaponLabel.text = str(followingEntity.currentItem.objectName)
				weaponMagCountLabel.text = str(followingEntity.currentItem.currentMagSize)
				if followingEntity.currentItem.currentMagSize <= 2:
					weaponMagCountLabel.modulate = lerp(weaponMagCountLabel.modulate,Color.RED,18*delta)
				else:
					weaponMagCountLabel.modulate = lerp(weaponMagCountLabel.modulate,Color.GRAY,18*delta)
			else:
				weaponAmmoLabel.text = ""
				weaponMagCountLabel.text = ""
				weaponLabel.text = ""
				weaponHud.modulate = lerp(weaponHud.modulate,Color(1,1,1,0.0),12*delta)

	##Recoil - Currently broken.. Needs fixing..
	camCast.rotation = lerp(camCast.rotation,castLerp, recoilReturnSpeed*delta)
	camTargetRot.x = lerp(camTargetRot.x, 0.0, camReturnSpeed * delta)
	camTargetRot.y = lerp(camTargetRot.y, 0.0, camReturnSpeed * delta)
	camTargetRot.z = lerp(camTargetRot.z, 0.0, camReturnSpeed * delta)
	camCurrRot = lerp(camCurrRot,camTargetRot,camRecoilStrength * delta)
	verticalHolder.rotation_degrees.x = camCurrRot.x
	horizontal.rotation_degrees.y = camCurrRot.y
	camera.rotation_degrees.z = camCurrRot.z

	#Always Screentilt
	if UserConfig.game_camera_screentilt_always:
		camCurrRot.z += -castLerp.y
	#Cast Lerp

	castLerp = lerp(castLerp,Vector3.ZERO,recoilReturnSpeed*delta)
	if UserConfig.game_crosshair_tilt:
		hud.getCrosshair().addTilt(-castLerp.y)
	#Zooming
	if isZoomed:
		if UserConfig.game_aim_screentilt or UserConfig.game_camera_screentilt_always:
			camCurrRot.z += -castLerp.y
		if !cameraData == null:
			if cameraData.useZoomFOV:
				camera.fov = lerpf(camera.fov, currentFOV, zoomSpeed * delta)
				currentFOV = aimFOV
				camSpring.spring_length = lerp(camSpring.spring_length, cameraData.cameraOffset.z, cameraData.camLerpSpeed*delta)
			else:
				camera.fov = lerpf(camera.fov, currentFOV, cameraData.zoomSpeed * delta)
				currentFOV = gameManager.defaultFOV
				camSpring.spring_length = lerp(camSpring.spring_length, cameraData.zoomSpringAmount, cameraData.zoomInSpeed*delta)
		else:
			camera.fov = lerpf(camera.fov, currentFOV, 8.5 * delta)
			currentFOV = gameManager.defaultFOV
			camSpring.spring_length = lerp(camSpring.spring_length, 0.5, 25.0*delta)
	else:
		if !cameraData == null:
			if cameraData.useZoomFOV:
				camera.fov = lerpf(camera.fov, currentFOV, zoomSpeed * delta)
				currentFOV = gameManager.defaultFOV
				camSpring.spring_length = lerp(camSpring.spring_length, cameraData.cameraOffset.z, cameraData.camLerpSpeed*delta)
			else:
				camera.fov = lerpf(camera.fov, currentFOV, cameraData.zoomSpeed * delta)
				currentFOV = gameManager.defaultFOV
				camSpring.spring_length = lerp(camSpring.spring_length, cameraData.cameraOffset.z, cameraData.zoomOutSpeed*delta)
		else:
			camera.fov = lerpf(camera.fov, currentFOV, zoomSpeed * delta)
			currentFOV = gameManager.defaultFOV
			camSpring.spring_length = lerp(camSpring.spring_length, 1.65, 50*delta)
	##Set the camera rotation
	camRot = vertical.global_transform.basis.get_euler().y

	##Pass the rotation of the camera to the pawn
	if !followNode == null:
		if followingEntity is BasePawn:
			followingEntity.meshRotation = camRot
			hud.healthBar.value = lerpf(hud.healthBar.value,followingEntity.healthComponent.health, 20 * delta)

	##Lerp to FollowNode

	if !followNode == null:
		camPivot.global_position.x = lerp(camPivot.global_position.x, followNode.global_position.x, cameraData.camLerpSpeed*delta)
		camPivot.global_position.y = lerp(camPivot.global_position.y, followNode.global_position.y, cameraData.camLerpSpeed*delta)
		camPivot.global_position.z = lerp(camPivot.global_position.z, followNode.global_position.z, cameraData.camLerpSpeed*delta)

		#camPivot.position.x = lerp(camPivot.position.x , cameraData.cameraOffset.x, cameraData.camLerpSpeed*delta)
		#vertical.position.z = lerp(vertical.position.z , cameraData.cameraOffset.z, cameraData.camLerpSpeed*delta)
		vertical.position.y = lerp(vertical.position.y, cameraData.cameraOffset.y, cameraData.camLerpSpeed*delta)
		if !itemEquipOffsetToggle:
			horizontal.position.x = lerp(horizontal.position.x, cameraData.cameraOffset.x, cameraData.camLerpSpeed*delta)
		else:
			horizontal.position.x = lerp(horizontal.position.x, cameraData.itemEquipOffset.x, cameraData.itemEquipLerpSpeed*delta)
	#Low HP
	if lowHP:
		#vignette.show()
		vignette.get_material().set_shader_parameter("color",lerp(vignette.get_material().get_shader_parameter("color"), Color(1,0,0,1),8*delta))
		vignette.get_material().set_shader_parameter("softness",lerpf(vignette.get_material().get_shader_parameter("softness"), 0.8,8*delta))
		if UserConfig.game_lowHP_ambience:
			if !hpAudio.playing:
				hpAudio.play()
	else:
		vignette.get_material().set_shader_parameter("color",lerp(vignette.get_material().get_shader_parameter("color"), Color(0,0,0,1),8*delta))
		vignette.get_material().set_shader_parameter("softness",lerpf(vignette.get_material().get_shader_parameter("softness"), 0.9,4*delta))
		hpAudio.stop()

	#Kill Vignette
	if !killVignette.get_material().get_shader_parameter("softness") >= 9.0:
		killVignette.get_material().set_shader_parameter("softness",lerpf(killVignette.get_material().get_shader_parameter("softness"), 10.0,0.6*delta))

	if !followNode == null:
		if followingEntity is BasePawn:
			if followingEntity.healthComponent:
				if !followingEntity.healthComponent.isDead:
					if followingEntity.healthComponent.health <= 30:
						lowHP = true
					else:
						lowHP = false
	#Freecam Movement
	if isFreecam:
		followNode = null
		#followingEntity.inputComponent = null
		camPivot.global_position.x = lerp(camPivot.global_position.x, self.global_position.x, 8*delta)
		camPivot.global_position.y = lerp(camPivot.global_position.y, self.global_position.y, 8*delta)
		camPivot.global_position.z = lerp(camPivot.global_position.z, self.global_position.z, 8*delta)
		vertVeclocity = Vector3.ZERO

		if !inputComponent == null:
			if inputComponent.getInputDir() != null:
				direction = inputComponent.getInputDir().rotated(Vector3.UP, camRot)
			else:
				print(inputComponent.getInputDir())

		if direction != Vector3.ZERO:
			direction = direction.normalized()

		if Input.is_action_pressed("dCamUp"):
			vertVeclocity.y = 1
		if Input.is_action_pressed("dCamDown"):
			vertVeclocity.y = -1.0

		velocity.x = velocityComponent.accelerateToVel(direction, delta, true, false, false).x
		velocity.y = velocityComponent.accelerateToVel(vertVeclocity, delta, false, true, false).y
		velocity.z = velocityComponent.accelerateToVel(direction, delta, false, false, true).z


		move_and_slide()


func _on_input_component_mouse_button_pressed(button)->void:
	pass


func _on_input_component_mouse_button_held(button)->void:
	if button == 1:
		print(button)


func _on_input_component_on_mouse_motion(motion)->void:
	if motion is InputEventMouseMotion:
		motionX = rad_to_deg(-motion.relative.x * gameManager.mouseSens)
		motionY = rad_to_deg(-motion.relative.y * gameManager.mouseSens)
		castLerp = Vector3(motionY* recoilLookSpeed+0.01,motionX* recoilLookSpeed,0)
		camPivot.rotation_degrees.y += motionX
		vertical.rotation_degrees.x += motionY
		#Lock Cam
		vertical.rotation.x = clamp(vertical.rotation.x, deg_to_rad(-88), deg_to_rad(88))

func posessObject(object, posessPart:Node3D = object)->void:
	if object.is_in_group("Posessable") and !object == null:
		if gameManager.world:
			gameManager.activeCamera = self
		followingEntity = object
		isFreecam = false
		followNode = posessPart
		object.attachedCam = self
		cameraData = object.pawnCameraData
		if object is BasePawn:
			camSpring.add_excluded_object(object.get_rid())

		if "inputComponent" in followingEntity:
			if followingEntity.inputComponent != null:
				if followingEntity.inputComponent is InputComponent:
					followingEntity.inputComponent.movementEnabled = true
					followingEntity.inputComponent.mouseActionsEnabled = true
					followingEntity.inputComponent.controllingPawn = object


func unposessObject(freecam:bool = false)->void:
	if freecam:
		isFreecam = freecam
		hud.disableHud()
		if followingEntity != null:
			position = followingEntity.position
			if "inputComponent" in followingEntity:
				if followingEntity.inputComponent is InputComponent:
					followingEntity.inputComponent.movementEnabled = false
					followingEntity.inputComponent.mouseActionsEnabled = false
					followingEntity.inputComponent.controllingPawn = null
					followingEntity.killedPawn.disconnect(emitKilleffect)
					followingEntity.headshottedPawn.disconnect(doHeadshotEffect)
					if "attachedCam" in followingEntity:
						followingEntity.attachedCam = null

	cameraData = null
	followNode = null

func getAttachedOwner():
	if !followNode == null:
		return followNode.get_parent().get_owner()
	else:
		return false

func fireRecoil(setRecoilX:float = 0.0,setRecoilY:float = 0.0,setRecoilZ:float = 0.0,useSetRecoil:bool = false)->void:
	if setRecoilX:
		camRecoil.x += setRecoilX
	if setRecoilY:
		camRecoil.y += setRecoilY
	if setRecoilZ:
		camRecoil.z += setRecoilZ
	if !useSetRecoil:
		camTargetRot = Vector3(camRecoil.x, randf_range(0.0,camRecoil.y), randf_range(0.0,camRecoil.z) )
	else:
		camTargetRot = Vector3(setRecoilX, randf_range(-setRecoilY,setRecoilY), randf_range(-setRecoilZ,setRecoilZ) )

func applyWeaponSpread(spread)->void:
	camCast.rotation += Vector3(randf_range(0.0, spread),randf_range(-spread, spread),0)
	hud.getCrosshair().addSize(0.85)
	if UserConfig.game_crosshair_tilt:
		hud.getCrosshair().addTilt(randf_range(-spread*7,spread*7))
	#camCast.rotation = Vector3.ZERO

func resetCamCast()->void:
	camCast.position = Vector3.ZERO

func emitKilleffect()->void:
	camera.fov += randf_range(2.0,3.0)
	killSound.play()
	killEffect = true
	fireRecoil(0,0,randf_range(0.5,0.8))
	fireVignette(0.9,Color.LIGHT_CORAL)
	hud.getCrosshair().tintCrosshair(Color.RED)
	hud.getCrosshair().addSize(1.5)

func doHeadshotEffect()->void:
	if !headshotSound.is_playing():
		headshotSound.play()
	fireVignette(0.9,Color.RED)
	hud.getCrosshair().addSize(1.9)
	camera.fov += randf_range(4.0,5.0)

func fireVignette(intensity:float = 0.9,color:Color = Color.DARK_RED)->void:
	killVignette.get_material().set_shader_parameter("color",color)
	killVignette.get_material().set_shader_parameter("softness",intensity)

func playTextAppearSound()->void:
	$HUD/textboxAppearSound.play()

func interactCheck()->void:
	if interactCast.is_colliding():
				if followingEntity != null:
					if followingEntity is BasePawn:
						var obj = followingEntity.getInteractionObject()
						if obj != null:
							if obj is BasePawn:
								if obj.inputComponent is AIComponent:
									if obj.inputComponent.interactType == 0:
										hud.setInteractionText("Speak to %s" %obj.inputComponent.pawnName)
							elif  obj is InteractiveObject:
								if !obj.beenUsed:
									if obj.canBeUsed:
										if !obj.useCustomInteractText:
											if obj.interactType == 1:
												hud.setInteractionText("Use %s" %obj.objectName)
											elif obj.interactType == 0:
													hud.setInteractionText("Pick up '%s'" %obj.objectName)
										else:
											hud.setInteractionText(obj.customInteractText)
								else:
									if hud.interactVisible:
										hud.interactVisible = false
							if !hud.interactVisible:
								hud.interactVisible = true
						else:
							if hud.interactVisible:
								hud.interactVisible = false
	else:
		if hud.interactVisible:
			hud.interactVisible = false

func _exit_tree()->void:
	gameManager.activeCamera = null



