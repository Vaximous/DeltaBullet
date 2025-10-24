extends Node

#Pooling
const MAX_DROPLETS = 64
const MAX_GIBS = 64

var droplet_pool: Array[BloodDroplet] = []
var droplet_index := 0

#Gibs
enum GIB_TYPE{
	FLESH,
	WOOD,
	BARREL,
	MISC
}
var gib_pool: Array[FakePhysicsEntity] = []
var gib_index := 0


#region Pooling Funcs
func initAllPools(world:WorldScene)->void:
	await gameManager.worldLoaded
	initDropletPool(world)
	initGibletPool(world)

func initGibletPool(world:WorldScene) -> void:
	gib_pool.clear()
	for i in MAX_GIBS:
		var d: FakePhysicsEntity = preload("res://assets/entities/gib/giblet.tscn").instantiate()
		d.hide()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			gib_pool.append(d)

func initDropletPool(world:WorldScene) -> void:
	droplet_pool.clear()
	for i in MAX_DROPLETS:
		var d: BloodDroplet = preload("res://assets/entities/emitters/bloodDroplet/bloodDrop.tscn").instantiate()
		d.hide()
		if is_instance_valid(world):
			world.pooledObjects.add_child(d)
			droplet_pool.append(d)

#endregion
