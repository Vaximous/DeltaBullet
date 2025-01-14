extends Marker3D
@export_category("Blood String")
var strings : Array[Node3D]
var lastCreated : Node3D
@export var amounts : int = 8

func _ready() -> void:
	await get_tree().process_frame
	#%timer.wait_time = creationTime
	#%timer.timeout.connect(createDroplet)
	#createDroplet()
	createStringSpurt()

func createStringSpurt()->void:
	for x in amounts:
		createDroplet()

func createDroplet()->void:
	if gameManager.world:
		var droplet = preload("res://assets/entities/emitters/bloodStringEmitter/stringDroplet.tscn").instantiate()
		gameManager.world.worldMisc.add_child(droplet)
		strings.append(droplet)
		droplet.global_position = global_position
		droplet.velocity.y = droplet.velocity.y * randf_range(5, 16)
		droplet.velocity.x = droplet.velocity.x * randf_range(-2, 2)
		droplet.velocity.z = droplet.velocity.z * randf_range(-2, 2)
		if !lastCreated == null:
			droplet.attached = lastCreated
			droplet.global_position = lastCreated.global_position
			droplet.drawString()
		lastCreated = droplet
