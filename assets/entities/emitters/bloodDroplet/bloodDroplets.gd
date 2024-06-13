extends RigidBody3D
class_name BloodDroplet
@onready var mesh : MeshInstance3D = $meshInstance3d
@onready var area3D : Area3D = $area3d
var bloodSpeed : float = 16.0
var bloodStart : Vector3
var bloodEnd : Vector3
var onScreen : bool = true
var contacts : int = 0
var exclusionArray : Array[RID]
var normal : Vector3 = Vector3.ZERO
var colPoint : Vector3= Vector3.ZERO

func _integrate_forces(state)->void:
	contacts = state.get_contact_count()
	if contacts > 0:
		if exclusionArray.has(state.get_contact_collider(0)):
			return
		if !state.get_contact_collider_object(0) is RigidBody3D:
			#print(state.get_contact_collider_object(0))
			normal = state.get_contact_local_normal(0)
			colPoint = state.get_contact_local_position(0)
			createSplat(state.get_contact_local_position(0))

func initTrail(pos1, pos2)->void:
	if mesh != null:
		bloodStart = pos1
		bloodEnd = pos2
		var meshDraw = ImmediateMesh.new()
		mesh.mesh = meshDraw
		meshDraw.surface_begin(Mesh.PRIMITIVE_LINES, mesh.get_material_override())
		meshDraw.surface_add_vertex(bloodStart)
		meshDraw.surface_add_vertex(bloodEnd)
		meshDraw.surface_end()

func createSplat(gposition:Vector3 = Vector3.ZERO)->void:
	if gameManager.world != null:
		#print("col")
		var bloodDecal = load("res://assets/entities/bloodSplat/bloodSplat1.tscn")
		var _b = bloodDecal.instantiate()
		gameManager.world.worldMisc.add_child(_b)
		_b.rotate(normal,randf_range(0, 180)/PI)
		_b.position = gposition
		_b.look_at(colPoint + normal, Vector3.UP)
		queue_free()

func _on_visible_on_screen_enabler_3d_screen_entered()->void:
	onScreen = true

func _on_visible_on_screen_enabler_3d_screen_exited()->void:
	onScreen = false
	queue_free()

