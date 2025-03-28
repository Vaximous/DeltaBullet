extends Resource
class_name ItemData

@export_category("Weapon")
@export_subgroup("Behavior")
@export var useBulletTrail : bool = true
var defaultBulletTrail = load("res://assets/entities/bulletTrail/bulletTrail.tscn")
@export_subgroup("Shop")
@export var displayData : ItemDisplayData
@export_subgroup("Stats")
## Which category does this item belong in?
## Can this weapon be reloaded?
@export var canBeReloaded:bool = true
## Maximum magazines for this specific weapon
@export var weaponMagSize:int = 128
## Maximum ammo count per mag
@export var ammoSize:int = 30
## Reload time in seconds
@export var reloadTime = 0.5
## Can this weapon explode heads?
@export var headDismember :bool= false
## How much damage does the weapon do?
@export var weaponDamage:float = 5.0
## How fast does the weapon fire?
@export var weaponFireRate:float = 0.4
## Bullet velocity
@export var bulletSpeed : float = 800.0
## Bullet penetration strength.
@export var bulletPenetration : float = 1.0
## Determines how much impulse is applied towards physics objects.
@export var weaponImpulse : float= 5.0
## How many bullets are shot out? Useful for shotguns. Default is 1.
@export var weaponShots : int = 1
## How many bullets are consumed in a shot. 0 = infinite
@export var ammoConsumption : int = 1
## Defining the damage falloff if you'd want a weapon with a less or more pronounced falloff
@export var damageFalloff : Curve = preload("res://assets/entities/projectiles/linear_falloff_curve.tres")
##Scope
@export_subgroup("Scope")
#Is this weapon a scoped weapon?
@export var scopedWeapon : bool = false
@export var scopedFOV : int = 25
##Scope Texture
@export var scopedTexture : Texture2D = load("res://assets/textures/ui/sniperscope.png")
## What crosshair should the weapon force?
@export_subgroup("Crosshair")
@export var useCustomCrosshairSize:bool = false
@export var crosshairSizeOverride : float = 0.8
@export var forcedCrosshair : Texture2D
@export_subgroup("Recoil")
@export var useFOV:bool = false
@export var fovShotAmount:float = 1.5
@export var weaponRecoil : Vector3 = Vector3(5 ,1 , 0.25)
@export var weaponRecoilStrength : float = 8.0
@export var weaponSpread:float = 0.25
@export_subgroup("Aiming Recoil")
@export var weaponRecoilStrengthAim : float = 4.0
@export var weaponSpreadAim:float = 0.25
@export_category("Weapon Animations")
var useLeftHand:bool = false
var useRightHand:bool = true
@export var leftHandParent:bool = false
@export var rightHandParent:bool = true
@export var useWeaponSprintAnim:bool = false
@export_subgroup("Idle Weapon Handling")
@export var useLeftHandIdle:bool = true
@export var useRightHandIdle:bool = true
@export_subgroup("Aim Weapon Handling")
@export var useLeftHandAiming :bool= true
@export var useRightHandAiming:bool = true
@export_subgroup("FreeAim Weapon Handling")
@export var useLeftHandFreeAiming:bool = true
@export var useRightHandFreeAiming:bool = true
@export_subgroup("Weapon Orientation")
@export var weaponPositionOffset = Vector3.ZERO
@export var weaponRotationOffset = Vector3.ZERO
@export_subgroup("Misc")
##When the item is equipped, what sound will it play?
@export var equipStream : AudioStream
@export var bulletColor : Color = Color(1,1,0,1)
