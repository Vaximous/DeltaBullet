extends PanelContainer
#@onready var materialContainer : HBoxContainer = $hBoxContainer/materials
@export var clothingItem : ClothingItem:
	set(value):
		clothingItem = value
		clearPreview()
		generateMaterialList()


func _process(delta: float) -> void:
	if clothingItem:
		for override in getMeshSurfaceOverrides(clothingItem.clothingMesh).size():
			getMeshSurfaceOverrides(clothingItem.clothingMesh)[override].albedo_color = getMaterialPickers()[override].color


	%camhold.rotation.x += 10*delta


func clearPreview()->void:
	for i in %item.get_children():
		i.queue_free()

func getMaterialPickers()->Array:
	return %materials.get_children()

func clearMaterialList()->void:
	for i in %materials.get_children():
		i.queue_free()

#func getMaterialButton(id:int)->ColorRect:
	#var button
	#for i in materialContainer.get_children():
		#if i.get_meta(&"materialID") == selectedID:
			#button = i
	#return button

func getMeshSurfaceOverrides(mesh:MeshInstance3D)->Array:
	var arr:Array = []
	for i in mesh.get_surface_override_material_count():
		arr.append(mesh.get_surface_override_material(i))
	return arr

func getMeshSurfaces(mesh:Mesh)->Array:
	var arr:Array = []
	for i in mesh.get_surface_count():
		arr.append(mesh.surface_get_material(i))
	return arr

#func selectMaterial(matID:int)->void:
	#selectedID = matID
	#colorPicker.color = selectedItem.clothingMesh.get_surface_override_material(matID).albedo_color

func createOverrideFromSurfaceMaterial(meshInstance:MeshInstance3D,mesh:Mesh,id:int):
	var surface = getMeshSurfaces(mesh)[id].duplicate()
	meshInstance.set_surface_override_material(id,surface)
	return surface


func generateMaterialList()->void:
	#Each material that makes up a mesh will have a button generated for it, the button holds the ID of the surface which is used to identify which material it is
	clearMaterialList()
	if clothingItem:
		for i in getMeshSurfaceOverrides(clothingItem.clothingMesh):
			if !is_instance_valid(i):
				createOverrideFromSurfaceMaterial(clothingItem.clothingMesh,clothingItem.clothingMesh.mesh,getMeshSurfaceOverrides(clothingItem.clothingMesh).find(i))

		var mats = getMeshSurfaceOverrides(clothingItem.clothingMesh)
		#print(mats)
		for materials in mats:
			var picker = ColorPickerButton.new()
			%materials.add_child(picker)
			picker.custom_minimum_size.x = 70
			picker.color = materials.albedo_color
			picker.set_meta(&"materialID",mats.find(materials))
