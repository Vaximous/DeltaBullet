@tool
extends EditorScenePostImport



# The Airduct model contains empties that determine where attachment points are.
# We will use metadata on the resources to store those attachment points as Transform3Ds.


func _post_import(scene: Node) -> Object:
	print("-- running Airduct import script")
	iterate(scene)
	print("-- Finished importing Airduct model.")
	return scene


func iterate(node : Node) -> void:
	if node != null:
		if node is MeshInstance3D:
			var attach_transforms : Array[Transform3D] = []
			for child in node.get_children():
				#Empties are attachment points
				if node is Node3D:
					attach_transforms.append(child.transform)
			node.mesh.set_meta(&"attach_points", attach_transforms)
			node.mesh.set_meta(&"_airvent_mesh", true)
			print_rich("Mesh: %s\n\tAttachment Points: [b]%s[/b]" % [node.mesh.resource_name, attach_transforms.size()])
		for child in node.get_children():
			iterate(child)
