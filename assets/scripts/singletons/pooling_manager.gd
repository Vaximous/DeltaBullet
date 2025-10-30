extends Node

#Pooling
var entity_dict : Dictionary = {
	"droplet" : preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn"),
	"giblet": preload("res://assets/entities/gib/giblet.tscn"),
	"bullet" : preload("res://assets/entities/projectiles/Bullet.tscn"),
	"bullet_trail" : preload("res://assets/entities/bulletTrail/bulletTrail.tscn")
}

const MAX_DROPLETS = 64
const MAX_GIBS = 64
const MAX_BULLETS = 2
const MAX_ROCKETS = 32
const MAX_GRENADESHELLS = 32
const MAX_TRAILS = 32

var droplet_pool: Array[BloodDroplet] = []
var droplet_index := 0

#Bullet Types
enum BULLET_TYPES{
	BULLET,
	ROCKET,
	GRENADESHELL
}
var bullet_pool: Array[Projectile] = []
var bullet_index := 0

#Gibs
enum GIB_TYPE{
	FLESH,
	WOOD,
	BARREL,
	MISC
}
var gib_pool: Array[FakePhysicsEntity] = []
var gib_index := 0

#Trail
var trail_pool: Array[BulletTrail] = []
var trail_index := 0

#region Create object from pool funcs
func create_projectile(world:WorldScene,projectile_type:BULLET_TYPES, position: Vector3,p_owner:Node3D, velocity: Vector3 = Vector3.ONE)->Projectile:
	var projectile : Projectile
	if is_instance_valid(world):
		match projectile_type:
			BULLET_TYPES.BULLET:
				projectile = bullet_pool[PoolingManager.bullet_index]
				bullet_index = (PoolingManager.bullet_index + 1) % PoolingManager.MAX_BULLETS
				projectile.reset(position, velocity)

	projectile.projectile_owner = p_owner
	return projectile


func create_trail(world:WorldScene, position_start: Vector3,position_end: Vector3)->BulletTrail:
	var trail : BulletTrail
	if is_instance_valid(world):
		trail = trail_pool[PoolingManager.trail_index]
		trail_index = (PoolingManager.trail_index + 1) % PoolingManager.MAX_TRAILS
		trail.reset(position_start, position_end)
	return trail

#endregion

#region Pooling Funcs
func initAllPools(world:WorldScene)->void:
	await gameManager.worldLoaded
	initDropletPool(world)
	initGibletPool(world)
	initBulletPool(world)
	initTrailPool(world)

func initTrailPool(world:WorldScene) -> void:
	trail_pool.clear()
	for i in MAX_TRAILS:
		var d: BulletTrail = entity_dict["bullet_trail"].instantiate()
		d.disable()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			trail_pool.append(d)

func initBulletPool(world:WorldScene) -> void:
	bullet_pool.clear()
	for i in MAX_BULLETS:
		var d: Projectile = entity_dict["bullet"].instantiate()
		d.disable()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			bullet_pool.append(d)

func initGibletPool(world:WorldScene) -> void:
	gib_pool.clear()
	for i in MAX_GIBS:
		var d: FakePhysicsEntity = entity_dict["giblet"].instantiate()
		d.hide()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			gib_pool.append(d)

func initDropletPool(world:WorldScene) -> void:
	droplet_pool.clear()
	for i in MAX_DROPLETS:
		var d: BloodDroplet = entity_dict["droplet"].instantiate()
		d.hide()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			droplet_pool.append(d)
#endregion
