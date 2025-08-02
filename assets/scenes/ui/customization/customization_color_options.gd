extends Control
var customizationType = 0
var selectedItem : ClothingItem
var selectedID : int = -1
var materialItem : PackedScene = load("res://assets/scenes/ui/customization/materialButton.tscn")
@onready var colorPicker : ColorPicker = $customizationColorOptions/panel/vBoxContainer/colorPicker
@onready var materialSelector : Control = $customizationColorOptions/panel/vBoxContainer/materialSelector
@onready var materialContainer : HBoxContainer = $customizationColorOptions/panel/vBoxContainer/materialSelector/materialContainer

func _process(delta: float) -> void:
	if customizationType == 0:
		if selectedID != -1:
			var overrideMat : StandardMaterial3D = selectedItem.clothingMesh.get_surface_override_material(selectedID)
			overrideMat.albedo_color = colorPicker.color
			getMaterialButton(selectedID).color = overrideMat.albedo_color


func selectItem(item:ClothingItem)->void:
	selectedItem = item
	generateMaterialList()

func clearMaterialList()->void:
	for i in materialContainer.get_children():
		i.queue_free()

func getMaterialButton(id:int)->ColorRect:
	var button
	for i in materialContainer.get_children():
		if i.get_meta(&"materialID") == selectedID:
			button = i
	return button

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

func selectMaterial(matID:int)->void:
	selectedID = matID
	colorPicker.color = selectedItem.clothingMesh.get_surface_override_material(matID).albedo_color

func createOverrideFromSurfaceMaterial(meshInstance:MeshInstance3D,mesh:Mesh,id:int):
	var surface = getMeshSurfaces(mesh)[id].duplicate()
	meshInstance.set_surface_override_material(id,surface)
	return surface


func generateMaterialList()->void:
	#Each material that makes up a mesh will have a button generated for it, the button holds the ID of the surface which is used to identify which material it is
	clearMaterialList()
	if selectedItem:
		add_child(selectedItem)
		for i in getMeshSurfaceOverrides(selectedItem.clothingMesh):
			if !is_instance_valid(i):
				createOverrideFromSurfaceMaterial(selectedItem.clothingMesh,selectedItem.clothingMesh.mesh,getMeshSurfaceOverrides(selectedItem.clothingMesh).find(i))

		var mats = getMeshSurfaceOverrides(selectedItem.clothingMesh)
		#print(mats)
		for materials in mats:
			var materialButton = materialItem.instantiate()
			materialContainer.add_child(materialButton)
			materialButton.color = materials.albedo_color
			materialButton.set_meta(&"materialID",mats.find(materials))
			materialButton.button.pressed.connect(selectMaterial.bind(materialButton.get_meta(&"materialID")))
