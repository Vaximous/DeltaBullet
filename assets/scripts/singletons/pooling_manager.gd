extends Node

#Dictionaries
var bullet_holes : Dictionary = {
	"bullet_hole_flesh" : preload("res://assets/entities/bulletHoles/flesh/BulletHole_Flesh.tscn"),
	"bullet_hole_generic" : preload("res://assets/entities/bulletHoles/generic/BulletHoleGeneric.tscn"),
	"bullet_hole_metal" : preload("res://assets/entities/bulletHoles/metal/bulletHoleMetal.tscn"),
	"bullet_hole_wood" : preload("res://assets/entities/bulletHoles/wood/WoodBullethole.tscn")
}

var entity_dict : Dictionary = {
	"droplet" : preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn"),
	"giblet": preload("res://assets/entities/gib/giblet.tscn"),
	"bullet" : preload("res://assets/entities/projectiles/Bullet.tscn"),
	"bullet_trail" : preload("res://assets/entities/bulletTrail/bulletTrail.tscn")
}

#Pooling bullet holes
enum HOLE_MATERIALS{
	GENERIC,
	METAL,
	WOOD,
	FLESH
}

const MAX_HOLE_METAL = 32
const MAX_HOLE_WOOD = 32
const MAX_HOLE_FLESH = 32
const MAX_HOLE_GENERIC = 32

var bullet_hole_generic_pool: Array[BulletHole] = []
var bullet_hole_generic_index := 0

var bullet_hole_flesh_pool: Array[BulletHole] = []
var bullet_hole_flesh_index := 0

var bullet_hole_metal_pool: Array[BulletHole] = []
var bullet_hole_metal_index := 0

var bullet_hole_wood_pool: Array[BulletHole] = []
var bullet_hole_wood_index := 0

#Pooling entities
const MAX_DROPLETS = 64
const MAX_GIBS = 64
const MAX_BULLETS = 128
const MAX_ROCKETS = 32
const MAX_GRENADESHELLS = 32
const MAX_TRAILS = 64

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

var active_entities : Array

#region Create object from pool funcs
func create_bullet_hole(parent:Node,bullet_hole_type:HOLE_MATERIALS, pos : Vector3 = Vector3.ONE, rot : float = 0.0, normal : Vector3 = Vector3.ONE,bulletVel : Vector3 = Vector3.ONE)->BulletHole:
	var hole : BulletHole
	if is_instance_valid(parent):
		match bullet_hole_type:
			HOLE_MATERIALS.GENERIC:
				hole = bullet_hole_generic_pool[PoolingManager.bullet_hole_generic_index]
				bullet_hole_generic_index = (PoolingManager.bullet_hole_generic_index + 1) % PoolingManager.MAX_HOLE_GENERIC
			HOLE_MATERIALS.WOOD:
				hole = bullet_hole_wood_pool[PoolingManager.bullet_hole_wood_index]
				bullet_hole_wood_index = (PoolingManager.bullet_hole_wood_index + 1) % PoolingManager.MAX_HOLE_WOOD
			HOLE_MATERIALS.METAL:
				hole = bullet_hole_metal_pool[PoolingManager.bullet_hole_metal_index]
				bullet_hole_metal_index = (PoolingManager.bullet_hole_metal_index + 1) % PoolingManager.MAX_HOLE_METAL
			HOLE_MATERIALS.FLESH:
				hole = bullet_hole_flesh_pool[PoolingManager.bullet_hole_flesh_index]
				bullet_hole_flesh_index = (PoolingManager.bullet_hole_flesh_index + 1) % PoolingManager.MAX_HOLE_FLESH

	if hole:
		hole.reparent(parent)
		hole.reset(pos, rot, normal, bulletVel)
	return hole

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
	if is_instance_valid(world):
		initDropletPool(world)
		initGibletPool(world)
		initBulletPool(world)
		initTrailPool(world)
		for i in HOLE_MATERIALS.size():
			init_bullet_hole_pool(i,world)

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

func init_bullet_hole_pool(bullet_hole : HOLE_MATERIALS, world:WorldScene)->void:
	if !is_instance_valid(world): return
	var d : BulletHole
	match bullet_hole:
		HOLE_MATERIALS.WOOD:
			bullet_hole_wood_pool.clear()
			for i in MAX_HOLE_WOOD:
				d = bullet_holes["bullet_hole_wood"].instantiate()
				bullet_hole_wood_pool.append(d)
				d.disable()
				world.pooledObjects.add_child(d)
		HOLE_MATERIALS.METAL:
			bullet_hole_metal_pool.clear()
			for i in MAX_HOLE_METAL:
				d = bullet_holes["bullet_hole_metal"].instantiate()
				bullet_hole_metal_pool.append(d)
				d.disable()
				world.pooledObjects.add_child(d)
		HOLE_MATERIALS.FLESH:
			bullet_hole_flesh_pool.clear()
			for i in MAX_HOLE_FLESH:
				d = bullet_holes["bullet_hole_flesh"].instantiate()
				bullet_hole_flesh_pool.append(d)
				d.disable()
				world.pooledObjects.add_child(d)
		HOLE_MATERIALS.GENERIC:
			bullet_hole_generic_pool.clear()
			for i in MAX_HOLE_GENERIC:
				d = bullet_holes["bullet_hole_generic"].instantiate()
				bullet_hole_generic_pool.append(d)
				d.disable()
				world.pooledObjects.add_child(d)

func init_bullet_hole_generic_pool(world:WorldScene) -> void:
	bullet_hole_generic_pool.clear()
	for i in MAX_HOLE_GENERIC:
		var d: BulletHole = bullet_holes["bullet_hole_generic"].instantiate()
		d.disable()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			bullet_hole_generic_pool.append(d)

func init_bullet_hole_flesh_pool(world:WorldScene) -> void:
	bullet_hole_flesh_pool.clear()
	for i in MAX_HOLE_FLESH:
		var d: BulletHole = bullet_holes["bullet_hole_flesh"].instantiate()
		d.disable()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			bullet_hole_flesh_pool.append(d)
#endregion
