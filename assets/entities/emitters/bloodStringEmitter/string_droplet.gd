extends FakePhysicsEntity
var attached : Node3D:
	set(value):
		attached = value
		if value != null:
			drawString()

func updateString()->void:
	if %string.mesh:
		%string.mesh.clear_surfaces()
		%string.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		%string.mesh.surface_add_vertex(to_local(global_position))
		%string.mesh.surface_add_vertex(to_local(attached.global_position))
		%string.mesh.surface_end()

func drawString()->void:
	var meshDraw = ImmediateMesh.new()
	%string.mesh = meshDraw
	%string.mesh.clear_surfaces()
	%string.mesh.surface_begin(Mesh.PRIMITIVE_LINES, %string.get_material_override())
	%string.mesh.surface_add_vertex(to_local(global_position))
	%string.mesh.surface_add_vertex(to_local(attached.global_position))
	%string.mesh.surface_end()

func _on_bounced() -> void:
	%bloodSpurt.restart()
	var splat = gameManager.createSplat(global_position,colNormal)
	#queue_free()
