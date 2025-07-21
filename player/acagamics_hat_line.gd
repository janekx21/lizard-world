extends Line2D

@export var nodes: Array[Node2D]

func _physics_process(delta: float) -> void:
	points = nodes.map(func(n): n.global_position)
	for i in len(points):
		set_point_position(i, global_transform.inverse() * nodes[i].global_position)
	global_scale = Vector2.ONE
