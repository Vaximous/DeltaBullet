extends Node2D

var points: Array[GraphPoint] = []


func _ready() -> void:
	var prev: GraphPoint = null
	for i in 50:
		var gp = add_graph_point()
		gp.global_position = global_position + Util.random_vector2() * 200.0
		if prev != null:
			gp.add_connection(prev)

		while randi() % 3 == 0:
			var closest = get_nearest_unconnected_point(gp)
			if closest != null:
				gp.add_connection(closest)
		var sprite: Sprite2D = Sprite2D.new()
		gp.add_child(sprite)
		sprite.texture = preload("res://addons/ez_dialogue/icons/add.png")
		prev = gp


func _process(delta: float) -> void:
	var dup = points.duplicate()
	for p in points:
		p.iterate_step(delta, dup)


func add_graph_point() -> GraphPoint:
	var p = GraphPoint.new()
	add_child(p)
	points.append(p)
	return p


func get_nearest_unconnected_point(point: GraphPoint) -> GraphPoint:
	var closest = null
	for p in points:
		if p == point:
			continue
		if p in point.connections:
			continue
		if closest == null:
			closest = p
			continue
		if p.global_position.distance_to(point.global_position) < closest.global_position.distance_to(point.global_position):
			closest = p
	return closest


class GraphPoint extends Node2D:
	var velocity: Vector2
	var connections: Array[GraphPoint]

	const dist_min: float = 160.0
	const dist_max: float = 160.0
	const velocity_max: float = 5000.0
	const push_force: float = 50.0
	const drag: float = 2.5


	func iterate_step(delta: float, _points: Array) -> void:
		_points.erase(self)
		for c in _points:
			var dist = c.global_position.distance_to(global_position)
			if dist < dist_min:
				#push away
				var force = global_position.direction_to(c.global_position) * push_force * delta * (dist - dist_min) / 2.0
				velocity += force
				c.velocity -= force
		for c in connections:
			var dist = c.global_position.distance_to(global_position)
			if dist > dist_max:
				#pull toward
				var force = global_position.direction_to(c.global_position) * push_force * delta * (dist_max - dist) / 2.0
				velocity -= force
				c.velocity += force

		velocity = velocity.lerp(Vector2.ZERO, min(1.0, drag * delta))
		velocity = velocity.limit_length(velocity_max)
		global_position += velocity * delta


	func add_connection(point_b: GraphPoint) -> void:
		if not connections.has(point_b):
			connections.append(point_b)
			var cn = ConnectorLine.new()
			add_child(cn)
			cn.point_b = point_b
			point_b.tree_exiting.connect(func():
					cn.point_b = null
					connections.erase(point_b)
			)


class ConnectorLine extends Line2D:

	var point_b: GraphPoint


	func _init() -> void:
		show_behind_parent = true
		width = 1.0


	func _process(_delta: float) -> void:
		if point_b == null:
			queue_free()
			return
		clear_points()
		add_point(Vector2.ZERO)
		add_point(point_b.global_position - global_position)
