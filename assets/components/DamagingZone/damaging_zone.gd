extends Area3D


@export var damage_amount : float = 0.0
@export var enter_delay : float = 0.5
@export var damage_interval : float = 1.0
@export var damage_remainder_on_exit : bool = true

var nodes_inside : Dictionary[Node3D, float] = {}


func _physics_process(delta: float) -> void:
	for node in nodes_inside.keys():
		nodes_inside[node] -= delta
		if nodes_inside[node] <= 0.0:
			nodes_inside[node] = damage_interval
			apply_damage(node)


func apply_damage(to_node : Node3D, mult : float = 1.0) -> void:
	Util.damage_node(to_node, damage_amount * mult, self)


func get_remainder_percent(t : float) -> float:
	return t / damage_interval


func _on_body_entered(body: Node3D) -> void:
	nodes_inside[body] = enter_delay


func _on_body_exited(body: Node3D) -> void:
	if damage_remainder_on_exit:
		apply_damage(body, get_remainder_percent(damage_interval - nodes_inside[body]))
	nodes_inside.erase(body)
