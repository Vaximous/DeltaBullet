extends Control
@onready var panelLabel : Label = $panel/textureRect/label
@onready var mapContainer : VBoxContainer = $panel/scrollContainer/mapContainer
@onready var saveName : TextEdit = $panel/saveNamePanel/textEdit

func _process(delta)->void:
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		queue_free()

func _ready()->void:
	initPanel()

func initPanel()->void:
	clearMaps()
	showPanel()
	scanMaps()

func clearMaps()->void:
	for maps in mapContainer.get_children():
		maps.queue_free()

func scanMaps()->void:
	var mapButton = load("res://assets/scenes/ui/mapslist/mapButton.tscn")
	var mapsArray = gameManager.scan_for_scenes(&"res://assets/scenes/worlds/")
	for map in mapsArray:
		if map.get_extension() == "tscn" || map.get_extension() == "scn":
			var mapinfo = load(map)
			if mapinfo is PackedScene:
				#Console.add_rich_console_message("[color=green]%s[/color]"%mapinfo)
				var mapVariants = mapinfo._bundled["variants"]
				for v in mapVariants:
					if v is WorldData:
						var _map = mapButton.instantiate()
						mapContainer.add_child(_map)
						_map.mapFile = v
						#Console.add_rich_console_message("[color=blue]%s[/color]"%_map.mapFile)
						_map.sceneLoad = map
						_map.parseMap()


func hidePanel()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	await tween.tween_property(self,"modulate",Color(1,1,1,0),0.25).finished
	queue_free()
	gameManager.hideMouse()

func showPanel()->void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self,"modulate",Color(1,1,1,1),0.25)

func _on_close_button_pressed()->void:
	gameManager.hideMouse()
