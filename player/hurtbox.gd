extends Area2D
class_name Hurtbox

@export var origin_peer_id: int
@export var damage: int

func remove():
	if is_multiplayer_authority():
		queue_free()

func get_player() -> Player:
	return $"/root/Game/Network".get_node(str(origin_peer_id)) as Player
