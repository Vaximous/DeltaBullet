extends MeshInstance3D
class_name BulletTrail
@export_category("Bullet Trail")
@onready var onscreenNotifier : VisibleOnScreenNotifier3D = $visibleOnScreenNotifier3d
var defaultBulletColor : Color = Color(1,1,0,1)
var bulletColor : Color = defaultBulletColor:
	set(value):
		bulletColor = value
		if value != defaultBulletColor:
			if !get_material_override() == null:
				mat = get_material_override().duplicate()
				self.set_material_override(mat)
				material_override.emission = bulletColor
				transparency = 0.0

var bulletSpeed : float = 40.0
var alpha : float = 1.0
var mat : Material
var bulletStart : Vector3 = Vector3.ZERO
var bulletEnd : Vector3
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta)->void:
	if onscreenNotifier.is_on_screen():
		if mesh:
			bulletStart = lerp(bulletStart,Vector3(bulletEnd.x,bulletEnd.y,bulletEnd.z),delta*bulletSpeed)
			mesh.clear_surfaces()
			mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			mesh.surface_add_vertex(bulletStart)
			mesh.surface_add_vertex(bulletEnd)
			mesh.surface_end()

			if !get_material_override() == null:
				transparency = lerpf(transparency,2.0,3.0*delta)
				if transparency >= 0.9:
					queue_free()
	else:
		queue_free()

func initTrail(pos1, pos2)->void:
	bulletStart = pos1
	bulletEnd = pos2
	var meshDraw = ImmediateMesh.new()
	self.mesh = meshDraw
	meshDraw.surface_begin(Mesh.PRIMITIVE_LINES, get_material_override())
	meshDraw.surface_add_vertex(bulletStart)
	meshDraw.surface_add_vertex(bulletEnd)
	meshDraw.surface_end()

func _on_timer_timeout()->void:
	queue_free()
